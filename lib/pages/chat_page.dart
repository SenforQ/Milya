import 'package:flutter/material.dart';
import 'dart:math';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/user_data.dart';
import '../services/chats_figure.dart';
import 'video_call_page.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const ChatPage({super.key, required this.user});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _userAvatar = '';
  String _userNickname = '';
  String _backgroundImage = '';
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _addWelcomeMessage();
    _selectBackgroundImage();
    _checkBlockStatus();
  }

  void _selectBackgroundImage() {
    // 在初始化时选择背景图片，之后不再变化
    final List<String> photoArray = List<String>.from(
      widget.user['milyaShowPhotoArray'],
    );
    final random = Random();
    _backgroundImage = photoArray[random.nextInt(photoArray.length)];
  }

  Future<void> _initializeUserData() async {
    _userAvatar = await UserData.getUserAvatar();
    _userNickname = await UserData.getUserNickname();
    setState(() {});
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text: widget.user['milyaSayHi'],
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    // 检查是否被拉黑
    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.block, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Cannot send message to blocked user'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    // 添加用户消息
    setState(() {
      _messages.add(
        ChatMessage(text: userMessage, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    // 发送到AI并获取回复
    try {
      final aiResponse = await ChatsFigure.sendMessage(
        userMessage,
        widget.user['milyaUserName'],
        widget.user,
      );

      setState(() {
        _messages.add(
          ChatMessage(
            text: aiResponse,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'Sorry, I\'m having trouble responding right now. Please try again later.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _makeVideoCall() {
    // 检查是否被拉黑
    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.block, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Cannot make calls to blocked user'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

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
              const Icon(Icons.videocam, color: Color(0xFF4CAF50), size: 24),
              const SizedBox(width: 8),
              Text(
                'Video Call',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          content: Text(
            'Start a video call with ${widget.user['milyaUserName']}?',
            style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, color: Color(0xFF999999)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startVideoCall();
              },
              child: const Text(
                'Call',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _startVideoCall() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VideoCallPage(user: widget.user)),
    );
  }

  void _showRequestConfirmDialog(String type) {
    // 检查是否被拉黑
    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.block, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Cannot request media from blocked user'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final String typeName = type == 'photo' ? 'Photo' : 'Video';
    final String typeIcon = type == 'photo' ? '📸' : '🎥';

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
              Text(typeIcon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'Request $typeName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          content: Text(
            'Do you want to request a $typeName from ${widget.user['milyaUserName']}?\n\nNote: This requires the other person\'s consent to be sent.',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, color: Color(0xFF999999)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendMediaRequest(type);
              },
              child: Text(
                'Send Request',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _sendMediaRequest(String type) {
    final String typeName = type == 'photo' ? 'photo' : 'video';

    // 添加用户请求消息
    setState(() {
      _messages.add(
        ChatMessage(
          text: 'Requested a $typeName from ${widget.user['milyaUserName']}',
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
    });

    _scrollToBottom();

    // 模拟对方同意并发送媒体文件
    Future.delayed(const Duration(seconds: 2), () {
      _sendMediaResponse(type);
    });
  }

  void _sendMediaResponse(String type) {
    if (type == 'photo') {
      _sendRandomPhoto();
    } else {
      _sendRandomVideo();
    }
  }

  void _sendRandomPhoto() {
    final List<String> photoArray = List<String>.from(
      widget.user['milyaShowPhotoArray'] ?? [],
    );

    if (photoArray.isNotEmpty) {
      final random = Random();
      final String randomPhoto = photoArray[random.nextInt(photoArray.length)];

      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Here\'s a photo for you! 📸',
            isUser: false,
            timestamp: DateTime.now(),
            mediaPath: randomPhoto,
            mediaType: 'photo',
          ),
        );
      });

      _scrollToBottom();
    }
  }

  void _sendRandomVideo() {
    final List<String> videoArray = List<String>.from(
      widget.user['milyaShowVideoArray'] ?? [],
    );

    if (videoArray.isNotEmpty) {
      final random = Random();
      final String randomVideo = videoArray[random.nextInt(videoArray.length)];

      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Here\'s a video for you! 🎥',
            isUser: false,
            timestamp: DateTime.now(),
            mediaPath: randomVideo,
            mediaType: 'video',
          ),
        );
      });

      _scrollToBottom();
    }
  }

  Future<void> _checkBlockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final blockedUsers = prefs.getStringList('blocked_users') ?? [];
    setState(() {
      _isBlocked = blockedUsers.contains(widget.user['milyaUserName']);
    });
  }

  Future<void> _blockUser() async {
    final prefs = await SharedPreferences.getInstance();
    final blockedUsers = prefs.getStringList('blocked_users') ?? [];

    if (!blockedUsers.contains(widget.user['milyaUserName'])) {
      blockedUsers.add(widget.user['milyaUserName']);
      await prefs.setStringList('blocked_users', blockedUsers);

      setState(() {
        _isBlocked = true;
      });

      // 显示拉黑成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.block, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('${widget.user['milyaUserName']} has been blocked'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showBlockDialog() {
    if (_isBlocked) {
      // 如果已经拉黑，显示解除拉黑选项
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
                const Icon(Icons.person_remove, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Unblock User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
            content: Text(
              'Do you want to unblock ${widget.user['milyaUserName']}?\n\nYou will be able to receive messages and make calls again.',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, color: Color(0xFF999999)),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _unblockUser();
                },
                child: const Text(
                  'Unblock',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      // 显示拉黑确认对话框
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
                const Icon(Icons.block, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Block User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to block ${widget.user['milyaUserName']}?\n\n• You will not receive any messages\n• You cannot make video calls\n• You cannot request photos/videos\n\nThis action can be undone later.',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, color: Color(0xFF999999)),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _blockUser();
                },
                child: const Text(
                  'Block',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _unblockUser() async {
    final prefs = await SharedPreferences.getInstance();
    final blockedUsers = prefs.getStringList('blocked_users') ?? [];

    blockedUsers.remove(widget.user['milyaUserName']);
    await prefs.setStringList('blocked_users', blockedUsers);

    setState(() {
      _isBlocked = false;
    });

    // 显示解除拉黑成功提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.person_add, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('${widget.user['milyaUserName']} has been unblocked'),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            // 角色头像
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  widget.user['milyaUserIcon'],
                  width: 26,
                  height: 26,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 26,
                      height: 26,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.person,
                        color: Colors.grey,
                        size: 16,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(width: 10),

            // 角色名字
            Text(
              widget.user['milyaUserName'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),

            const Spacer(),

            // 拉黑按钮
            IconButton(
              onPressed: () => _showBlockDialog(),
              icon: Icon(
                _isBlocked ? Icons.person_remove : Icons.block,
                color: _isBlocked ? Colors.orange : Colors.red,
                size: 24,
              ),
              tooltip: _isBlocked ? 'Unblock User' : 'Block User',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 聊天内容区域
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_backgroundImage),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0x4D000000), // #000000 with alpha 0.3
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isLoading) {
                      return _buildLoadingMessage();
                    }

                    final message = _messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
            ),
          ),

          // 请求按钮区域
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // 请求照片按钮
                GestureDetector(
                  onTap:
                      _isBlocked
                          ? null
                          : () => _showRequestConfirmDialog('photo'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _isBlocked
                              ? Colors.grey.withOpacity(0.1)
                              : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            _isBlocked
                                ? Colors.grey.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_camera,
                          size: 16,
                          color:
                              _isBlocked ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Request Photo',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                _isBlocked
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // 请求视频按钮
                GestureDetector(
                  onTap:
                      _isBlocked
                          ? null
                          : () => _showRequestConfirmDialog('video'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _isBlocked
                              ? Colors.grey.withOpacity(0.1)
                              : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            _isBlocked
                                ? Colors.grey.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam,
                          size: 16,
                          color:
                              _isBlocked ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Request Video',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                _isBlocked
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 输入区域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 拉黑状态提示
                if (_isBlocked)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.block, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'User is blocked. Unblock to continue chatting.',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isBlocked,
                        decoration: InputDecoration(
                          hintText:
                              _isBlocked
                                  ? 'User is blocked'
                                  : 'Type a message...',
                          hintStyle: TextStyle(
                            color:
                                _isBlocked ? Colors.red.withOpacity(0.6) : null,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(
                              color:
                                  _isBlocked
                                      ? Colors.red.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(
                              color:
                                  _isBlocked
                                      ? Colors.red.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(
                              color:
                                  _isBlocked
                                      ? Colors.red.withOpacity(0.5)
                                      : const Color(0xFF8B5CF6),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 发送消息按钮
                    GestureDetector(
                      onTap: _isBlocked ? null : _sendMessage,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              _isBlocked
                                  ? Colors.grey.withOpacity(0.3)
                                  : const Color(0xFFFF9469),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.send,
                          color: _isBlocked ? Colors.grey : Colors.white,
                          size: 24,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 通话按钮
                    GestureDetector(
                      onTap: _isBlocked ? null : _makeVideoCall,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              _isBlocked
                                  ? Colors.grey.withOpacity(0.3)
                                  : const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.videocam,
                          color: _isBlocked ? Colors.grey : Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            // AI头像
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: ClipOval(
                child: Image.asset(
                  widget.user['milyaUserIcon'],
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.person,
                        color: Colors.grey,
                        size: 20,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0xFF8B5CF6) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文本消息
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                  ),

                  // 媒体内容
                  if (message.mediaPath != null) ...[
                    const SizedBox(height: 8),
                    _buildMediaContent(message),
                  ],
                ],
              ),
            ),
          ),

          if (message.isUser) ...[
            const SizedBox(width: 8),
            // 用户头像
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: ClipOval(
                child:
                    _userAvatar.isNotEmpty
                        ? Image.asset(
                          _userAvatar,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.person,
                                color: Colors.grey,
                                size: 20,
                              ),
                            );
                          },
                        )
                        : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaContent(ChatMessage message) {
    if (message.mediaType == 'photo') {
      return GestureDetector(
        onTap: () => _showFullScreenImage(message.mediaPath!),
        child: Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              message.mediaPath!,
              width: 200,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
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
          ),
        ),
      );
    } else if (message.mediaType == 'video') {
      // 从视频路径推导出封面图片路径
      final String thumbnailPath = _getVideoThumbnail(message.mediaPath!);

      return GestureDetector(
        onTap: () => _showVideoPlayer(message.mediaPath!),
        child: Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 视频封面图
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  thumbnailPath,
                  width: 200,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // 如果封面图加载失败，显示默认的黑色背景
                    return Container(
                      width: 200,
                      height: 150,
                      color: Colors.black87,
                      child: const Center(
                        child: Icon(
                          Icons.videocam,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 半透明遮罩
              Container(
                width: 200,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
              // 播放按钮
              const Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 50,
              ),
              // VIDEO标签
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'VIDEO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showFullScreenImage(String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImagePage(imagePath: imagePath),
      ),
    );
  }

  String _getVideoThumbnail(String videoPath) {
    // 将视频路径转换为对应的封面图片路径
    // 例如: assets/figure/1/v/1_v_2025_06_24_1.mp4 -> assets/figure/1/p/1_p_2025_06_24_1.png
    try {
      // 分割路径获取各部分
      final parts = videoPath.split('/');
      if (parts.length >= 5) {
        final figureId = parts[2]; // 获取figure ID (例如: "1")
        final fileName = parts.last.split('.').first; // 获取文件名去除扩展名
        final photoFileName = fileName.replaceFirst('_v_', '_p_'); // 将v替换为p

        // 构建封面图片路径
        return 'assets/figure/$figureId/p/$photoFileName.png';
      }
    } catch (e) {
      debugPrint('Error generating thumbnail path: $e');
    }

    // 如果解析失败，返回默认图片路径
    return 'assets/images/userdefault_20250625.png';
  }

  void _showVideoPlayer(String videoPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _VideoPlayerPage(videoPath: videoPath),
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: ClipOval(
              child: Image.asset(
                widget.user['milyaUserIcon'],
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.person,
                      color: Colors.grey,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const SizedBox(
              width: 40,
              height: 20,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF9469),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _FullScreenImagePage extends StatelessWidget {
  final String imagePath;

  const _FullScreenImagePage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 全屏图片
          Center(
            child: InteractiveViewer(
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.error, color: Colors.white, size: 64),
                  );
                },
              ),
            ),
          ),

          // 关闭按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerPage extends StatefulWidget {
  final String videoPath;

  const _VideoPlayerPage({required this.videoPath});

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset(widget.videoPath);
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });

      // 自动播放视频
      _controller.play();

      // 监听播放状态
      _controller.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

      // 3秒后隐藏控制栏
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      debugPrint('Video initialization error: $e');
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // 视频播放器
            Center(
              child:
                  _hasError
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Unable to play video',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.videoPath.split('/').last,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                      : _isInitialized
                      ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                      : const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
            ),

            // 控制栏
            if (_showControls && _isInitialized && !_hasError)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    top: 40,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 进度条
                      VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Color(0xFF8B5CF6),
                          bufferedColor: Colors.grey,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 控制按钮和时间
                      Row(
                        children: [
                          // 播放/暂停按钮
                          GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _controller.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // 时间显示
                          Text(
                            '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          // 全屏按钮（暂时显示为装饰）
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // 关闭按钮
            if (_showControls)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? mediaPath;
  final String? mediaType; // 'photo' or 'video'

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.mediaPath,
    this.mediaType,
  });
}
