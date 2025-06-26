import 'package:flutter/material.dart';
import 'home_page.dart';
import 'avatar_page.dart';
import 'chats_page.dart';
import 'me_page.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _currentIndex = 0;

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

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
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
