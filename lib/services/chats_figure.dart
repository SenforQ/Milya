import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatsFigure {
  static const String _baseUrl =
      'https://open.bigmodel.cn/api/paas/v4/chat/completions';
  static const String _apiKey =
      'e882dfabbbc84db692d570bc4bfa1fe9.ODOjIQBmkIatsGKb';

  // 聊天记录存储键前缀
  static const String _chatHistoryPrefix = 'chat_history_';
  static const String _lastChatTimePrefix = 'last_chat_time_';
  static const String _recommendedFigureKey = 'recommended_figure';

  // 获取与特定角色的聊天记录
  static Future<List<Map<String, dynamic>>> getChatHistory(
    String figureName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('$_chatHistoryPrefix$figureName');
    if (historyJson != null) {
      final List<dynamic> historyList = jsonDecode(historyJson);
      return historyList.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // 保存聊天记录
  static Future<void> saveChatHistory(
    String figureName,
    List<Map<String, dynamic>> history,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(history);
    await prefs.setString('$_chatHistoryPrefix$figureName', historyJson);
    // 同时更新最后聊天时间
    await prefs.setInt(
      '$_lastChatTimePrefix$figureName',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // 获取所有有聊天记录的角色
  static Future<List<String>> getChatFigures() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final chatFigures = <String>[];

    for (String key in keys) {
      if (key.startsWith(_chatHistoryPrefix)) {
        final figureName = key.replaceFirst(_chatHistoryPrefix, '');
        chatFigures.add(figureName);
      }
    }

    return chatFigures;
  }

  // 获取角色最后聊天时间
  static Future<DateTime?> getLastChatTime(String figureName) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('$_lastChatTimePrefix$figureName');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  // 获取推荐角色
  static Future<String?> getRecommendedFigure() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_recommendedFigureKey);
  }

  // 设置推荐角色
  static Future<void> setRecommendedFigure(String figureName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recommendedFigureKey, figureName);
  }

  // 检查是否有任何聊天记录
  static Future<bool> hasAnyChatHistory() async {
    final chatFigures = await getChatFigures();
    return chatFigures.isNotEmpty;
  }

  // 获取角色最后一条消息
  static Future<String?> getLastMessage(String figureName) async {
    final history = await getChatHistory(figureName);
    if (history.isNotEmpty) {
      final lastMessage = history.last;
      if (lastMessage['role'] == 'assistant') {
        return lastMessage['content'];
      } else if (history.length > 1) {
        final secondLastMessage = history[history.length - 2];
        if (secondLastMessage['role'] == 'assistant') {
          return secondLastMessage['content'];
        }
      }
    }
    return null;
  }

  // AI对话功能
  static Future<String> sendMessage(
    String message,
    String figureName,
    Map<String, dynamic> figureData,
  ) async {
    try {
      // 获取聊天历史
      final chatHistory = await getChatHistory(figureName);

      // 构建系统提示
      final systemPrompt =
          '''You are ${figureData['milyaUserName']}, a jewelry enthusiast in the Milya community. 
${figureData['milyaUserIntroduction']}

You should respond in English, be friendly and engaging. Keep your responses conversational and natural, focusing on jewelry, fashion, and lifestyle topics. Your personality should match your description.''';

      // 构建消息列表
      final messages = [
        {'role': 'system', 'content': systemPrompt},
        ...chatHistory,
        {'role': 'user', 'content': message},
      ];

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'glm-4-flash',
          'messages': messages,
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiMessage = data['choices'][0]['message']['content'];

        // 保存聊天记录
        final updatedHistory = [
          ...chatHistory,
          {'role': 'user', 'content': message},
          {'role': 'assistant', 'content': aiMessage},
        ];

        await saveChatHistory(figureName, updatedHistory);

        return aiMessage;
      } else {
        debugPrint('API Error: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return "Sorry, I'm having trouble responding right now. Please try again later.";
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      return "Sorry, there was an error. Please check your connection and try again.";
    }
  }

  // 清除特定角色的聊天记录
  static Future<void> clearChatHistory(String figureName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_chatHistoryPrefix$figureName');
    await prefs.remove('$_lastChatTimePrefix$figureName');
  }

  // 清除所有聊天记录
  static Future<void> clearAllChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (String key in keys) {
      if (key.startsWith(_chatHistoryPrefix) ||
          key.startsWith(_lastChatTimePrefix)) {
        await prefs.remove(key);
      }
    }

    await prefs.remove(_recommendedFigureKey);
  }
}
