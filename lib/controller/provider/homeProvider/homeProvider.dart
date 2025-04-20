import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class HomeProvider with ChangeNotifier {
  bool hasPendingBills = false;
  bool hasUnreadMessages = false;
  bool hasUnprocessedFeedback = false;
  bool hasReturnRoom = false;

  StreamSubscription<QuerySnapshot>? _messagesSub;
  StreamSubscription<QuerySnapshot>? _feedbackSub;
  StreamSubscription<QuerySnapshot>? _returnRoomSub;

  HomeProvider() {
    _init();
  }

  void _init() {
    _updateFCMToken();
    _checkPendingBills();
    _listenMessages();
    _listenFeedbacks();
    _listenReturnRoom();
  }

  Future<void> _updateFCMToken() async {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber;
    final fcm = await FirebaseMessaging.instance.getToken();
    if (phone != null && fcm != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(phone)
          .update({'fcmToken': fcm});
    }
  }

  Future<void> _checkPendingBills() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collectionGroup('bills')
          .where('isPending', isEqualTo: true)
          .get();
      hasPendingBills = snap.docs.isNotEmpty;
      notifyListeners();
    } catch (_) {}
  }

  void _listenMessages() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final phone = user.phoneNumber;
    _messagesSub = FirebaseFirestore.instance
        .collection('messages')
        .snapshots()
        .listen((snap) {
      bool unread = snap.docs.any((doc) {
        final d = doc.data();
        if (d['senderId'] == user.uid) return false;
        final seenBy = List<String>.from(d['seenBy'] ?? []);
        return phone != null && !seenBy.contains(phone);
      });
      if (hasUnreadMessages != unread) {
        hasUnreadMessages = unread;
        notifyListeners();
      }
    });
  }

  void _listenFeedbacks() {
    _feedbackSub = FirebaseFirestore.instance
        .collection('feedbacks')
        .where('processed', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      final unproc = snap.docs.isNotEmpty;
      if (hasUnprocessedFeedback != unproc) {
        hasUnprocessedFeedback = unproc;
        notifyListeners();
      }
    });
  }

  void _listenReturnRoom() {
    _returnRoomSub = FirebaseFirestore.instance
        .collection('returnRoom')
        .snapshots()
        .listen((snap) {
      final has = snap.docs.isNotEmpty;
      if (hasReturnRoom != has) {
        hasReturnRoom = has;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _feedbackSub?.cancel();
    _returnRoomSub?.cancel();
    super.dispose();
  }
}
