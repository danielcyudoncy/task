// views/chat_screen.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:task/views/wallpaper_screen.dart';
import 'package:get/get.dart';
// Import the UserNavBar

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
            ? "You"
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
            CircleAvatar(
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.receiverName,
                    style: textTheme.titleMedium?.copyWith(
                      color:
                          isDarkMode ? colorScheme.onSurface : colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isOtherUserTyping)
                    Text(
                      'typing...',
                      style: textTheme.labelSmall?.copyWith(
                        color: (isDarkMode
                                ? colorScheme.onSurface
                                : colorScheme.onPrimary)
                            .withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        titleSpacing: 0,
      ),

      body: Stack(
        children: [
          _ChatBackground(backgroundValue: widget.chatBackground ?? ''),
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
                          child: Text('Say hello!',
                              style: TextStyle(
                                  color: isDarkMode
                                      ? colorScheme.onBackground
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
                            color: colorScheme.secondary.withOpacity(0.5),
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
      ),
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

  void _showActionMenu(BuildContext context) {
    HapticFeedback.vibrate();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['👍', '❤️', '😂', '😮', '😢', '🙏'].map((emoji) {
                  return InkWell(
                    onTap: () {
                      onToggleReaction(emoji);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 28))),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            if (isMe)
              ListTile(
                leading: Icon(Icons.edit_rounded,
                    color: Theme.of(context).colorScheme.onSurface),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.of(context).pop();
                  onStartEdit();
                },
              ),
            ListTile(
              leading: Icon(Icons.copy_rounded,
                  color: Theme.of(context).colorScheme.onSurface),
              title: const Text('Copy Text'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: messageData['text']));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')));
              },
            ),
            if (isMe)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.error),
                title: Text('Delete',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () {
                  onDelete();
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final Color bubbleColor;
    final Color textColor;
    if (isMe) {
      bubbleColor = colorScheme.secondary;
      textColor = colorScheme.onSecondary;
    } else {
      if (isDarkMode) {
        bubbleColor = colorScheme.surface;
        textColor = colorScheme.onSurface;
      } else {
        bubbleColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
      }
    }

    final reactions = Map<String, dynamic>.from(messageData['reactions'] ?? {});
    final hasReactions = reactions.isNotEmpty;
    final bool isEdited = messageData['isEdited'] ?? false;
    final replyData = messageData['replyTo'] as Map<String, dynamic>?;

    return GestureDetector(
      onLongPress: () => _showActionMenu(context),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: bubbleColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (replyData != null)
                      _RepliedMessageDisplay(replyData: replyData, isMe: isMe),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(messageData['text'],
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: textColor)),
                          const SizedBox(height: 4.0),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isEdited)
                                Text(
                                  'edited',
                                  style: textTheme.labelSmall?.copyWith(
                                      color: textColor.withOpacity(0.7),
                                      fontStyle: FontStyle.italic),
                                ),
                              const SizedBox(width: 4),
                              if (messageData['timestamp'] != null)
                                Text(
                                  DateFormat('h:mm a').format(
                                      messageData['timestamp']!.toDate()),
                                  style: textTheme.labelSmall?.copyWith(
                                      color: textColor.withOpacity(0.7)),
                                ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasReactions)
            Transform.translate(
              offset: Offset(isMe ? 0 : 10, -14),
              child: _ReactionsDisplay(reactions: reactions),
            ),
        ],
      ),
    );
  }
}

class _ReactionsDisplay extends StatelessWidget {
  final Map<String, dynamic> reactions;
  const _ReactionsDisplay({required this.reactions});

  @override
  Widget build(BuildContext context) {
    final sortedReactions = reactions.entries.toList()
      ..sort((a, b) =>
          (b.value as List).length.compareTo((a.value as List).length));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: sortedReactions.map((entry) {
          final count = (entry.value as List).length;
          return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text('${entry.key}${count > 1 ? ' $count' : ''}',
                  style: const TextStyle(fontSize: 12)));
        }).toList(),
      ),
    );
  }
}

class _MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final FocusNode focusNode;

  const _MessageInputField(
      {required this.controller,
      required this.onSend,
      required this.focusNode});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      color: isDarkMode
          ? colorScheme.surface
          : colorScheme.surfaceContainerHighest.withOpacity(0.1),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(color: colorScheme.onSurface),
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  fillColor: isDarkMode
                      ? colorScheme.surface
                      : colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            IconButton(
              icon: Icon(Icons.send_rounded, color: colorScheme.secondary),
              onPressed: onSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final Timestamp? timestamp;
  const _DateDivider({this.timestamp});

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (timestamp == null) return const SizedBox.shrink();
    final dateText = _getFormattedDate(timestamp!.toDate());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.5),
          borderRadius: BorderRadius.circular(12)),
      child: Text(dateText,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.8))),
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
          color: colorScheme.surfaceContainerHighest.withOpacity(0.2)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: colorScheme.secondary),
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
                          color: colorScheme.onSurface.withOpacity(0.8))),
                ],
              ),
            ),
            IconButton(
                icon: Icon(Icons.close,
                    color: colorScheme.onSurface.withOpacity(0.6)),
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
          color: colorScheme.surfaceContainerHighest.withOpacity(0.2)),
      child: Row(
        children: [
          Icon(Icons.edit, color: colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
              child: Text("Editing Message",
                  style: TextStyle(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.bold))),
          IconButton(
              icon: Icon(Icons.close,
                  color: colorScheme.onSurface.withOpacity(0.6)),
              onPressed: onCancel),
        ],
      ),
    );
  }
}

class _RepliedMessageDisplay extends StatelessWidget {
  final Map<String, dynamic> replyData;
  final bool isMe;

  const _RepliedMessageDisplay({required this.replyData, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final replyTextColor = isDarkMode ? Colors.white70 : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 2, left: 1, right: 1),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        border: Border(
          left: BorderSide(
            color: colorScheme.secondary,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyData['senderName'],
            style: TextStyle(
                color: colorScheme.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            replyData['messageText'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                TextStyle(color: replyTextColor.withOpacity(0.8), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
