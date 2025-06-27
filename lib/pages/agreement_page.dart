import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main_tab_page.dart';
import 'terms_page.dart';
import 'privacy_page.dart';
import '../services/music_service.dart';

class AgreementPage extends StatefulWidget {
  const AgreementPage({super.key});

  @override
  State<AgreementPage> createState() => _AgreementPageState();
}

class _AgreementPageState extends State<AgreementPage> {
  bool _isAgreed = false;
  bool _isPlaying = false;
  final MusicService _musicService = MusicService();
  Offset _musicButtonPosition = const Offset(16, 16); // 音乐按钮位置

  @override
  void initState() {
    super.initState();
    _musicService.initialize();
    _updateMusicState();
  }

  void _updateMusicState() {
    // 定期检查音乐播放状态
    if (mounted) {
      setState(() {
        _isPlaying = _musicService.isPlaying;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _updateMusicState();
      });
    }
  }

  Future<void> _toggleMusic() async {
    try {
      await _musicService.toggle();
      if (mounted) {
        setState(() {
          _isPlaying = _musicService.isPlaying;
        });
      }
    } catch (e) {
      print('Music playback error: $e');
      _showToast('Music playback error: $e');
    }
  }

  Widget _buildMusicButton(bool isDragging) {
    return GestureDetector(
      onTap: isDragging ? null : _toggleMusic,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(isDragging ? 0.8 : 0.6),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          _isPlaying ? Icons.pause : Icons.music_note,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  void _onEnterApp() {
    if (!_isAgreed) {
      _showToast('Please agree to the terms');
      return;
    }

    // 检查音乐是否已经开启
    if (_isPlaying) {
      // 音乐已开启，直接进入app
      _enterMainApp();
    } else {
      // 音乐未开启，显示音乐提示弹窗
      _showMusicPromptDialog();
    }
  }

  void _enterMainApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainTabPage()),
    );
  }

  void _showMusicPromptDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题
                const Text(
                  'Music Experience',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 16),

                // 提示内容
                const Text(
                  'For a better experience with our App, we suggest you start a musical journey',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // 按钮区域
                Row(
                  children: [
                    // Skip按钮
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              _enterMainApp();
                            },
                            borderRadius: BorderRadius.circular(22),
                            child: const Center(
                              child: Text(
                                'Skip',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // OK按钮
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              Navigator.of(context).pop();
                              // 开启音乐
                              await _musicService.play();
                              _enterMainApp();
                            },
                            borderRadius: BorderRadius.circular(22),
                            child: const Center(
                              child: Text(
                                'OK',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 底部音乐来源说明
                const Text(
                  '* This music is created by AI and does not involve any copyright',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEulaUrl() async {
    final Uri url = Uri.parse(
        'https://www.apple.com/legal/internet-services/itunes/dev/stdeula');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showToast('Cannot open EULA link');
      }
    } catch (e) {
      _showToast('Cannot open EULA link');
    }
  }

  void _showToast(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(message: message),
    );

    overlay?.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_login_shadow_20250625.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0x80000000)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // 原有内容
                Column(
                  children: [
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          // Enter APP 按钮
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: const Color(0xFFF5E6D3),
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    image: const DecorationImage(
                                      image: AssetImage(
                                        'assets/images/btn_no_20250625.png',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _onEnterApp,
                                    borderRadius: BorderRadius.circular(25),
                                    child: const Center(
                                      child: Text(
                                        'Enter APP',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF613C1B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // 协议勾选
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isAgreed = !_isAgreed;
                                  });
                                },
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.8),
                                      width: 2,
                                    ),
                                    color: _isAgreed
                                        ? Colors.orange
                                        : Colors.transparent,
                                  ),
                                  child: _isAgreed
                                      ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'I have read and agree ',
                                      ),
                                      WidgetSpan(
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const TermsPage(),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            'Terms of Service',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF4A90E2),
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const TextSpan(text: ', '),
                                      WidgetSpan(
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const PrivacyPage(),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            'Privacy Policy',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF4A90E2),
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const TextSpan(text: ' and '),
                                      WidgetSpan(
                                        child: GestureDetector(
                                          onTap: _openEulaUrl,
                                          child: const Text(
                                            'EULA',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF4A90E2),
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),

                // 可拖动的音乐按钮
                Positioned(
                  left: _musicButtonPosition.dx,
                  top: _musicButtonPosition.dy,
                  child: Draggable<String>(
                    data: 'music_button',
                    feedback: _buildMusicButton(true),
                    childWhenDragging: Container(),
                    onDragEnd: (details) {
                      setState(() {
                        // 确保按钮不会拖到屏幕外
                        final screenSize = MediaQuery.of(context).size;
                        final safeArea = MediaQuery.of(context).padding;

                        double newX = details.offset.dx;
                        double newY = details.offset.dy;

                        // 限制在安全区域内
                        newX = newX.clamp(0.0, screenSize.width - 48);
                        newY = newY.clamp(safeArea.top,
                            screenSize.height - safeArea.bottom - 48);

                        // 边缘吸附功能
                        if (newX < 60) {
                          newX = 16; // 吸附到左边缘
                        } else if (newX > screenSize.width - 108) {
                          newX = screenSize.width - 64; // 吸附到右边缘
                        }

                        _musicButtonPosition = Offset(newX, newY);
                      });
                    },
                    child: _buildMusicButton(false),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Toast组件
class _ToastWidget extends StatefulWidget {
  final String message;

  const _ToastWidget({required this.message});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.45,
      left: 40,
      right: 40,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xE6000000),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
