import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class VideoCallPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const VideoCallPage({super.key, required this.user});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  late AudioPlayer _audioPlayer;
  Timer? _callTimer;

  @override
  void initState() {
    super.initState();

    // 设置状态栏为透明
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // 初始化音频播放器
    _audioPlayer = AudioPlayer();

    // 初始化水波纹动画
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _rippleController.repeat();

    // 开始通话流程
    _startCall();
  }

  Future<void> _startCall() async {
    try {
      // 播放通话音频
      await _audioPlayer.play(
        AssetSource('images/milyaCall_music_20250626.mp3'),
      );
    } catch (e) {
      // 如果音频播放失败，继续进行通话流程
      print('Audio playback failed: $e');
    }

    // 30秒后自动挂断
    _callTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        _endCall();
      }
    });
  }

  void _simulateCall() {
    // 这个方法已经被_startCall替代，保留为空以避免错误
  }

  void _endCall() async {
    // 停止音频播放
    await _audioPlayer.stop();
    _callTimer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _audioPlayer.dispose();
    _callTimer?.cancel();
    // 恢复状态栏
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图片
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(widget.user['milyaShowPhotoArray'][0]),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 渐变覆盖层
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // 左上角头像
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            child: Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
                image: DecorationImage(
                  image: AssetImage(widget.user['milyaUserIcon']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 用户名（在头像右边11px）
          Positioned(
            top:
                MediaQuery.of(context).padding.top +
                20 +
                (31 - 14) / 2, // 垂直居中对齐头像
            left: 20 + 31 + 11, // 头像右边11px
            child: Text(
              widget.user['milyaUserName'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // 状态文本（在挂断按钮上方更远距离）
          Positioned(
            bottom:
                MediaQuery.of(context).padding.bottom +
                40 +
                200 +
                30, // 挂断按钮容器上方30px
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'On the line...',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),

          // 底部控制按钮
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 挂断按钮带水波纹
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 水波纹动画
                      AnimatedBuilder(
                        animation: _rippleAnimation,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // 第一圈水波纹
                              if (_rippleAnimation.value > 0.1)
                                Container(
                                  width: 80 + (_rippleAnimation.value * 60),
                                  height: 80 + (_rippleAnimation.value * 60),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(
                                        (1 - _rippleAnimation.value) * 0.6,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              // 第二圈水波纹
                              if (_rippleAnimation.value > 0.3)
                                Container(
                                  width:
                                      80 +
                                      ((_rippleAnimation.value - 0.2) * 80),
                                  height:
                                      80 +
                                      ((_rippleAnimation.value - 0.2) * 80),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(
                                        (1 - (_rippleAnimation.value - 0.2)) *
                                            0.4,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              // 第三圈水波纹
                              if (_rippleAnimation.value > 0.5)
                                Container(
                                  width:
                                      80 +
                                      ((_rippleAnimation.value - 0.4) * 100),
                                  height:
                                      80 +
                                      ((_rippleAnimation.value - 0.4) * 100),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(
                                        (1 - (_rippleAnimation.value - 0.4)) *
                                            0.2,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      // 挂断按钮（固定在中心）
                      GestureDetector(
                        onTap: _endCall,
                        child: Image.asset(
                          'assets/images/btn_video_call_20250625.png',
                          width: 80,
                          height: 80,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
