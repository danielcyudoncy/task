// views/chat_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

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
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// _ChatScreenState
class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String? conversationId;

  // Timer for typing indicator
  Timer? _typingTimer;

  // Edit/Reply State
  Map<String, dynamic>? _replyingToMessage;
  String? _editingMessageId;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    conversationId = widget.conversationId!;
    markMessagesAsSeen();
    _messageController.addListener(_onTyping);
  }

  @override
  void dispose() {
    _updateTypingStatus(false);
    _typingTimer?.cancel();
    _messageController.removeListener(_onTyping);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTyping() {
    if (_typingTimer?.isActive ?? false) _typingTimer!.cancel();
    _updateTypingStatus(true);
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      _updateTypingStatus(false);
    });
  }

  Future<void> _updateTypingStatus(bool isTyping) async {
    if (conversationId == null) return;
    try {
      // Use set with merge:true to create the field if it doesn't exist.
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .set({
        'typingStatus': {currentUserId: isTyping}
      }, SetOptions(merge: true));
    } catch (e) {
      // It's okay if this fails occasionally, e.g., on first message.
    }
  }

  void _startReplying(String messageId, String messageText, String senderName) {
    setState(() {
      _editingMessageId = null;
      _replyingToMessage = {
        'messageId': messageId,
        'messageText': messageText,
        'senderName': senderName,
      };
      FocusScope.of(context).requestFocus();
    });
  }

  void _startEditing(String messageId, String currentText) {
    setState(() {
      _replyingToMessage = null;
      _editingMessageId = messageId;
      _messageController.text = currentText;
      FocusScope.of(context).requestFocus();
    });
  }

  void _cancelReplyOrEdit() {
    setState(() {
      _replyingToMessage = null;
      _editingMessageId = null;
      _messageController.clear();
      FocusScope.of(context).unfocus();
    });
  }

  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Stop the typing indicator immediately
    _typingTimer?.cancel();
    _updateTypingStatus(false);

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

      batch.set(
          conversationRef,
          {
            'participants': [currentUserId, widget.receiverId],
            'lastMessage':
                _replyingToMessage != null ? 'Replying: $text' : text,
            'lastMessageTime': timestamp,
          },
          SetOptions(merge: true));

      await batch.commit();
    }

    _cancelReplyOrEdit();
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final appBarTitle = StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .snapshots(),
      builder: (context, snapshot) {
        bool isReceiverTyping = false;
        if (snapshot.hasData && snapshot.data?.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          if (data['typingStatus'] != null) {
            isReceiverTyping = data['typingStatus'][widget.receiverId] ?? false;
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.receiverName,
              style: textTheme.titleLarge?.copyWith(
                color: isDarkMode
                    ? colorScheme.onBackground
                    : colorScheme.onPrimary,
                fontSize: 18.sp,
              ),
            ),
            if (isReceiverTyping)
              Text(
                'typing...',
                style: textTheme.bodySmall?.copyWith(
                  color: (isDarkMode
                          ? colorScheme.onBackground
                          : colorScheme.onPrimary)
                      .withOpacity(0.7),
                ),
              ),
          ],
        );
      },
    );

    return Scaffold(
      backgroundColor:
          isDarkMode ? colorScheme.background : colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.receiverAvatar.isNotEmpty
                  ? NetworkImage(widget.receiverAvatar)
                  : null,
              backgroundColor: colorScheme.secondary.withOpacity(0.8),
              child: widget.receiverAvatar.isEmpty
                  ? Text(
                      widget.receiverName.isNotEmpty
                          ? widget.receiverName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 10.w),
            appBarTitle,
          ],
        ),
      ),
      body: Column(
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Say Hello!"));
                }

                final messages = snapshot.data!.docs;

                int lastSeenByOtherUserIndex = -1;
                for (int i = 0; i < messages.length; i++) {
                  final messageData =
                      messages[i].data() as Map<String, dynamic>;
                  final seenBy = List<String>.from(messageData['seenBy'] ?? []);
                  if (messageData['senderId'] == currentUserId &&
                      seenBy.contains(widget.receiverId)) {
                    lastSeenByOtherUserIndex = i;
                    break;
                  }
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final messageData =
                        messageDoc.data() as Map<String, dynamic>;

                    bool showDayDivider = false;
                    if (index < messages.length - 1) {
                      final prevMessageData =
                          messages[index + 1].data() as Map<String, dynamic>;
                      if (!isSameDay(messageData['timestamp'],
                          prevMessageData['timestamp'])) {
                        showDayDivider = true;
                      }
                    } else {
                      showDayDivider = true;
                    }

                    final bool isMe = messageData['senderId'] == currentUserId;
                    final bool showSeenStatus =
                        isMe && index == lastSeenByOtherUserIndex;

                    return Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (showDayDivider)
                          _DateDivider(timestamp: messageData['timestamp']),
                        Dismissible(
                          key: Key(messageDoc.id),
                          direction: DismissDirection.startToEnd,
                          onDismissed: (direction) {
                            // We determine the correct name based on who sent the message
                            final String senderName =
                                isMe ? "You" : widget.receiverName;
                            // We now correctly pass this 'senderName' variable to the function
                            _startReplying(
                                messageDoc.id, messageData['text'], senderName);
                          },
                          background: Container(
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.7),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20.0),
                            child: const Icon(Icons.reply_rounded,
                                color: Colors.white),
                          ),
                          child: _MessageBubble(
                            messageId: messageDoc.id,
                            messageData: messageData,
                            isMe: isMe,
                            onDelete: () => deleteMessage(messageDoc.id),
                            onToggleReaction: (emoji) =>
                                toggleReaction(messageDoc.id, emoji),
                            onStartEditing: () => _startEditing(
                                messageDoc.id, messageData['text']),
                          ),
                        ),
                        if (showSeenStatus)
                          Padding(
                            padding:
                                const EdgeInsets.only(right: 8.0, top: 2.0),
                            child: Text(
                              'Seen',
                              style: textTheme.labelSmall?.copyWith(
                                color: (isDarkMode
                                        ? colorScheme.onBackground
                                        : colorScheme.onPrimary)
                                    .withOpacity(0.7),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (_replyingToMessage != null)
            _ReplyPreview(
              messageData: _replyingToMessage!,
              onCancel: _cancelReplyOrEdit,
            ),
          if (_editingMessageId != null)
            _EditPreview(onCancel: _cancelReplyOrEdit),
          _MessageInputField(
            controller: _messageController,
            onSend: sendMessage,
          ),
        ],
      ),
    );
  }
}

