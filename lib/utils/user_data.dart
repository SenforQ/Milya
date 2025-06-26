import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class UserData {
  static const String _avatarKey = 'user_avatar';
  static const String _nicknameKey = 'user_nickname';
  static const String _signatureKey = 'user_signature';
  static const String _defaultAvatar = 'assets/images/userdefault_20250625.png';
  static const String _defaultSignature =
      'User hasn\'t had time to introduce themselves yet';

  // 获取用户头像
  static Future<String> getUserAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarKey) ?? _defaultAvatar;
  }

  // 设置用户头像
  static Future<void> setUserAvatar(String avatarPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarKey, avatarPath);
  }

  // 获取用户昵称
  static Future<String> getUserNickname() async {
    final prefs = await SharedPreferences.getInstance();
    String? nickname = prefs.getString(_nicknameKey);

    if (nickname == null) {
      // 生成随机昵称 Milya + 1000-9999
      final random = Random();
      final randomNumber = 1000 + random.nextInt(9000); // 1000-9999
      nickname = 'Milya$randomNumber';
      await prefs.setString(_nicknameKey, nickname);
    }

    return nickname;
  }

  // 设置用户昵称
  static Future<void> setUserNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nicknameKey, nickname);
  }

  // 获取用户个性签名
  static Future<String> getUserSignature() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_signatureKey) ?? _defaultSignature;
  }

  // 设置用户个性签名
  static Future<void> setUserSignature(String signature) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_signatureKey, signature);
  }

  // 检查是否首次使用（用于初始化）
  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_nicknameKey);
  }
}
