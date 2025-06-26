import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import '../services/chats_figure.dart';
import 'chat_page.dart';
import 'user_detail_page.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  List<String> _chatFigures = [];
  Map<String, Map<String, dynamic>> _figuresData = {};
  List<String> _randomFigures = [];
  String? _recommendedFigure;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 加载角色数据
    await _loadFiguresData();

    // 加载聊天记录并按时间排序
    final chatFigures = await ChatsFigure.getChatFigures();

    // 获取每个角色的最后聊天时间并排序
    final figureWithTimes = <Map<String, dynamic>>[];
    for (String figureName in chatFigures) {
      final lastTime = await ChatsFigure.getLastChatTime(figureName);
      figureWithTimes.add({
        'name': figureName,
        'time': lastTime ?? DateTime.fromMillisecondsSinceEpoch(0),
      });
    }

    // 按时间排序（最新的在前）
    figureWithTimes.sort(
      (a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime),
    );

    final sortedChatFigures =
        figureWithTimes.map((item) => item['name'] as String).toList();

    // 生成随机6个角色用于底部滚动
    _generateRandomFigures();

    // 检查是否有聊天记录
    final hasChats = await ChatsFigure.hasAnyChatHistory();

    String? recommendedFigure;
    if (!hasChats) {
      // 如果没有聊天记录，随机推荐一个角色
      recommendedFigure = await _getRandomRecommendation();
      if (recommendedFigure != null) {
        await ChatsFigure.setRecommendedFigure(recommendedFigure);
      }
    } else {
      recommendedFigure = await ChatsFigure.getRecommendedFigure();
    }

    setState(() {
      _chatFigures = sortedChatFigures;
      _recommendedFigure = recommendedFigure;
      _isLoading = false;
    });
  }

  Future<void> _loadFiguresData() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/data/figure_20250625.json');
      final List<dynamic> jsonArray = jsonDecode(jsonString);

      // 将数组转换为以用户名为key的Map
      final Map<String, Map<String, dynamic>> figuresMap = {};
      for (var item in jsonArray) {
        if (item is Map<String, dynamic> && item['milyaUserName'] != null) {
          figuresMap[item['milyaUserName']] = item;
        }
      }

      setState(() {
        _figuresData = figuresMap;
      });
    } catch (e) {
      debugPrint('Error loading figures data: $e');
    }
  }

  Future<String?> _getRandomRecommendation() async {
    if (_figuresData.isEmpty) return null;

    final figureKeys = _figuresData.keys.toList();
    final random = Random();
    return figureKeys[random.nextInt(figureKeys.length)];
  }

  void _generateRandomFigures() {
    if (_figuresData.isEmpty) return;

    final figureKeys = _figuresData.keys.toList();
    final random = Random();
    final randomFigures = <String>[];

    // 随机选择6个角色
    while (randomFigures.length < 6 &&
        randomFigures.length < figureKeys.length) {
      final randomKey = figureKeys[random.nextInt(figureKeys.length)];
      if (!randomFigures.contains(randomKey)) {
        randomFigures.add(randomKey);
      }
    }

    _randomFigures = randomFigures;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _navigateToChat(String figureName) {
    final figureData = _figuresData[figureName];
    if (figureData != null) {
      Navigator.of(context)
          .push(
            MaterialPageRoute(builder: (context) => ChatPage(user: figureData)),
          )
          .then((_) {
            // 聊天后刷新页面
            _loadData();
          });
    }
  }

  void _navigateToUserDetail(String figureName) {
    final figureData = _figuresData[figureName];
    if (figureData != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => UserDetailPage(user: figureData),
        ),
      );
    }
  }

  Widget _buildOnlineIndicator() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  Widget _buildChatItem(String figureName) {
    final figureData = _figuresData[figureName];
    if (figureData == null) return const SizedBox.shrink();

    return FutureBuilder<DateTime?>(
      future: ChatsFigure.getLastChatTime(figureName),
      builder: (context, timeSnapshot) {
        return FutureBuilder<String?>(
          future: ChatsFigure.getLastMessage(figureName),
          builder: (context, messageSnapshot) {
            final lastTime = timeSnapshot.data;
            final lastMessage =
                messageSnapshot.data ?? 'Tap to start chatting...';

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _navigateToChat(figureName),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // 头像
                        Stack(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  figureData['milyaUserIcon'],
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.grey,
                                        size: 28,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            // 在线状态指示器
                            Positioned(
                              right: 2,
                              top: 2,
                              child: _buildOnlineIndicator(),
                            ),
                          ],
                        ),

                        const SizedBox(width: 16),

                        // 聊天内容
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 用户名和时间
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    figureData['milyaUserName'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  if (lastTime != null)
                                    Text(
                                      _formatTime(lastTime),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 4),

                              // 最后消息
                              Text(
                                lastMessage.length > 50
                                    ? '${lastMessage.substring(0, 50)}...'
                                    : lastMessage,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopAvatarRow() {
    // 使用随机推荐的6个角色而不是聊天记录中的角色
    final displayFigures = _randomFigures.take(6).toList();

    return SizedBox(
      height: 84,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              displayFigures.map((figureName) {
                final figureData = _figuresData[figureName];
                if (figureData == null) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => _navigateToUserDetail(figureName),
                    child: Stack(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              figureData['milyaUserIcon'],
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                    size: 36,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // 在线状态指示器
                        Positioned(
                          right: 4,
                          top: 4,
                          child: _buildOnlineIndicator(),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildRecommendedChat() {
    if (_recommendedFigure == null) return const SizedBox.shrink();

    final figureData = _figuresData[_recommendedFigure!];
    if (figureData == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F4FD), Color(0xFFF0F9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToChat(_recommendedFigure!),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 头像
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          figureData['milyaUserIcon'],
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.person,
                                color: Colors.grey,
                                size: 28,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // 推荐标识
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // 内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            figureData['milyaUserName'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Recommended',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        figureData['milyaSayHi'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // 顶部标题区域
          SafeArea(
            child: Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chat',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 推荐角色头像行
                  if (_randomFigures.isNotEmpty) _buildTopAvatarRow(),
                ],
              ),
            ),
          ),

          // 主要内容区域
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // 推荐聊天（如果没有聊天记录或有推荐）
                  if (_recommendedFigure != null) _buildRecommendedChat(),

                  // 聊天列表
                  Expanded(
                    child:
                        _chatFigures.isEmpty
                            ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No chats yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Start a conversation with someone!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.only(top: 8),
                              itemCount: _chatFigures.length,
                              itemBuilder: (context, index) {
                                return _buildChatItem(_chatFigures[index]);
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
