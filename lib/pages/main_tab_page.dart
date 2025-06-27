import 'package:flutter/material.dart';
import 'home_page.dart';
import 'avatar_page.dart';
import 'chats_page.dart';
import 'me_page.dart';
import '../services/music_service.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _currentIndex = 0;
  bool _isPlaying = false;
  final MusicService _musicService = MusicService();
  Offset _musicButtonPosition = const Offset(16, 60); // 音乐按钮位置，避开状态栏

  // 页面列表
  final List<Widget> _pages = [
    const HomePage(),
    const AvatarPage(),
    const ChatsPage(),
    const MePage(),
  ];

  // TabBar配置
  final List<TabConfig> _tabConfigs = [
    TabConfig(
      normalIcon: 'assets/images/btn_tab_home_pre_20250625.png',
      selectedIcon: 'assets/images/btn_tab_home_nor_20250625.png',
    ),
    TabConfig(
      normalIcon: 'assets/images/btn_tab_avatar_pre_20250625.png',
      selectedIcon: 'assets/images/btn_tab_avatar_nor_20250625.png',
    ),
    TabConfig(
      normalIcon: 'assets/images/btn_tab_chats_pre_20250625.png',
      selectedIcon: 'assets/images/btn_tab_chats_nor_20250625.png',
    ),
    TabConfig(
      normalIcon: 'assets/images/btn_tab_me_pre_20250625.png',
      selectedIcon: 'assets/images/btn_tab_me_nor_20250625.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
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
    await _musicService.toggle();
    if (mounted) {
      setState(() {
        _isPlaying = _musicService.isPlaying;
      });
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

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _pages),

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

                  // 限制在安全区域内，避开底部导航栏
                  newX = newX.clamp(0.0, screenSize.width - 48);
                  newY = newY.clamp(safeArea.top,
                      screenSize.height - 120); // 120 = 底部导航栏高度 + 一些间距

                  // 边缘吸附功能：如果拖到屏幕边缘附近，自动吸附到边缘
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          border: Border(top: BorderSide(color: Color(0xFFE5E5E5), width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_tabConfigs.length, (index) {
                return Expanded(child: _buildTabItem(index));
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index) {
    final config = _tabConfigs[index];
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(
            isSelected ? config.selectedIcon : config.normalIcon,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            // 如果图片不存在，显示占位图标
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                _getPlaceholderIcon(index),
                size: 24,
                color: isSelected ? Colors.black : Colors.grey,
              );
            },
          ),
        ),
      ),
    );
  }

  // 获取占位图标
  IconData _getPlaceholderIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.person;
      case 2:
        return Icons.chat;
      case 3:
        return Icons.account_circle;
      default:
        return Icons.circle;
    }
  }
}

// TabBar配置类
class TabConfig {
  final String normalIcon;
  final String selectedIcon;

  TabConfig({required this.normalIcon, required this.selectedIcon});
}
