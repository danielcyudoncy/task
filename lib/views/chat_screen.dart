// views/chat_screen.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:task/views/wallpaper_screen.dart';
import 'package:get/get.dart';
import '../widgets/chat_nav_bar.dart';
import '../controllers/wallpaper_controller.dart';
// Import the UserNavBar
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Helper function
bool isSameDay(Timestamp? a, Timestamp? b) {
  if (a == null || b == null) return false;
  final dateA = a.toDate();
  final dateB = b.toDate();
  return dateA.year == dateB.year &&
      dateA.month == dateB.month &&
      dateA.day == dateB.day;
}

// ChatScreen StatefulWidget
class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;
  final String? conversationId;
  final String? chatId;
  final String otherUserId;
  final String? otherUserName;
  final Map<String, dynamic> otherUser;
  final String? chatBackground;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAvatar,
    this.conversationId,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUser,
    required this.chatBackground,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// _ChatScreenState
class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String? conversationId;

  Map<String, dynamic>? _replyingToMessage;
  String? _editingMessageId;

  late final DatabaseReference _typingStatusRef;
  bool _isOtherUserTyping = false;
  Timer? _typingTimer;
  StreamSubscription? _typingSubscription;
  bool _shouldScrollToBottom = true;
  final WallpaperController _wallpaperController = Get.put(WallpaperController());

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    conversationId = widget.conversationId!;
    final rtdb = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://task-e5a96-default-rtdb.firebaseio.com', 
    );

   _typingStatusRef = rtdb.ref('typing_status/$conversationId');

    _typingSubscription =
        _typingStatusRef.child(widget.receiverId).onValue.listen((event) {
      final isTyping = event.snapshot.value as bool? ?? false;
      if (mounted) {
        setState(() {
          _isOtherUserTyping = isTyping;
        });
      }
    });

    _messageController.addListener(_onTyping);
    _scrollController.addListener(_onScroll);

    markMessagesAsSeen();
    
    // Schedule scroll to bottom after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTyping);
    _scrollController.removeListener(_onScroll);
    _typingTimer?.cancel();
    _typingSubscription?.cancel();
    _typingStatusRef.child(currentUserId).set(false);

    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _onTyping() {
    if (_typingTimer?.isActive ?? false) _typingTimer?.cancel();
    _typingStatusRef.child(currentUserId).set(true);
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      _typingStatusRef.child(currentUserId).set(false);
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      // If user scrolls up, disable auto-scroll
      if (position.pixels > position.minScrollExtent + 100) {
        _shouldScrollToBottom = false;
      }
    }
  }

  // void _navigateToHome() {
  //   // This schedules the navigation to happen *after* the current build cycle,
  //   // which prevents the "visitChildElements() called during build" error.
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     // Find the permanent AuthController instance.
  //     final AuthController authController = Get.find<AuthController>();
  //     final role = authController.userRole.value;

  //     const adminRoles = ["Admin", "Assignment Editor", "Head of Department"];

  //     // Navigate based on the role using the safest method.
  //     if (adminRoles.contains(role)) {
  //       Get.offAllNamed('/admin-dashboard');
  //     } else {
  //       // Defaults to user home for "Reporter", "Cameraman", or any other role.
  //       Get.offAllNamed('/home');
  //     }
  //   });
  // }



  void _startReply(Map<String, dynamic> messageData, String messageId) {
    setState(() {
      _editingMessageId = null;
      _replyingToMessage = {
        'messageId': messageId,
        'messageText': messageData['text'],
        'senderName': messageData['senderId'] == currentUserId
            ? "You".tr
            : widget.receiverName,
      };
    });
    _inputFocusNode.requestFocus();
  }

  void _startEdit(String messageId, String currentText) {
    setState(() {
      _replyingToMessage = null;
      _editingMessageId = messageId;
      _messageController.text = currentText;
    });
    _inputFocusNode.requestFocus();
  }

  void _cancelReplyOrEdit() {
    setState(() {
      _replyingToMessage = null;
      _editingMessageId = null;
      _messageController.clear();
    });
    _inputFocusNode.unfocus();
  }

  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_editingMessageId != null) {
      final messageRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(_editingMessageId!);
      await messageRef.update({'text': text, 'isEdited': true});
    } else {
      final timestamp = Timestamp.now();
      final messageRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();
      final conversationRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId);

      WriteBatch batch = FirebaseFirestore.instance.batch();

      batch.set(messageRef, {
        'senderId': currentUserId,
        'receiverId': widget.receiverId,
        'text': text,
        'timestamp': timestamp,
        'seenBy': [currentUserId],
        'reactions': {},
        'isEdited': false,
        'replyTo': _replyingToMessage,
      });

      batch.update(conversationRef, {
        'members': [currentUserId, widget.receiverId],
        'lastMessage': text,
        'timestamp': timestamp,
      });

      await batch.commit();
    }
    _cancelReplyOrEdit();
    _shouldScrollToBottom = true;
  }

  Future<void> markMessagesAsSeen() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('senderId', isEqualTo: widget.receiverId)
        .where('seenBy', whereNotIn: [currentUserId]).get();
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'seenBy': FieldValue.arrayUnion([currentUserId])
      });
    }
    await batch.commit();
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    final messageRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);
    FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(messageRef);
      if (!snapshot.exists) return;
      final messageData = snapshot.data()!;
      final reactions =
          Map<String, dynamic>.from(messageData['reactions'] ?? {});
      List<dynamic> userList = List.from(reactions[emoji] ?? []);
      if (userList.contains(currentUserId)) {
        userList.remove(currentUserId);
      } else {
        userList.add(currentUserId);
      }
      if (userList.isEmpty) {
        reactions.remove(emoji);
      } else {
        reactions[emoji] = userList;
      }
      transaction.update(messageRef, {'reactions': reactions});
    });
  }

  Future<void> deleteMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(_scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      _shouldScrollToBottom = false;
    }
  }

   

