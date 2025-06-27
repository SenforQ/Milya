import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  VideoPlayerController? _videoController;
  List<dynamic> _users = [];
  Map<String, dynamic>? _currentUser;
  List<Map<String, dynamic>> _randomFollowers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsersAndPlayRandomVideo();
  }

  Future<void> _loadUsersAndPlayRandomVideo() async {
    try {
      // 加载用户数据
      final String response = await rootBundle.loadString(
        'assets/data/figure_20250625.json',
      );
      final List<dynamic> data = json.decode(response);
      _users = data;

      // 加载被拉黑的用户列表
      final prefs = await SharedPreferences.getInstance();
      final blockedUsers = prefs.getStringList('blocked_users') ?? [];

      // 过滤掉被拉黑的用户
      final availableUsers = _users.where((user) {
        final userName = user['milyaUserName'] ?? '';
        return !blockedUsers.contains(userName);
      }).toList();

      if (availableUsers.isEmpty) {
        // 如果所有用户都被拉黑了，重置拉黑列表
        await prefs.remove('blocked_users');
        _currentUser = _users[Random().nextInt(_users.length)];
      } else {
        // 随机选择一个未被拉黑的用户
        final random = Random();
        _currentUser = availableUsers[random.nextInt(availableUsers.length)];
      }

      // 随机选择3个其他用户作为粉丝头像
      final otherUsers = _users.where((user) => user != _currentUser).toList();
      _randomFollowers = [];
      final random = Random();
      for (int i = 0; i < 3 && i < otherUsers.length; i++) {
        final randomIndex = random.nextInt(otherUsers.length);
        _randomFollowers.add(otherUsers[randomIndex]);
        otherUsers.removeAt(randomIndex);
      }

      // 初始化视频播放器
      if (_currentUser != null) {
        _videoController = VideoPlayerController.asset(
          _currentUser!['milyaShowVideo'],
        );
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.setVolume(0.0); // 静音播放
        _videoController!.play();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _showActionSheet(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                _buildActionSheetItem('Report', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _ReportPage(user: user),
                    ),
                  );
                }),
                _buildActionSheetItem('Block', () {
                  Navigator.pop(context);
                  _showBlockConfirmDialog(context, user, 'block');
                }),
                _buildActionSheetItem('Mute', () {
                  Navigator.pop(context);
                  _showBlockConfirmDialog(context, user, 'mute');
                }),
                const Divider(height: 1, color: Color(0xFFE5E5E5)),
                _buildActionSheetItem('Cancel', () {
                  Navigator.pop(context);
                }, isCancel: true),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionSheetItem(
    String title,
    VoidCallback onTap, {
    bool isCancel = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.normal,
            color: isCancel ? const Color(0xFF999999) : const Color(0xFF333333),
          ),
        ),
      ),
    );
  }

  void _showBlockConfirmDialog(
      BuildContext context, Map<String, dynamic> user, String action) {
    String actionText = action == 'block' ? 'Block' : 'Mute';
    String contentText = action == 'block'
        ? 'Are you sure you want to block ${user['milyaUserName']}? You won\'t see their content anymore.'
        : 'Are you sure you want to mute ${user['milyaUserName']}? You won\'t see their content anymore.';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$actionText User'),
          content: Text(contentText),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _executeBlockAction(user, action);
              },
              child: Text(
                actionText,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeBlockAction(
      Map<String, dynamic> user, String action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> blockedUsers = prefs.getStringList('blocked_users') ?? [];

      String userName = user['milyaUserName'] ?? '';
      if (!blockedUsers.contains(userName)) {
        blockedUsers.add(userName);
        await prefs.setStringList('blocked_users', blockedUsers);
      }

      String actionText = action == 'block' ? 'blocked' : 'muted';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user['milyaUserName']} has been $actionText'),
          backgroundColor: Colors.black87,
          duration: const Duration(seconds: 2),
        ),
      );

      // 重新加载视频以显示新的用户
      _loadUsersAndPlayRandomVideo();
    } catch (e) {
      debugPrint('Error executing block action: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 视频背景
          if (_videoController != null && _videoController!.value.isInitialized)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),

          // 底部玻璃效果视图
          Positioned(
            left: 20,
            right: 20,
            bottom: 20, // 距离底部20px
            child: Container(
              height: 162,
              decoration: BoxDecoration(
                color: const Color(
                  0x99000000,
                ), // #000000 with 0.6 opacity (153/255 ≈ 0.6)
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 用户名和举报按钮
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _currentUser!['milyaUserName'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500, // Medium
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                _showActionSheet(context, _currentUser!),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.more_horiz,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 用户介绍
                      Expanded(
                        child: Text(
                          _currentUser!['milyaUserIntroduction'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFFFFFFF),
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 底部：头像和粉丝数
                      Row(
                        children: [
                          // 随机3个头像 - 使用Stack实现重叠效果
                          SizedBox(
                            width: 20 +
                                (_randomFollowers.length - 1) * 18, // 计算总宽度
                            height: 20,
                            child: Stack(
                              children:
                                  _randomFollowers.asMap().entries.map((entry) {
                                int index = entry.key;
                                Map<String, dynamic> follower = entry.value;
                                return Positioned(
                                  left: index * 18.0, // 每个头像间隔18px实现2px重叠
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        follower['milyaUserIcon'],
                                        width: 20,
                                        height: 20,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            width: 20,
                                            height: 20,
                                            color: Colors.grey,
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 10,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // 粉丝数
                          Text(
                            '${_currentUser!['milyaUserFollow']} followers',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFFFFFFF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const Spacer(),

                          // 右侧箭头按钮
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UserDetailPage(user: _currentUser!),
                                ),
                              );
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const _ReportPage({required this.user});

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<_ReportPage> {
  String _selectedReason = 'Pornographic or vulgar content';
  final TextEditingController _otherController = TextEditingController();

  final List<String> _reportReasons = [
    'Pornographic or vulgar content',
    'Politically sensitive content',
    'Deception and Fraud',
    'Harassment and Threats',
    'Insults and Obscenity',
    'Incorrect Information',
    'Privacy Violation',
    'Plagiarism or Copyright Infringement',
    'Other',
  ];

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 20,
          ),
        ),
        title: const Text(
          'Report',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 显示被举报用户信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        widget.user['milyaUserIcon'] ??
                            'assets/images/userdefault_20250625.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 20,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user['milyaUserName'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Report this user for inappropriate behavior',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Reason for Report',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            // 举报原因列表
            Expanded(
              child: ListView.builder(
                itemCount: _reportReasons.length,
                itemBuilder: (context, index) {
                  final reason = _reportReasons[index];
                  final isSelected = _selectedReason == reason;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedReason = reason;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFFD8AC7B)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFD8AC7B)
                                    : const Color(0xFFCCCCCC),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Other Issue 输入框
            if (_selectedReason == 'Other') ...[
              const Text(
                'Other Issue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _otherController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Describe the issue',
                    hintStyle: TextStyle(color: Color(0xFF999999)),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Submit Report 按钮
            Container(
              width: double.infinity,
              height: 50,
              margin: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                onPressed: () {
                  // 提交举报
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report submitted successfully'),
                      backgroundColor: Color(0xFFD8AC7B),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD8AC7B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Submit Report',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
