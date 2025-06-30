import 'package:shared_preferences/shared_preferences.dart';

class CoinsService {
  static const String _coinsKey = 'gold_coins';
  static const int _messageCoins = 6; // 每条消息消耗6金币
  static const double _defaultCoins = 100.0; // 新用户默认100金币

  // 获取当前金币数量
  static Future<double> getCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_coinsKey) ?? _defaultCoins;
  }

  // 设置金币数量
  static Future<void> setCoins(double coins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_coinsKey, coins);
  }

  // 增加金币
  static Future<double> addCoins(double amount) async {
    final currentCoins = await getCoins();
    final newCoins = currentCoins + amount;
    await setCoins(newCoins);
    return newCoins;
  }

  // 扣除金币（发送消息）
  static Future<bool> consumeCoinsForMessage() async {
    final currentCoins = await getCoins();
    if (currentCoins >= _messageCoins) {
      await setCoins(currentCoins - _messageCoins);
      return true; // 扣除成功
    }
    return false; // 金币不足
  }

  // 检查是否有足够金币发送消息
  static Future<bool> canSendMessage() async {
    final currentCoins = await getCoins();
    return currentCoins >= _messageCoins;
  }

  // 获取发送消息所需金币数
  static int getMessageCoinsCost() {
    return _messageCoins;
  }

  // 重置为默认金币（用于测试或新用户）
  static Future<void> resetToDefault() async {
    await setCoins(_defaultCoins);
  }
}