@override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDarkMode ? colorScheme.surface : colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color:
                  isDarkMode ? colorScheme.onSurface : colorScheme.onPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.home, color: isDarkMode ? colorScheme.onSurface : colorScheme.onPrimary),
            onPressed: () {
              Get.offNamed('/admin-dashboard');
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const WallpaperScreen()));
            },
          ),
        ],
        title: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => DraggableScrollableSheet(
                      initialChildSize: 0.55,
                      minChildSize: 0.4,
                      maxChildSize: 0.85,
                      expand: false,
                      builder: (context, scrollController) => SingleChildScrollView(
                        controller: scrollController,
                        child: UserDetailsSheet(user: widget.otherUser),
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode ? colorScheme.onPrimary : colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        backgroundImage: widget.receiverAvatar.isNotEmpty
                            ? NetworkImage(widget.receiverAvatar)
                            : null,
                        child: widget.receiverAvatar.isEmpty
                            ? Text(
                                widget.receiverName.isNotEmpty
                                    ? widget.receiverName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.receiverName,
                            style: textTheme.titleMedium?.copyWith(
                              color: isDarkMode ? colorScheme.onSurface : colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_isOtherUserTyping)
                            Text(
                              'typing'.tr,
                              style: textTheme.labelSmall?.copyWith(
                                color: (isDarkMode
                                        ? colorScheme.onSurface
                                        : colorScheme.onPrimary)
                                    .withAlpha((0.7 * 255).round()),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        titleSpacing: 0,
      ),

      body: Obx(() => Stack(
        children: [
          _ChatBackground(backgroundValue: _wallpaperController.wallpaper.value),
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('conversations')
                      .doc(conversationId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    // Scroll to bottom when new messages arrive
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty && _shouldScrollToBottom) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _scrollToBottom();
                        }
                      });
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                          child: CircularProgressIndicator(
                              color: colorScheme.secondary));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                          child: Text('say_hello'.tr,
                              style: TextStyle(
color: isDarkMode
                                      ? colorScheme.onSurface
                                      : colorScheme.onPrimary)));
                    }
                    return ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final messageDoc = snapshot.data!.docs[index];
                        final messageData =
                            messageDoc.data() as Map<String, dynamic>;
                        bool showDayDivider = false;
                        if (index < snapshot.data!.docs.length - 1) {
                          final prevMessageDoc = snapshot.data!.docs[index + 1];
                          final prevMessageData =
                              prevMessageDoc.data() as Map<String, dynamic>;
                          if (!isSameDay(messageData['timestamp'],
                              prevMessageData['timestamp'])) {
                            showDayDivider = true;
                          }
                        } else {
                          showDayDivider = true;
                        }
                        final bool isMe =
                            messageData['senderId'] == currentUserId;
                        return Dismissible(
                          key: Key(messageDoc.id),
                          direction: DismissDirection.startToEnd,
                          onDismissed: (direction) =>
                              _startReply(messageData, messageDoc.id),
                          background: Container(
                            color: colorScheme.secondary.withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.centerLeft,
                            child: const Icon(Icons.reply, color: Colors.white),
                          ),
                          child: Column(
                            children: [
                              if (showDayDivider)
                                _DateDivider(
                                    timestamp: messageData['timestamp']),
                              _MessageBubble(
                                messageId: messageDoc.id,
                                messageData: messageData,
                                isMe: isMe,
                                onDelete: () => deleteMessage(messageDoc.id),
                                onToggleReaction: (emoji) =>
                                    toggleReaction(messageDoc.id, emoji),
                                onStartEdit: () => _startEdit(
                                    messageDoc.id, messageData['text']),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_replyingToMessage != null)
                _ReplyPreview(
                    messageData: _replyingToMessage!,
                    onCancel: _cancelReplyOrEdit),
              if (_editingMessageId != null)
                _EditPreview(onCancel: _cancelReplyOrEdit),
              _MessageInputField(
                controller: _messageController,
                focusNode: _inputFocusNode,
                onSend: sendMessage,
              ),
            ],
          ),
        ],
      )),
      bottomNavigationBar: const ChatNavBar(currentIndex: 0),
    );
  }

}