// === ALL WIDGET DEFINITIONS BELOW ===

class _ReplyPreview extends StatelessWidget {
  final Map<String, dynamic> messageData;
  final VoidCallback onCancel;

  const _ReplyPreview({required this.messageData, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${messageData['senderName']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Text(
                  messageData['messageText'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _EditPreview extends StatelessWidget {
  final VoidCallback onCancel;

  const _EditPreview({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
      child: Row(
        children: [
          Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Editing Message',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String messageId;
  final Map<String, dynamic> messageData;
  final bool isMe;
  final VoidCallback onDelete;
  final Function(String) onToggleReaction;
  final VoidCallback onStartEditing;

  const _MessageBubble({
    required this.messageId,
    required this.messageData,
    required this.isMe,
    required this.onDelete,
    required this.onToggleReaction,
    required this.onStartEditing,
  });

  void _showActionMenu(BuildContext context) {
    HapticFeedback.vibrate();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.copy_rounded,
                  color: Theme.of(context).colorScheme.onSurface),
              title: const Text('Copy Text'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: messageData['text']));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            if (isMe)
              ListTile(
                leading: Icon(Icons.edit_note_rounded,
                    color: Theme.of(context).colorScheme.onSurface),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.of(context).pop();
                  onStartEditing();
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

    final Color bubbleColor;
    final Color textColor;

    if (isMe) {
      bubbleColor = colorScheme.secondary;
      textColor = colorScheme.onSecondary;
    } else {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      if (isDarkMode) {
        bubbleColor = colorScheme.surface;
        textColor = colorScheme.onSurface;
      } else {
        bubbleColor = colorScheme.surfaceVariant;
        textColor = colorScheme.onSurfaceVariant;
      }
    }

    final reactions = Map<String, dynamic>.from(messageData['reactions'] ?? {});
    final hasReactions = reactions.isNotEmpty;
    final replyInfo = messageData['replyTo'] as Map<String, dynamic>?;
    final isEdited = messageData['isEdited'] ?? false;

    final bubbleContent = Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Text(
          messageData['text'],
          style: textTheme.bodyMedium?.copyWith(color: textColor),
        ),
        const SizedBox(width: 8.0),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isEdited)
                Text(
                  'Edited · ',
                  style: textTheme.labelSmall
                      ?.copyWith(color: textColor.withOpacity(0.7)),
                ),
              Text(
                DateFormat('h:mm a').format(messageData['timestamp']!.toDate()),
                style: textTheme.labelSmall
                    ?.copyWith(color: textColor.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ],
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showActionMenu(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
              margin: EdgeInsets.only(
                top: 4.0,
                bottom: hasReactions ? 12.0 : 4.0,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (replyInfo != null)
                    _RepliedMessageDisplay(
                        replyInfo: replyInfo, textColor: textColor),
                  bubbleContent,
                ],
              ),
            ),
            if (hasReactions)
              Positioned(
                bottom: 0,
                right: isMe ? 0 : null,
                left: isMe ? null : 0,
                child: _ReactionsDisplay(reactions: reactions),
              ),
          ],
        ),
      ),
    );
  }
}

class _RepliedMessageDisplay extends StatelessWidget {
  final Map<String, dynamic> replyInfo;
  final Color textColor;

  const _RepliedMessageDisplay(
      {required this.replyInfo, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 4.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyInfo['senderName'] ?? 'Someone',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 12,
            ),
          ),
          Text(
            replyInfo['messageText'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor.withOpacity(0.8),
              fontSize: 12,
            ),
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
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: sortedReactions.map((entry) {
          final count = (entry.value as List).length;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Text(
              '${entry.key}${count > 1 ? ' $count' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInputField({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      color: isDarkMode
          ? colorScheme.surface
          : colorScheme.surfaceVariant.withOpacity(0.1),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(color: colorScheme.onSurface),
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  fillColor: isDarkMode
                      ? colorScheme.surface
                      : colorScheme.surfaceVariant,
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
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dateText,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.8),
            ),
      ),
    );
  }
}
