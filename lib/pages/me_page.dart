import 'package:flutter/material.dart';
import 'dart:io';
import '../utils/user_data.dart';
import '../utils/image_manager.dart';
import 'edit_profile_page.dart';
import 'terms_page.dart';
import 'privacy_page.dart';
import 'about_page.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  String _userAvatar = '';
  String _userNickname = '';
  String _userSignature = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _userAvatar = await UserData.getUserAvatar();
    _userNickname = await UserData.getUserNickname();
    _userSignature = await UserData.getUserSignature();
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
                                  child:
                                      _userAvatar.isNotEmpty
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

                        // 用户昵称
                        Text(
                          _userNickname,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
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

                        const SizedBox(height: 40),

                        // 菜单项列表
                        Column(
                          children: [
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
