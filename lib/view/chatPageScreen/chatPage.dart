import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _record = AudioRecorder();
  Map<String, dynamic>? _replyingTo;
  // Quản lý trạng thái expand của mỗi tin nhắn
  final Set<String> _expandedMessageIds = {};

  @override
  void initState() {
    super.initState();
    _setUserOnline();
    _markAllMessagesAsSeen();
  }

  @override
  void dispose() {
    _setUserOffline();
    _record.dispose();
    super.dispose();
  }

  void _setUserOnline() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.phoneNumber)
          .update({'isOnline': true});
    }
  }

  void _setUserOffline() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.phoneNumber)
          .update({
        'isOnline': false,
        'lastActive': FieldValue.serverTimestamp(),
      });
    }
  }
Widget _buildSeenByNames(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final seenByList = (data['seenBy'] as List<dynamic>?)?.cast<String>() ?? [];

    // Nếu không ai xem thì không hiển thị
    if (seenByList.isEmpty) return const SizedBox();

    // Xác định xem mình có phải người gửi không
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = data['senderId'] == currentUid;

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: seenByList)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData) {
          return const SizedBox();
        }

        // Lấy danh sách tên
        final names = snapshot.data!.docs.map((uDoc) {
          final u = uDoc.data() as Map<String, dynamic>;
          return u['fullName'] ?? 'Ẩn danh';
        }).toList();
        final namesText = names.join(', ');

        // Tính padding & alignment tùy isMe
        final pad = isMe
            ? const EdgeInsets.only(top: 4, right: 12)
            : const EdgeInsets.only(top: 4, left: 12);
        final align = isMe ? Alignment.centerRight : Alignment.centerLeft;

        return Padding(
          padding: pad,
          child: Align(
            alignment: align,
            child: Text(
              'Đã xem: $namesText',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
        );
      },
    );
  }



  void _markMessageAsSeen(DocumentSnapshot doc) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final phone = user.phoneNumber;
    final data = doc.data() as Map<String, dynamic>;
    final List seenBy = data['seenBy'] ?? [];

    if (!seenBy.contains(phone)) {
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(doc.id)
          .update({
        'seenBy': FieldValue.arrayUnion([phone]),
      });
    }
  }

  Future<void> _markAllMessagesAsSeen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final phone = user.phoneNumber;
    if (phone == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('messages')
        .where('senderId', isNotEqualTo: user.uid)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final seenBy = List<String>.from(data['seenBy'] ?? []);
      if (!seenBy.contains(phone)) {
        batch.update(doc.reference, {
          'seenBy': FieldValue.arrayUnion([phone]),
        });
      }
    }
    await batch.commit();
  }

  Widget _buildSeenByAvatars(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final seenByList = data['seenBy'] as List<dynamic>?;

    if (seenByList == null || seenByList.isEmpty) return const SizedBox();

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: List<String>.from(seenByList))
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final users = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.only(top: 4, left: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: users.map((userDoc) {
              final u = userDoc.data() as Map<String, dynamic>;
              final avatarUrl = u['avatarUrl'];
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: CircleAvatar(
                  radius: 10,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person, size: 12)
                      : null,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _sendMessage({
    required String type,
    String? text,
    String? mediaUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.phoneNumber)
        .get();
    final data = doc.data() ?? {};
    final name = data['fullName'] ?? 'Ẩn danh';
    final room = data['roomNo'] ?? '';
    final avatar = data['avatarUrl'];
    final nickname =
        room.toString().isNotEmpty ? '$name - phòng trọ số $room' : name;

    await FirebaseFirestore.instance.collection('messages').add({
      'senderId': user.uid,
      'senderName': nickname,
      'senderPhone': user.phoneNumber,
      'avatarUrl': avatar,
      'type': type,
      'text': text ?? '',
      'mediaUrl': mediaUrl ?? '',
      'replyTo': _replyingTo != null
          ? {
              'senderName': _replyingTo!['senderName'],
              'text': _replyingTo!['text'],
            }
          : null,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Gửi thông báo FCM nếu người nhận offline
    final users = await FirebaseFirestore.instance
        .collection('users')
        .where('isOnline', isEqualTo: false)
        .get();

    for (var user in users.docs) {
      final userData = user.data();
      final fcmToken = userData['fcmToken'];
      if (fcmToken != null) {
        _sendPushNotification(
          fcmToken,
          'Bạn có tin nhắn mới từ chat!',
        );
      }
    }

    setState(() {
      _replyingTo = null;
    });
  }

  Future<void> _sendPushNotification(String fcmToken, String message) async {
    final url = Uri.parse('https://pushnoti-8jr2.onrender.com/sendMessageNoti');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'senderPhone':
          FirebaseAuth.instance.currentUser?.phoneNumber ?? 'Unknown',
      'receiverPhone': 'receiver_phone_number',
      'message': message,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        log('Notification sent successfully');
      } else {
        log('Error sending notification: ${response.statusCode}');
      }
    } catch (e) {
      log('Error while sending notification: $e');
    }
  }

  void sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;
    await _sendMessage(type: 'text', text: text.trim());
    _controller.clear();
    _scrollToBottom();
  }

  Future<void> sendImageMessage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final ref = FirebaseStorage.instance.ref().child(
            'chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      await _sendMessage(type: 'image', mediaUrl: url);
    }
  }

  Future<void> startOrStopRecording() async {
    if (await _record.isRecording()) {
      final path = await _record.stop();
      if (path != null) {
        final ref = FirebaseStorage.instance.ref().child(
              'chat_audio/${DateTime.now().millisecondsSinceEpoch}.m4a',
            );
        await ref.putFile(File(path));
        final url = await ref.getDownloadURL();
        await _sendMessage(type: 'voice', mediaUrl: url);
      }
    } else {
      final micStatus = await Permission.microphone.request();
      if (micStatus.isGranted) {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _record.start(const RecordConfig(), path: path);
      }
    }
  }

 
  Widget _buildMessageItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isMe = data['senderId'] == FirebaseAuth.instance.currentUser?.uid;
    final type = data['type'] ?? 'text';
    final avatarUrl = data['avatarUrl'];
    final replyTo = data['replyTo'];
    final senderPhone = data['senderPhone'] ?? '';

    final timestamp = data['timestamp'] as Timestamp?;
    final String timeString = timestamp != null
        ? TimeOfDay.fromDateTime(timestamp.toDate()).format(context)
        : '';

    Widget content;
    if (type == 'image') {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(data['mediaUrl'], width: 180),
      );
    } else if (type == 'voice') {
      content = const Icon(Icons.play_arrow);
    } else {
      content = Text(
        data['text'] ?? '',
        style: TextStyle(color: isMe ? Colors.white : Colors.black),
      );
    }

    return GestureDetector(
      onLongPress: () {
        final docId = doc.id;
        final rawData = doc.data();
        if (rawData == null) return;
        final data = Map<String, dynamic>.from(rawData as Map);
        final isMe = data['senderId'] == FirebaseAuth.instance.currentUser?.uid;
        final isDeleted = data['type'] == 'deleted';
        if (isDeleted) return;

        showModalBottomSheet(
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((data['text'] ?? '').toString().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Sao chép'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: data['text']));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép')),
                    );
                  },
                ),
              if ((data['text'] ?? '').toString().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.reply),
                  title: const Text('Trả lời'),
                  onTap: () {
                    setState(() => _replyingTo = data);
                    Navigator.pop(context);
                  },
                ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: Text(
                    isDeleted ? 'Xóa vĩnh viễn' : 'Thu hồi tin nhắn',
                  ),
                  onTap: () async {
                    if (isDeleted) {
                      await FirebaseFirestore.instance
                          .collection('messages')
                          .doc(docId)
                          .delete();
                    } else {
                      await FirebaseFirestore.instance
                          .collection('messages')
                          .doc(docId)
                          .update({
                        'type': 'deleted',
                        'text': '[Tin nhắn đã bị thu hồi]',
                        'mediaUrl': '',
                      });
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isDeleted
                            ? 'Đã xóa tin nhắn khỏi cuộc trò chuyện'
                            : 'Đã thu hồi tin nhắn'),
                      ),
                    );
                  },
                ),
              if (!isDeleted) const Divider(),
              if (!isDeleted)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['❤️', '😆', '😢', '😡'].map((emoji) {
                      return GestureDetector(
                        onTap: () async {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          final reactions = data['reactions'] ?? {};
                          final current = reactions[uid];

                          await FirebaseFirestore.instance
                              .collection('messages')
                              .doc(docId)
                              .update({
                            'reactions.$uid':
                                current == emoji ? FieldValue.delete() : emoji,
                          });
                          Navigator.pop(context);
                        },
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 6.0),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                  senderPhone.isNotEmpty
                      ? StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(senderPhone)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            final userData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            final currentOnline = userData['isOnline'] ?? false;
                            return currentOnline
                                ? Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          },
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              MessageBubble(
                senderName: data['senderName'],
                text: data['text'],
                mediaUrl: data['mediaUrl'],
                isMe: isMe,
                replyTo: replyTo,
                type: type,
              ),
              _buildReactionsBar(doc),
              if (data['seenBy'] != null && (data['seenBy'] as List).isNotEmpty)
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .where(
                        FieldPath.documentId,
                        whereIn: List<String>.from(data['seenBy']),
                      )
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final users = snapshot.data!.docs;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4, left: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: users.map((userDoc) {
                          final u = userDoc.data() as Map<String, dynamic>;
                          final avatar = u['avatarUrl'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: CircleAvatar(
                              radius: 10,
                              backgroundImage:
                                  avatar != null ? NetworkImage(avatar) : null,
                              child: avatar == null
                                  ? const Icon(Icons.person, size: 12)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleReaction(DocumentSnapshot doc, String emoji) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final phone = user.phoneNumber;

    final docRef =
        FirebaseFirestore.instance.collection('messages').doc(doc.id);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data() as Map<String, dynamic>;

      Map<String, dynamic> updatedReactions = {};
      if (data['reactions'] != null) {
        updatedReactions = Map<String, dynamic>.from(data['reactions']);
      }

      if (updatedReactions[phone] == emoji) {
        updatedReactions.remove(phone);
      } else {
        updatedReactions[phone!] = emoji;
      }
      transaction.update(docRef, {'reactions': updatedReactions});
    });
  }

  Widget _buildReactionSelector(DocumentSnapshot doc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ['❤️', '😆', '😢', '😡'].map((emoji) {
          return GestureDetector(
            onTap: () {
              _handleReaction(doc, emoji);
              Navigator.pop(context);
            },
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReactionsBar(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final reactions = data['reactions'] as Map<String, dynamic>?;
    if (reactions == null || reactions.isEmpty) return const SizedBox();

    final Map<String, int> counts = {};
    reactions.forEach((_, emoji) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    });

    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4),
      child: Row(
        children: counts.entries.map((e) {
          return GestureDetector(
            onTap: () => _showReactorList(doc, e.key),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(e.key, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text('${e.value}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showReactorList(DocumentSnapshot doc, String emoji) async {
    final data = doc.data() as Map<String, dynamic>;
    final reactions = data['reactions'] as Map<String, dynamic>?;
    if (reactions == null) return;

    final phones = reactions.entries
        .where((e) => e.value == emoji)
        .map((e) => e.key)
        .toList();

    final users = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: phones)
        .get();

    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Người đã thả $emoji',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          ...users.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundImage: data['avatarUrl'] != null
                    ? NetworkImage(data['avatarUrl'])
                    : null,
                child:
                    data['avatarUrl'] == null ? const Icon(Icons.person) : null,
              ),
              title: Text(data['fullName'] ?? 'Ẩn danh'),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingTo != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _replyingTo!['senderName'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _replyingTo!['text'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _replyingTo = null),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade100,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: sendImageMessage,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade100,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: startOrStopRecording,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => sendTextMessage(_controller.text),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final messages = snapshot.data!.docs;
        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final doc = messages[index];
            _markMessageAsSeen(doc);
            final isExpanded = _expandedMessageIds.contains(doc.id);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedMessageIds.remove(doc.id);
                      } else {
                        _expandedMessageIds.add(doc.id);
                      }
                    });
                  },
                  child: _buildMessageItem(doc),
                ),
                if (isExpanded)
                  _buildSeenByNames(doc)
              ],
            );
          },
        );
      },
    );
  }


  Widget _buildActiveUsers() {
    return SizedBox(
      height: 80,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('isOnline', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          final users = snapshot.data!.docs;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: user['avatarUrl'] != null
                            ? NetworkImage(user['avatarUrl'])
                            : null,
                        child: user['avatarUrl'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['fullName'] ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void _handleReaction(DocumentSnapshot doc, String emoji) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final phone = user.phoneNumber;

      final docRef =
          FirebaseFirestore.instance.collection('messages').doc(doc.id);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        final data = snapshot.data() as Map<String, dynamic>;

        Map<String, dynamic> updatedReactions = {};
        if (data['reactions'] != null) {
          updatedReactions = Map<String, dynamic>.from(data['reactions']);
        }
        updatedReactions[phone!] = emoji;
        transaction.update(docRef, {'reactions': updatedReactions});
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trò chuyện'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _buildActiveUsers(),
            Expanded(child: _buildMessageList()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String? senderName;
  final String? text;
  final String? mediaUrl;
  final bool isMe;
  final Map<String, dynamic>? replyTo;
  final String type;

  const MessageBubble({
    super.key,
    required this.senderName,
    required this.text,
    required this.mediaUrl,
    required this.isMe,
    required this.replyTo,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (type == 'image') {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(mediaUrl ?? '', width: 180),
      );
    } else if (type == 'voice') {
      content = const Icon(Icons.play_arrow);
    } else {
      content = Text(
        text ?? '',
        style: TextStyle(color: isMe ? Colors.white : Colors.black),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 250),
      decoration: BoxDecoration(
        gradient: isMe
            ? const LinearGradient(
                colors: [Color(0xFF64B5F6), Color(0xFF2196F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isMe ? 20 : 0),
          bottomRight: Radius.circular(isMe ? 0 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(2, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && senderName != null)
            Text(
              senderName!,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          if (!isMe) const SizedBox(height: 4),
          if (replyTo != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    replyTo!['senderName'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    replyTo!['text'] ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          content,
        ],
      ),
    );
  }
}
