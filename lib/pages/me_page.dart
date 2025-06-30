import 'package:flutter/material.dart';
import 'dart:io';
import '../utils/user_data.dart';
import '../utils/image_manager.dart';
import '../services/vip_service.dart';
import 'edit_profile_page.dart';
import 'terms_page.dart';
import 'privacy_page.dart';
import 'about_page.dart';
import 'ai_jewelry_expert_page.dart';
import 'wallet_page.dart';
import 'vip_benefits_page.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  String _userAvatar = '';
  String _userNickname = '';
  String _userSignature = '';
  bool _isVip = false;
  int _vipRemainingDays = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _userAvatar = await UserData.getUserAvatar();
    _userNickname = await UserData.getUserNickname();
    _userSignature = await UserData.getUserSignature();
    _isVip = await VipService.isVipActive();
    if (_isVip) {
      _vipRemainingDays = await VipService.getVipRemainingDays();
    }
    setState(() {});
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const EditProfilePage()));

    // 如果编辑页面返回true，说明数据已更新，重新加载数据
    if (result == true) {
      _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题区域
            Container(
              padding: const EdgeInsets.all(20),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Me',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // 主要内容区域
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20), // 距离卡片区域20px
                  child: SingleChildScrollView(
                    // 使整个内容区域可滑动
                    child: Column(
                      children: [
                        // 用户头像和编辑按钮
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: _navigateToEditProfile,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _userAvatar.isNotEmpty
                                      ? _buildAvatarImage(_userAvatar, 80)
                                      : Container(
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.person,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            // 编辑按钮
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: _navigateToEditProfile,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFA67B6D), // 指定的编辑按钮颜色
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // 用户昵称和VIP标识
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _userNickname,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            if (_isVip) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700),
                                      Color(0xFFFFA500)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.diamond,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'VIP',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 12),

                        // 用户个性签名
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _userSignature,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              height: 1.4,
                            ),
                          ),
                        ),

                        // VIP状态信息
                        if (_isVip) ...[
                          const SizedBox(height: 8),
                          Text(
                            'VIP expires in $_vipRemainingDays days',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],

                        const SizedBox(height: 30), // 修改为30px

                        // VIP区域
                        GestureDetector(
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const VipBenefitsPage(),
                              ),
                            );
                            // 返回后刷新数据，可能VIP状态已改变
                            _loadUserData();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 0),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 背景VIP图片
                                Image.asset(
                                  'assets/images/btn_me_vip_20250625.png',
                                  width: double.infinity,
                                  fit: BoxFit.fitWidth,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey,
                                          size: 40,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                // Join VIP按钮
                                Positioned(
                                  right: 12,
                                  child: Image.asset(
                                    'assets/images/btn_me_join_vip_20250625.png',
                                    width: 57,
                                    height: 30,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 57,
                                        height: 30,
                                        color: Colors.orange,
                                        child: const Center(
                                          child: Text(
                                            'VIP',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // AI珠宝专家胶囊按钮
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AIJewelryExpertPage(),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/AiJewelryIcon_20250627.png',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF8B5CF6),
                                                Color(0xFFEC4899),
                                              ],
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.auto_awesome,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AI Jewelry Expert',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Get professional jewelry advice',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 菜单项列表
                        Column(
                          children: [
                            _buildMenuItem(
                              title: 'Wallet',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const WalletPage(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              title: 'User Contract',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const TermsPage(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              title: 'Privacy Policy',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const PrivacyPage(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              title: 'About us',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const AboutPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 40), // 底部额外空间
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String imagePath, double size) {
    if (imagePath.startsWith('local_avatars/')) {
      // 本地图片，使用 FutureBuilder 异步加载
      return FutureBuilder<String>(
        future: ImageManager.getFullPath(imagePath),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return FutureBuilder<bool>(
              future: ImageManager.isLocalFile(imagePath),
              builder: (context, existsSnapshot) {
                if (existsSnapshot.hasData && existsSnapshot.data == true) {
                  return Image.file(
                    File(snapshot.data!),
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultAvatar(size);
                    },
                  );
                } else {
                  return _buildDefaultAvatar(size);
                }
              },
            );
          } else {
            return _buildDefaultAvatar(size);
          }
        },
      );
    } else {
      // 资源图片
      return Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar(size);
        },
      );
    }
  }

  Widget _buildDefaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[300],
      child: Icon(Icons.person, size: size * 0.5, color: Colors.grey),
    );
  }

  Widget _buildMenuItem({required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
