import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageManager {
  static const String _avatarFolderName = 'avatars';

  // 从相册选择图片
  static Future<String?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        // 保存图片到本地并返回相对路径
        return await _saveImageToLocal(image);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // 从相机拍摄图片
  static Future<String?> pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        // 保存图片到本地并返回相对路径
        return await _saveImageToLocal(image);
      }
      return null;
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  // 保存图片到本地应用目录
  static Future<String> _saveImageToLocal(XFile image) async {
    try {
      // 获取应用文档目录
      final Directory appDocDir = await getApplicationDocumentsDirectory();

      // 创建头像文件夹
      final Directory avatarDir = Directory(
        '${appDocDir.path}/$_avatarFolderName',
      );
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      // 生成唯一文件名
      final String fileName =
          'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String localPath = '${avatarDir.path}/$fileName';

      // 复制文件到本地目录
      await File(image.path).copy(localPath);

      // 返回相对路径（用于存储）
      return 'local_avatars/$fileName';
    } catch (e) {
      debugPrint('Error saving image: $e');
      rethrow;
    }
  }

  // 根据路径获取完整的本地文件路径
  static Future<String> getFullPath(String relativePath) async {
    if (relativePath.startsWith('local_avatars/')) {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String fileName = relativePath.replaceFirst('local_avatars/', '');
      return '${appDocDir.path}/$_avatarFolderName/$fileName';
    }
    return relativePath; // 如果是assets路径，直接返回
  }

  // 检查本地文件是否存在
  static Future<bool> isLocalFile(String imagePath) async {
    if (imagePath.startsWith('local_avatars/')) {
      final String fullPath = await getFullPath(imagePath);
      return await File(fullPath).exists();
    }
    return false;
  }

  // 删除本地头像文件
  static Future<bool> deleteLocalAvatar(String relativePath) async {
    try {
      if (relativePath.startsWith('local_avatars/')) {
        final String fullPath = await getFullPath(relativePath);
        final File file = File(fullPath);
        if (await file.exists()) {
          await file.delete();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting local avatar: $e');
      return false;
    }
  }

  // 清理旧的头像文件（保留最新的5个）
  static Future<void> cleanupOldAvatars() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory avatarDir = Directory(
        '${appDocDir.path}/$_avatarFolderName',
      );

      if (await avatarDir.exists()) {
        final List<FileSystemEntity> files = avatarDir.listSync();

        // 按修改时间排序，保留最新的5个文件
        files.sort((a, b) {
          final aStat = a.statSync();
          final bStat = b.statSync();
          return bStat.modified.compareTo(aStat.modified);
        });

        // 删除超过5个的旧文件
        if (files.length > 5) {
          for (int i = 5; i < files.length; i++) {
            try {
              await files[i].delete();
            } catch (e) {
              debugPrint('Error deleting old avatar: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old avatars: $e');
    }
  }
}
