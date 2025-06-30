import 'package:shared_preferences/shared_preferences.dart';

class VipService {
  static const String _vipStatusKey = 'vip_status';
  static const String _vipExpiryKey = 'vip_expiry_date';
  static const String _vipProductIdKey = 'vip_product_id';

  // 激活VIP会员
  static Future<void> activateVip(String productId) async {
    final prefs = await SharedPreferences.getInstance();

    // 根据产品ID设置VIP过期时间
    DateTime expiryDate;
    if (productId == 'Subsweete3_29' || productId == 'Subsweete3_59') {
      // 订阅类型产品，设置为一周后过期
      expiryDate = DateTime.now().add(const Duration(days: 7));
    } else {
      // 默认一周
      expiryDate = DateTime.now().add(const Duration(days: 7));
    }

    await prefs.setBool(_vipStatusKey, true);
    await prefs.setString(_vipExpiryKey, expiryDate.toIso8601String());
    await prefs.setString(_vipProductIdKey, productId);

    // 调试信息
    print('VIP激活成功 - 产品ID: $productId, 过期时间: ${expiryDate.toIso8601String()}');
  }

  // 检查是否为VIP用户
  static Future<bool> isVipActive() async {
    final prefs = await SharedPreferences.getInstance();

    final isVip = prefs.getBool(_vipStatusKey) ?? false;
    if (!isVip) {
      print('VIP状态检查: 非VIP用户');
      return false;
    }

    // 检查是否过期
    final expiryString = prefs.getString(_vipExpiryKey);
    if (expiryString == null) {
      print('VIP状态检查: 没有过期时间数据');
      return false;
    }

    final expiryDate = DateTime.parse(expiryString);
    final now = DateTime.now();

    if (now.isAfter(expiryDate)) {
      // VIP已过期，清除状态
      print('VIP状态检查: VIP已过期，清除状态');
      await clearVipStatus();
      return false;
    }

    print('VIP状态检查: VIP有效，过期时间: ${expiryDate.toIso8601String()}');
    return true;
  }

  // 获取VIP过期时间
  static Future<DateTime?> getVipExpiryDate() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString(_vipExpiryKey);

    if (expiryString == null) return null;

    try {
      return DateTime.parse(expiryString);
    } catch (e) {
      return null;
    }
  }

  // 获取VIP产品ID
  static Future<String?> getVipProductId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_vipProductIdKey);
  }

  // 清除VIP状态
  static Future<void> clearVipStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vipStatusKey);
    await prefs.remove(_vipExpiryKey);
    await prefs.remove(_vipProductIdKey);
    print('VIP状态已清除');
  }

  // 获取VIP剩余天数
  static Future<int> getVipRemainingDays() async {
    final expiryDate = await getVipExpiryDate();
    if (expiryDate == null) return 0;

    final now = DateTime.now();
    if (now.isAfter(expiryDate)) return 0;

    return expiryDate.difference(now).inDays + 1; // +1 因为当天也算一天
  }

  // 延长VIP时间（用于处理续订）
  static Future<void> extendVip(String productId, int days) async {
    final prefs = await SharedPreferences.getInstance();

    DateTime newExpiryDate;
    final currentExpiryString = prefs.getString(_vipExpiryKey);

    if (currentExpiryString != null) {
      // 如果已有VIP，在现有基础上延长
      final currentExpiry = DateTime.parse(currentExpiryString);
      final now = DateTime.now();

      if (currentExpiry.isAfter(now)) {
        // VIP还未过期，在现有时间基础上延长
        newExpiryDate = currentExpiry.add(Duration(days: days));
      } else {
        // VIP已过期，从现在开始计算
        newExpiryDate = now.add(Duration(days: days));
      }
    } else {
      // 没有现有VIP，从现在开始计算
      newExpiryDate = DateTime.now().add(Duration(days: days));
    }

    await prefs.setBool(_vipStatusKey, true);
    await prefs.setString(_vipExpiryKey, newExpiryDate.toIso8601String());
    await prefs.setString(_vipProductIdKey, productId);

    print('VIP延长成功 - 新过期时间: ${newExpiryDate.toIso8601String()}');
  }

  // 调试方法：获取所有VIP相关数据
  static Future<Map<String, dynamic>> getVipDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isVip': prefs.getBool(_vipStatusKey) ?? false,
      'expiryDate': prefs.getString(_vipExpiryKey),
      'productId': prefs.getString(_vipProductIdKey),
      'remainingDays': await getVipRemainingDays(),
      'isActive': await isVipActive(),
    };
  }
}
