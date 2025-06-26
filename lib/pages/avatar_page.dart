import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_detail_page.dart';
import '../utils/user_data.dart';

class AvatarPage extends StatefulWidget {
  const AvatarPage({super.key});

  @override
  State<AvatarPage> createState() => _AvatarPageState();
}

class _AvatarPageState extends State<AvatarPage> {
  late ScrollController _scrollController;
  double _appBarOpacity = 0.0;
  List<Map<String, dynamic>> _randomUsers = [];
  List<Map<String, dynamic>> _wearShareUsers = [];
  Set<String> _followedUsers = {}; // 存储已关注用户的名字
  Map<String, String> _userPostTimes = {}; // 存储每个用户的固定发布时间
  Set<String> _blockedUsers = {}; // 存储被拉黑/屏蔽的用户名字
  Map<String, List<Map<String, dynamic>>> _userComments = {}; // 存储每个用户朋友圈的评论

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadBlockedUsers();
    _loadRandomUsers();
    _loadWearShareUsers();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final maxOffset = 200.0; // 导航栏完全显示时的滚动距离

    setState(() {
      _appBarOpacity = (offset / maxOffset).clamp(0.0, 1.0);
    });
  }

  Future<void> _loadBlockedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blockedList = prefs.getStringList('blocked_users') ?? [];
      setState(() {
        _blockedUsers = blockedList.toSet();
      });
    } catch (e) {
      debugPrint('Error loading blocked users: $e');
    }
  }

  Future<void> _saveBlockedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('blocked_users', _blockedUsers.toList());
    } catch (e) {
      debugPrint('Error saving blocked users: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _generateCommentsForUser(
    String postAuthor,
    List<Map<String, dynamic>> allUsers,
  ) async {
    try {
      // 过滤掉发帖人自己和被拉黑的用户
      final availableUsers =
          allUsers.where((user) {
            final userName = user['milyaUserName'] ?? '';
            return userName != postAuthor && !_blockedUsers.contains(userName);
          }).toList();

      if (availableUsers.isEmpty) return [];

      final random = Random();
      final commentCount = 2 + random.nextInt(4); // 2-5条评论
      final List<Map<String, dynamic>> comments = [];

      // 珠宝相关的评论模板
      final List<String> commentTemplates = [
        'Beautiful jewelry! Where did you get it? 💎',
        'Love this style! 😍✨',
        'Amazing collection! So elegant 👑',
        'This piece is absolutely stunning! 💫',
        'Such exquisite craftsmanship! ✨',
        'The sparkle is incredible! 💎💎',
        'Perfect choice for your style! 👌',
        'This would go perfectly with my outfit! 💃',
        'The design is so unique! Love it! 🌟',
        'Where can I find similar pieces? 🛍️',
        'The color is perfect! 💕',
        'This is giving me major jewelry envy! 😍',
        'Such a timeless piece! Classic beauty 🌸',
        'The detailing is phenomenal! 🔍✨',
        'This screams luxury! Gorgeous! 👸',
      ];

      for (int i = 0; i < commentCount && i < availableUsers.length; i++) {
        final commenter = availableUsers[random.nextInt(availableUsers.length)];
        final commentText =
            commentTemplates[random.nextInt(commentTemplates.length)];

        // 生成随机时间（1小时到7天前）
        final hoursAgo = 1 + random.nextInt(168); // 1-168小时
        String timeAgo;
        if (hoursAgo < 24) {
          timeAgo = '${hoursAgo}h ago';
        } else {
          final daysAgo = hoursAgo ~/ 24;
          timeAgo = '${daysAgo}d ago';
        }

        comments.add({
          'avatarPath':
              commenter['milyaUserIcon'] ??
              'assets/images/userdefault_20250625.png',
          'userName': commenter['milyaUserName'] ?? '',
          'comment': commentText,
          'timeAgo': timeAgo,
          'isLiked': false,
          'likeCount': random.nextInt(20), // 0-19个赞
        });

        // 移除已选择的用户，避免重复
        availableUsers.remove(commenter);
      }

      return comments;
    } catch (e) {
      debugPrint('Error generating comments for user: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _generateRandomComments(
    String postAuthor,
  ) async {
    // 直接返回已生成的评论
    return _userComments[postAuthor] ?? [];
  }

  Future<void> _loadRandomUsers() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/data/figure_20250625.json');
      final List<dynamic> jsonArray = jsonDecode(jsonString);

      // 转换为Map并随机选择8个用户
      final List<Map<String, dynamic>> allUsers =
          jsonArray.cast<Map<String, dynamic>>().toList();

      final random = Random();
      final List<Map<String, dynamic>> selectedUsers = [];

      while (selectedUsers.length < 8 &&
          selectedUsers.length < allUsers.length) {
        final randomUser = allUsers[random.nextInt(allUsers.length)];
        final userName = randomUser['milyaUserName'] ?? '';

        // 检查用户是否已被选择或被拉黑/屏蔽
        if (!selectedUsers.any((user) => user['milyaUserName'] == userName) &&
            !_blockedUsers.contains(userName)) {
          selectedUsers.add(randomUser);
        }

        // 防止无限循环：如果剩余可用用户数不够，则跳出
        final availableUsers =
            allUsers
                .where(
                  (user) =>
                      !_blockedUsers.contains(user['milyaUserName'] ?? ''),
                )
                .length;
        if (availableUsers < 8 && selectedUsers.length >= availableUsers) {
          break;
        }
      }

      setState(() {
        _randomUsers = selectedUsers;
      });
    } catch (e) {
      debugPrint('Error loading random users: $e');
    }
  }

  void _navigateToUserDetail(Map<String, dynamic> user) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => UserDetailPage(user: user)));
  }

  Future<void> _loadWearShareUsers() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/data/figure_20250625.json');
      final List<dynamic> jsonArray = jsonDecode(jsonString);

      // 转换为Map并随机选择8个不同的用户（与_randomUsers不重复）
      final List<Map<String, dynamic>> allUsers =
          jsonArray.cast<Map<String, dynamic>>().toList();

      final random = Random();
      final List<Map<String, dynamic>> selectedUsers = [];

      while (selectedUsers.length < 8 &&
          selectedUsers.length < allUsers.length) {
        final randomUser = allUsers[random.nextInt(allUsers.length)];
        final userName = randomUser['milyaUserName'] ?? '';

        // 检查用户是否已被选择或被拉黑/屏蔽
        if (!selectedUsers.any((user) => user['milyaUserName'] == userName) &&
            !_blockedUsers.contains(userName)) {
          selectedUsers.add(randomUser);
        }

        // 防止无限循环：如果剩余可用用户数不够，则跳出
        final availableUsers =
            allUsers
                .where(
                  (user) =>
                      !_blockedUsers.contains(user['milyaUserName'] ?? ''),
                )
                .length;
        if (availableUsers < 8 && selectedUsers.length >= availableUsers) {
          break;
        }
      }

      // 为每个用户生成固定的发布时间和评论
      final Map<String, String> postTimes = {};
      final Map<String, List<Map<String, dynamic>>> userComments = {};

      for (var user in selectedUsers) {
        final userName = user['milyaUserName'] ?? '';
        if (userName.isNotEmpty) {
          postTimes[userName] = _generateRandomTime();
          // 为每个用户生成固定的评论列表
          userComments[userName] = await _generateCommentsForUser(
            userName,
            allUsers,
          );
        }
      }

      setState(() {
        _wearShareUsers = selectedUsers;
        _userPostTimes = postTimes;
        _userComments = userComments;
      });
    } catch (e) {
      debugPrint('Error loading wear share users: $e');
    }
  }

  void _toggleFollow(String userName) {
    setState(() {
      if (_followedUsers.contains(userName)) {
        _followedUsers.remove(userName);
      } else {
        _followedUsers.add(userName);
      }
    });
  }

  void _blockUser(String userName) {
    setState(() {
      _blockedUsers.add(userName);
      // 从关注列表中移除（如果有的话）
      _followedUsers.remove(userName);
      // 从Wear Share列表中移除被拉黑的用户
      _wearShareUsers.removeWhere((user) => user['milyaUserName'] == userName);
      // 移除该用户的时间记录和评论
      _userPostTimes.remove(userName);
      _userComments.remove(userName);

      // 重新生成剩余用户的评论（移除被拉黑用户的评论）
      _regenerateCommentsAfterBlock(userName);
    });

    // 保存拉黑用户列表到本地存储
    _saveBlockedUsers();

    // 重新加载Wear Share用户以补充新用户
    _loadWearShareUsers();
  }

  void _regenerateCommentsAfterBlock(String blockedUserName) {
    // 遍历所有用户的评论，移除被拉黑用户的评论
    _userComments.forEach((postAuthor, comments) {
      comments.removeWhere((comment) => comment['userName'] == blockedUserName);
    });
  }

  void _submitCommentReport(
    String commentUserName,
    String commentText,
    String reason,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Comment by $commentUserName has been reported for: $reason',
        ),
        backgroundColor: const Color(0xFF666666),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCommentActionSheet(
    String commentUserName,
    String commentText,
    VoidCallback refreshCallback,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                _buildActionSheetItem('Report', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => _CommentReportPage(
                            commentUserName: commentUserName,
                            commentText: commentText,
                          ),
                    ),
                  );
                }),
                _buildActionSheetItem('Block', () {
                  Navigator.pop(context);
                  _showCommentBlockConfirmDialog(
                    commentUserName,
                    commentText,
                    refreshCallback,
                  );
                }),
                const Divider(height: 1, color: Color(0xFFE5E5E5)),
                _buildActionSheetItem('Cancel', () {
                  Navigator.pop(context);
                }, isCancel: true),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCommentBlockConfirmDialog(
    String commentUserName,
    String commentText,
    VoidCallback refreshCallback,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Block $commentUserName?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          content: const Text(
            'You will no longer see comments from this user.',
            style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
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
                _blockCommentUser(commentUserName, refreshCallback);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$commentUserName has been blocked'),
                    backgroundColor: const Color(0xFF666666),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Block',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD32F2F),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _blockCommentUser(String commentUserName, VoidCallback refreshCallback) {
    setState(() {
      _blockedUsers.add(commentUserName);

      // 从所有用户的评论中移除被拉黑用户的评论
      _userComments.forEach((postAuthor, comments) {
        comments.removeWhere(
          (comment) => comment['userName'] == commentUserName,
        );
      });
    });

    // 保存拉黑用户列表
    _saveBlockedUsers();

    // 刷新评论弹窗
    refreshCallback();
  }

  Map<String, dynamic>? _findUserByName(String userName) {
    // 在所有用户列表中查找指定用户名的用户
    for (var user in [..._randomUsers, ..._wearShareUsers]) {
      if (user['milyaUserName'] == userName) {
        return user;
      }
    }
    return null;
  }

  void _showFullScreenImage(String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImagePage(imagePath: imagePath),
      ),
    );
  }

  void _showBlockConfirmDialog(
    BuildContext context,
    Map<String, dynamic> user,
    String action,
  ) {
    final userName = user['milyaUserName'] ?? '';
    final actionText = action == 'block' ? 'Block' : 'Mute';
    final actionDescription =
        action == 'block'
            ? 'You will no longer see any content from this user and they cannot interact with you.'
            : 'You will no longer see posts from this user in your feed.';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '$actionText $userName?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          content: Text(
            actionDescription,
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
                if (userName.isNotEmpty) {
                  _blockUser(userName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$userName has been ${action == 'block' ? 'blocked' : 'muted'}',
                      ),
                      backgroundColor: const Color(0xFF666666),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text(
                actionText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD32F2F), // 红色表示危险操作
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCommentBottomSheet(
    BuildContext context,
    Map<String, dynamic> user,
  ) {
    final userName = user['milyaUserName'] ?? '';
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // 顶部拖拽指示器和标题
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Comments',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE5E5E5)),

                  // 评论列表区域
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _generateRandomComments(userName),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFD8AC7B),
                            ),
                          );
                        }

                        List<Map<String, dynamic>> comments = [];
                        if (snapshot.hasData) {
                          comments = List.from(snapshot.data!);
                        }

                        // 如果没有评论，显示空状态
                        if (comments.isEmpty) {
                          return const Center(
                            child: Text(
                              'No comments yet\nBe the first to comment!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 16,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return FutureBuilder<String>(
                              future: UserData.getUserNickname(),
                              builder: (context, userSnapshot) {
                                final currentUserName = userSnapshot.data ?? '';
                                final isOwnComment =
                                    comment['userName'] == currentUserName;

                                return _buildCommentItem(
                                  avatarPath: comment['avatarPath'],
                                  userName: comment['userName'],
                                  comment: comment['comment'],
                                  timeAgo: comment['timeAgo'],
                                  isLiked: comment['isLiked'],
                                  likeCount: comment['likeCount'],
                                  isOwnComment: isOwnComment,
                                  userData: _findUserByName(
                                    comment['userName'],
                                  ),
                                  onLikeTap: () {
                                    setModalState(() {
                                      comment['isLiked'] = !comment['isLiked'];
                                      if (comment['isLiked']) {
                                        comment['likeCount']++;
                                      } else {
                                        comment['likeCount']--;
                                      }
                                    });
                                  },
                                  onReportTap:
                                      isOwnComment
                                          ? null
                                          : () {
                                            _showCommentActionSheet(
                                              comment['userName'],
                                              comment['comment'],
                                              () {
                                                setModalState(() {});
                                              },
                                            );
                                          },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE5E5E5)),

                  // 评论输入区域
                  Container(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                    ),
                    child: Row(
                      children: [
                        // 用户头像
                        FutureBuilder<String>(
                          future: UserData.getUserAvatar(),
                          builder: (context, snapshot) {
                            final avatarPath =
                                snapshot.data ??
                                'assets/images/userdefault_20250625.png';
                            return Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  avatarPath,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.grey,
                                        size: 18,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(width: 12),

                        // 输入框
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: commentController,
                              decoration: const InputDecoration(
                                hintText: 'Add a comment...',
                                hintStyle: TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // 发送按钮
                        GestureDetector(
                          onTap: () async {
                            if (commentController.text.trim().isNotEmpty) {
                              final commentText = commentController.text.trim();
                              final userNickname =
                                  await UserData.getUserNickname();
                              final userAvatar = await UserData.getUserAvatar();

                              // 创建新评论
                              final newComment = {
                                'avatarPath': userAvatar,
                                'userName': userNickname,
                                'comment': commentText,
                                'timeAgo': 'Just now',
                                'isLiked': false,
                                'likeCount': 0,
                              };

                              // 添加到当前用户的评论列表中
                              if (_userComments[userName] == null) {
                                _userComments[userName] = [];
                              }
                              _userComments[userName]!.insert(0, newComment);

                              commentController.clear();
                              setModalState(() {});

                              // 使用mounted检查来确保context仍然有效
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Comment posted!'),
                                    backgroundColor: Color(0xFF666666),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD8AC7B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentItem({
    required String avatarPath,
    required String userName,
    required String comment,
    required String timeAgo,
    required bool isLiked,
    required int likeCount,
    required bool isOwnComment,
    required VoidCallback onLikeTap,
    VoidCallback? onReportTap,
    Map<String, dynamic>? userData,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          GestureDetector(
            onTap:
                userData != null
                    ? () => _navigateToUserDetail(userData!)
                    : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  avatarPath,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
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
          ),

          const SizedBox(width: 12),

          // 评论内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap:
                          userData != null
                              ? () => _navigateToUserDetail(userData!)
                              : null,
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),

          // 点赞和举报按钮
          Row(
            children: [
              // 点赞按钮和数量
              GestureDetector(
                onTap: onLikeTap,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color:
                            isLiked
                                ? const Color(0xFFD8AC7B)
                                : const Color(0xFF999999),
                      ),
                      if (likeCount > 0)
                        Text(
                          likeCount.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isLiked
                                    ? const Color(0xFFD8AC7B)
                                    : const Color(0xFF999999),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 举报按钮（只对他人评论显示）
              if (!isOwnComment && onReportTap != null)
                GestureDetector(
                  onTap: onReportTap,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.flag_outlined,
                      size: 16,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showActionSheet(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                _buildActionSheetItem('Report', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _ReportPage(user: user),
                    ),
                  );
                }),
                _buildActionSheetItem('Block', () {
                  Navigator.pop(context);
                  _showBlockConfirmDialog(context, user, 'block');
                }),
                _buildActionSheetItem('Mute', () {
                  Navigator.pop(context);
                  _showBlockConfirmDialog(context, user, 'mute');
                }),
                const Divider(height: 1, color: Color(0xFFE5E5E5)),
                _buildActionSheetItem('Cancel', () {
                  Navigator.pop(context);
                }, isCancel: true),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionSheetItem(
    String title,
    VoidCallback onTap, {
    bool isCancel = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.normal,
            color: isCancel ? const Color(0xFF999999) : const Color(0xFF333333),
          ),
        ),
      ),
    );
  }

  String _generateRandomTime() {
    final random = Random();
    final now = DateTime.now();

    // 生成0-7天前的随机时间
    final daysAgo = random.nextInt(8);
    final hoursAgo = random.nextInt(24);
    final minutesAgo = random.nextInt(60);

    final postTime = now.subtract(
      Duration(days: daysAgo, hours: hoursAgo, minutes: minutesAgo),
    );

    if (daysAgo == 0) {
      if (hoursAgo == 0) {
        return minutesAgo == 0 ? 'Just now' : '${minutesAgo}m ago';
      } else {
        return '${hoursAgo}h ago';
      }
    } else if (daysAgo == 1) {
      return 'Yesterday';
    } else {
      return '${daysAgo}d ago';
    }
  }

  Widget _buildPhotoGrid(Map<String, dynamic> user) {
    final List<String> photoArray =
        user['milyaShowPhotoArray'] != null
            ? List<String>.from(user['milyaShowPhotoArray'])
            : [];

    if (photoArray.isEmpty) return const SizedBox.shrink();

    final double screenWidth = MediaQuery.of(context).size.width;
    final double imageSize = (screenWidth - 40 - 16) / 3.0;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            photoArray.take(9).map((imagePath) {
              return GestureDetector(
                onTap: () => _showFullScreenImage(imagePath),
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      imagePath,
                      width: imageSize,
                      height: imageSize,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 主要内容区域
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 顶部间距（状态栏 + 20px）
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + 20,
                ),
              ),

              // 顶部banner图片
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/img_avatar_banner_20250625.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Jewelry talent 标题
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(left: 20, top: 34),
                  child: const Text(
                    'Jewelry talent',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF160B00),
                    ),
                  ),
                ),
              ),

              // 角色水平滚动区域
              SliverToBoxAdapter(
                child: Container(
                  height: 90, // 60px头像 + 8px间距 + 22px文字高度
                  margin: const EdgeInsets.only(top: 20),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _randomUsers.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 16),
                        child: _buildUserItem(_randomUsers[index]),
                      );
                    },
                  ),
                ),
              ),

              // Wear Share 标题
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(left: 20, top: 34),
                  child: const Text(
                    'Wear Share',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF160B00),
                    ),
                  ),
                ),
              ),

              // Wear Share 用户列表
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index >= _wearShareUsers.length) return null;
                  return _buildWearShareItem(_wearShareUsers[index]);
                }, childCount: _wearShareUsers.length),
              ),

              // 底部间距
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // 渐显导航栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(_appBarOpacity),
                boxShadow:
                    _appBarOpacity > 0.5
                        ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ]
                        : null,
              ),
              child: SafeArea(
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: _appBarOpacity,
                    child: const Text(
                      'Share Jewelry',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
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

  Widget _buildUserItem(Map<String, dynamic> user) {
    return GestureDetector(
      onTap: () => _navigateToUserDetail(user),
      child: Column(
        children: [
          // 头像
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
            ),
            child: ClipOval(
              child: Image.asset(
                user['milyaUserIcon'] ?? '',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.person,
                      color: Colors.grey,
                      size: 30,
                    ),
                  );
                },
              ),
            ),
          ),

          // 用户名
          const SizedBox(height: 8),
          Text(
            user['milyaUserName'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWearShareItem(Map<String, dynamic> user) {
    final String userName = user['milyaUserName'] ?? '';
    final String shareText = user['milyaShareLive'] ?? '';
    final bool isFollowed = _followedUsers.contains(userName);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 头像
              GestureDetector(
                onTap: () => _navigateToUserDetail(user),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      user['milyaUserIcon'] ?? '',
                      width: 40,
                      height: 40,
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
              ),

              const SizedBox(width: 12),

              // 用户名
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToUserDetail(user),
                  child: Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF333333),
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),

              // 关注按钮
              GestureDetector(
                onTap: () => _toggleFollow(userName),
                child: Container(
                  width: 84,
                  height: 33,
                  decoration: BoxDecoration(
                    gradient:
                        isFollowed
                            ? null
                            : const LinearGradient(
                              colors: [Color(0xFFF7E2C7), Color(0xFFE5BD98)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                    color: isFollowed ? const Color(0xFFDADADA) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      isFollowed ? 'Unfollow' : 'Follow',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color:
                            isFollowed
                                ? const Color(0xFFFFFFFF)
                                : const Color(0xFF84441A),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 朋友圈文案
          if (shareText.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 0, right: 0, top: 8),
              child: Text(
                shareText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF333333),
                  height: 1.4,
                ),
              ),
            ),

          // 图片展示区域
          _buildPhotoGrid(user),

          // 时间和操作按钮区域
          _buildActionBar(user),
        ],
      ),
    );
  }

  Widget _buildActionBar(Map<String, dynamic> user) {
    final String userName = user['milyaUserName'] ?? '';
    final String postTime = _userPostTimes[userName] ?? 'Just now';

    return Container(
      width: MediaQuery.of(context).size.width,
      height: 16,
      margin: const EdgeInsets.only(top: 23),
      child: Row(
        children: [
          // 时间
          Container(
            margin: const EdgeInsets.only(left: 0),
            child: Text(
              postTime,
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
          ),

          const Spacer(),

          // 举报按钮
          GestureDetector(
            onTap: () => _showActionSheet(context, user),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Image.asset(
                'assets/images/btn_attention_nor_20250625.png',
                width: 16,
                height: 16,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.report,
                    size: 16,
                    color: Color(0xFF999999),
                  );
                },
              ),
            ),
          ),

          // 评论按钮
          GestureDetector(
            onTap: () {
              _showCommentBottomSheet(context, user);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 0),
              child: Image.asset(
                'assets/images/btn_chat_nor_20250625.png',
                width: 16,
                height: 16,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.comment,
                    size: 16,
                    color: Color(0xFF999999),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
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

class _ReportPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const _ReportPage({required this.user});

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<_ReportPage> {
  String _selectedReason = 'Pornographic or vulgar content';
  final TextEditingController _otherController = TextEditingController();

  final List<String> _reportReasons = [
    'Pornographic or vulgar content',
    'Politically sensitive content',
    'Deception and Fraud',
    'Harassment and Threats',
    'Insults and Obscenity',
    'Incorrect Information',
    'Privacy Violation',
    'Plagiarism or Copyright Infringement',
    'Other',
  ];

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 20,
          ),
        ),
        title: const Text(
          'Report',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reason for Report',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            // 举报原因列表
            Expanded(
              child: ListView.builder(
                itemCount: _reportReasons.length,
                itemBuilder: (context, index) {
                  final reason = _reportReasons[index];
                  final isSelected = _selectedReason == reason;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedReason = reason;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isSelected
                                      ? const Color(0xFFD8AC7B)
                                      : Colors.transparent,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? const Color(0xFFD8AC7B)
                                        : const Color(0xFFCCCCCC),
                                width: 2,
                              ),
                            ),
                            child:
                                isSelected
                                    ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Other Issue 输入框
            if (_selectedReason == 'Other') ...[
              const Text(
                'Other Issue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _otherController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Describe the issue',
                    hintStyle: TextStyle(color: Color(0xFF999999)),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Save 按钮
            Container(
              width: double.infinity,
              height: 50,
              margin: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                onPressed: () {
                  // 提交举报
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report submitted successfully'),
                      backgroundColor: Color(0xFFD8AC7B),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD8AC7B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentReportPage extends StatefulWidget {
  final String commentUserName;
  final String commentText;

  const _CommentReportPage({
    required this.commentUserName,
    required this.commentText,
  });

  @override
  _CommentReportPageState createState() => _CommentReportPageState();
}

class _CommentReportPageState extends State<_CommentReportPage> {
  String _selectedReason = 'Spam or misleading';
  final TextEditingController _otherController = TextEditingController();

  final List<String> _reportReasons = [
    'Spam or misleading',
    'Harassment or bullying',
    'Hate speech',
    'Inappropriate content',
    'Copyright violation',
    'False information',
    'Adult content',
    'Violent content',
    'Other',
  ];

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 20,
          ),
        ),
        title: const Text(
          'Report Comment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 显示被举报的评论信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User: ${widget.commentUserName}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.commentText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Reason for Report',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            // 举报原因列表
            Expanded(
              child: ListView.builder(
                itemCount: _reportReasons.length,
                itemBuilder: (context, index) {
                  final reason = _reportReasons[index];
                  final isSelected = _selectedReason == reason;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedReason = reason;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isSelected
                                      ? const Color(0xFFD8AC7B)
                                      : Colors.transparent,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? const Color(0xFFD8AC7B)
                                        : const Color(0xFFCCCCCC),
                                width: 2,
                              ),
                            ),
                            child:
                                isSelected
                                    ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Other Issue 输入框
            if (_selectedReason == 'Other') ...[
              const Text(
                'Other Issue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _otherController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Describe the issue with this comment',
                    hintStyle: TextStyle(color: Color(0xFF999999)),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Save 按钮
            Container(
              width: double.infinity,
              height: 50,
              margin: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                onPressed: () {
                  // 提交评论举报
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Comment by ${widget.commentUserName} has been reported',
                      ),
                      backgroundColor: const Color(0xFFD8AC7B),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD8AC7B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Submit Report',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
