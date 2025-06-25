// views/chat_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/chat_controller.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatController _chatController = Get.find<ChatController>();
  bool _isSending = false;
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  Future<void> _initializeConversation() async {
    _conversationId =
        await _chatController.getOrCreateConversation(widget.receiverId);
    setState(() {});
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _conversationId == null) {
      return;
    }

    setState(() => _isSending = true);
    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      final success = await _chatController.sendMessage(
        conversationId: _conversationId!,
        content: message,
      );

      if (success) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        Get.snackbar('Error', 'Failed to send message');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message');
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16.r,
              backgroundImage: widget.receiverAvatar.isNotEmpty
                  ? NetworkImage(widget.receiverAvatar)
                  : null,
              child: widget.receiverAvatar.isEmpty
                  ? Text(
                      widget.receiverName.isNotEmpty
                          ? widget.receiverName[0].toUpperCase()
                          : '?',
                      style: TextStyle(fontSize: 14.sp),
                    )
                  : null,
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiverName,
                  style: TextStyle(fontSize: 16.sp),
                ),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.receiverId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final isOnline = snapshot.data?['isOnline'] ?? false;
                    final lastSeen = snapshot.data?['lastSeen'] as Timestamp?;
                    return Text(
                      isOnline
                          ? 'Online'
                          : 'Last seen ${_formatLastSeen(lastSeen?.toDate())}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isOnline ? Colors.green : Colors.grey,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Add additional options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _conversationId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('conversations')
                        .doc(_conversationId)
                        .collection('messages')
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'Start a conversation with ${widget.receiverName}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      final messages = snapshot.data!.docs;

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(
                            _scrollController.position.maxScrollExtent,
                          );
                        }
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16.w),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message =
                              messages[index].data() as Map<String, dynamic>;
                          final isMe = message['senderId'] ==
                              _chatController.currentUserId;
                          final timestamp =
                              (message['timestamp'] as Timestamp?)?.toDate();

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              margin: EdgeInsets.symmetric(vertical: 4.h),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Theme.of(context).primaryColor
                                    : isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(isMe ? 16.r : 4.r),
                                  topRight: Radius.circular(isMe ? 4.r : 16.r),
                                  bottomLeft: Radius.circular(16.r),
                                  bottomRight: Radius.circular(16.r),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['content'],
                                    style: TextStyle(
                                      color: isMe ? Colors.white : null,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    timestamp != null
                                        ? DateFormat('h:mm a').format(timestamp)
                                        : '',
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white70
                                          : isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'a long time ago';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 60) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }

    return DateFormat('MMM d').format(lastSeen);
  }
}
