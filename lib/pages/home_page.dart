import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
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

      // 随机选择一个用户
      final random = Random();
      _currentUser = _users[random.nextInt(_users.length)];

      // 随机选择3个其他用户作为粉丝头像
      final otherUsers = _users.where((user) => user != _currentUser).toList();
      _randomFollowers = [];
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
                      // 用户名
                      Text(
                        _currentUser!['milyaUserName'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500, // Medium
                          color: Color(0xFFFFFFFF),
                        ),
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
                            width:
                                20 +
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
                                  builder:
                                      (context) =>
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