class _ChatBackground extends StatelessWidget {
  final String backgroundValue;
  const _ChatBackground({required this.backgroundValue});

  Color _colorFromHex(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    BoxDecoration decoration;
    if (backgroundValue.startsWith('asset:')) {
      final path = backgroundValue.substring(6);
      decoration = BoxDecoration(
        image: DecorationImage(
          image: AssetImage(path),
          fit: BoxFit.cover,
        ),
      );
    } else if (backgroundValue.startsWith('#')) {
      decoration = BoxDecoration(color: _colorFromHex(backgroundValue));
    } else {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final colorScheme = Theme.of(context).colorScheme;
      decoration = BoxDecoration(
        color: isDarkMode ? colorScheme.surface : colorScheme.primary,
      );
    }
    return Container(decoration: decoration);
  }
}

class _MessageBubble extends StatelessWidget {
  final String messageId;
  final Map<String, dynamic> messageData;
  final bool isMe;
  final VoidCallback onDelete;
  final Function(String) onToggleReaction;
  final VoidCallback onStartEdit;

  const _MessageBubble({
    required this.messageId,
    required this.messageData,
    required this.isMe,
    required this.onDelete,
    required this.onToggleReaction,
    required this.onStartEdit,
  });

  @override
  Widget build(BuildContext context) {
    final text = messageData['text'] ?? '';
    final time = (messageData['timestamp'] as Timestamp?)?.toDate();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe
              ? colorScheme.secondary
              : (isDark ? colorScheme.surfaceContainerHighest : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.04 * 255).round()),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : colorScheme.onSurface,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (time != null)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  DateFormat('h:mm a').format(time),
                  style: TextStyle(
                    color: isMe ? Colors.white.withAlpha((0.7 * 255).round()) : Colors.grey,
                    fontSize: 11.sp,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final Timestamp? timestamp;
  const _DateDivider({required this.timestamp});

  @override
  Widget build(BuildContext context) {
    if (timestamp == null) return const SizedBox.shrink();
    final date = timestamp!.toDate();
    final now = DateTime.now();
    String label;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      label = 'Today'.tr;
    } else {
      label = DateFormat('d MMM yyyy').format(date);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              label,
              style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[400] 
                    : Colors.grey[700], 
                  fontWeight: FontWeight.w600
                ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const _MessageInputField({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 16.h),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(28),
color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,

        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'type_here_your_message'.tr,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send_rounded, color: colorScheme.primary),
              onPressed: onSend,
              splashRadius: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  final Map<String, dynamic> messageData;
  final VoidCallback onCancel;

  const _ReplyPreview({required this.messageData, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha((0.2 * 255).round())),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4.w, color: colorScheme.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(messageData['senderName'],
                      style: TextStyle(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(messageData['messageText'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: colorScheme.onSurface.withAlpha((0.8 * 255).round()))),
                ],
              ),
            ),
            IconButton(
                icon: Icon(Icons.close,
                    color: colorScheme.onSurface.withAlpha((0.6 * 255).round())),
                onPressed: onCancel),
          ],
        ),
      ),
    );
  }
}

class _EditPreview extends StatelessWidget {
  final VoidCallback onCancel;
  const _EditPreview({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha((0.2 * 255).round())),
      child: Row(
        children: [
          Icon(Icons.edit, color: colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
              child: Text("Editing Message".tr,
                  style: TextStyle(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.bold))),
          IconButton(
              icon: Icon(Icons.close,
                  color: colorScheme.onSurface.withAlpha((0.6 * 255).round())),
              onPressed: onCancel),
        ],
      ),
    );
  }
}

class UserDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> user;
  const UserDetailsSheet({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatar = user['photoUrl'] ?? '';
    final name = user['fullName'] ?? 'Unknown';
    final phone = user['phoneNumber'] ?? 'Not set';
    final email = user['email'] ?? 'Not set';
    final role = user['role'] ?? '';
    final about = user['about'] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? colorScheme.onPrimary : colorScheme.primary,
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 48.w,
              backgroundColor: Colors.white,
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty
                  ? Icon(Icons.person, size: 48.sp, color: colorScheme.primary)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          if (role.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(role, style: textTheme.bodyMedium?.copyWith(color: colorScheme.secondary)),
          ],
          const SizedBox(height: 16),
          if (about.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.info_outline, color: colorScheme.secondary, size: 20.sp),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(about, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Icon(Icons.phone, color: colorScheme.secondary, size: 20.sp),
              const SizedBox(width: 8),
              Expanded(
                child: Text(phone, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.email, color: colorScheme.secondary, size: 20.sp),
              const SizedBox(width: 8),
              Expanded(
                child: Text(email, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
                shadowColor: Colors.black26,
              ),
              icon: const Icon(Icons.message, color: Colors.white),
              label: Text("Message".tr, style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary
              )),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
