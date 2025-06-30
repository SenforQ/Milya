import 'package:flutter/material.dart';
import 'dart:io';
import '../utils/user_data.dart';
import '../utils/image_manager.dart';
import '../services/vip_service.dart';
import 'vip_benefits_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();

  String _originalAvatar = ''; // 保存原始头像，用于取消时恢复
  String _previewAvatar = ''; // 预览头像，用于显示
  bool _isLoading = false;
  bool _isVip = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final nickname = await UserData.getUserNickname();
    final signature = await UserData.getUserSignature();
    final avatar = await UserData.getUserAvatar();
    final isVip = await VipService.isVipActive();

    setState(() {
      _nicknameController.text = nickname;
      _signatureController.text = signature;
      _originalAvatar = avatar; // 保存原始头像
      _previewAvatar = avatar; // 初始预览头像与原始头像相同
      _isVip = isVip;
    });
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 检查VIP状态
      final isVip = await VipService.isVipActive();

      // 如果用户不是VIP，显示升级提示并阻止保存
      if (!isVip) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showVipUpgradeDialog('profile editing');
        }
        return;
      }

      // 保存用户数据
      await UserData.setUserNickname(_nicknameController.text.trim());
      await UserData.setUserSignature(_signatureController.text.trim());

      // 只有在头像发生变化时才保存头像
      if (_previewAvatar != _originalAvatar) {
        await UserData.setUserAvatar(_previewAvatar);
        // 如果是新的本地头像，清理旧头像
        if (_previewAvatar.startsWith('local_avatars/')) {
          ImageManager.cleanupOldAvatars();
        }
      }

      // 显示成功提示，根据VIP状态显示不同消息
      if (mounted) {
        String message = 'Profile saved successfully!';
        if (isVip) {
          final remainingDays = await VipService.getVipRemainingDays();
          message += ' (VIP: $remainingDays days remaining)';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                if (isVip) ...[
                  const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 8),
                ],
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: isVip ? const Color(0xFF8B5CF6) : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // 返回上一页
        Navigator.of(context).pop(true); // 返回true表示数据已更新
      }
    } catch (e) {
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save profile. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAvatarSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 顶部拖拽指示器
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    const Text(
                      'Change Avatar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 系统图片选择选项
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSystemOption(
                          icon: Icons.photo_library,
                          label: 'Gallery',
                          onTap: () async {
                            Navigator.of(context).pop();
                            final imagePath =
                                await ImageManager.pickImageFromGallery();
                            if (imagePath != null) {
                              setState(() {
                                _previewAvatar = imagePath; // 只更新预览，不保存
                              });
                            }
                          },
                        ),
                        _buildSystemOption(
                          icon: Icons.camera_alt,
                          label: 'Camera',
                          onTap: () async {
                            Navigator.of(context).pop();
                            final imagePath =
                                await ImageManager.pickImageFromCamera();
                            if (imagePath != null) {
                              setState(() {
                                _previewAvatar = imagePath; // 只更新预览，不保存
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),

                    const Text(
                      'Or choose from presets:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 15),

                    // 预设头像选项
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildAvatarOption(
                          'assets/images/userdefault_20250625.png',
                        ),
                        _buildAvatarOption(
                          'assets/figure/1/p/1_p_2025_06_24_1.png',
                        ),
                        _buildAvatarOption(
                          'assets/figure/2/p/2_p_2025_06_24_1.png',
                        ),
                        _buildAvatarOption(
                          'assets/figure/3/p/3_p_2025_06_24_1.png',
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildAvatarOption(
                          'assets/figure/4/p/4_p_2025_06_24_1.png',
                        ),
                        _buildAvatarOption(
                          'assets/figure/5/p/5_p_2025_06_24_1.png',
                        ),
                        _buildAvatarOption(
                          'assets/figure/6/p/6_p_2025_06_24_1.png',
                        ),
                        _buildAvatarOption(
                          'assets/figure/7/p/7_p_2025_06_24_1.png',
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSystemOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          color: Colors.grey.withOpacity(0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: const Color(0xFF8B5CF6)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption(String avatarPath) {
    final isSelected = _previewAvatar == avatarPath;

    return GestureDetector(
      onTap: () {
        setState(() {
          _previewAvatar = avatarPath; // 只更新预览，不保存
        });
        Navigator.of(context).pop();
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B5CF6)
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 3 : 2,
          ),
        ),
        child: ClipOval(
          child: Image.asset(
            avatarPath,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.person, color: Colors.grey, size: 30),
              );
            },
          ),
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

  void _showVipUpgradeDialog(String featureUsed) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.diamond,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'VIP Feature',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile editing is only available for VIP members.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Upgrade to VIP to unlock this and many other premium features!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Later',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 跳转到VIP购买页面
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const VipBenefitsPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Upgrade VIP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onBack() {
    // 如果头像发生了变化但没有保存，删除临时的本地图片文件
    if (_previewAvatar != _originalAvatar &&
        _previewAvatar.startsWith('local_avatars/')) {
      // 异步删除，不阻塞UI
      ImageManager.deleteLocalAvatar(_previewAvatar);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // 如果头像发生了变化但没有保存，删除临时的本地图片文件
          if (_previewAvatar != _originalAvatar &&
              _previewAvatar.startsWith('local_avatars/')) {
            // 异步删除，不阻塞UI
            ImageManager.deleteLocalAvatar(_previewAvatar);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _onBack,
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // 头像编辑区域
              GestureDetector(
                onTap: _showAvatarSelection,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: _previewAvatar.isNotEmpty
                            ? _buildAvatarImage(_previewAvatar, 100)
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),

                    // 编辑图标
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Tap to change avatar',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 40),

              // 昵称输入框
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nickname',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      hintText: 'Enter your nickname',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 个性签名输入框
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bio',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _signatureController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tell us about yourself...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD2B5), Color(0xFFFF9469)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _signatureController.dispose();
    super.dispose();
  }
}
