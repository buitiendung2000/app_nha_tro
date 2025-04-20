import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileProvider with ChangeNotifier {
  final _col = FirebaseFirestore.instance.collection('users');
  late Stream<QuerySnapshot> usersStream;

  ProfileProvider() {
    usersStream = _col.orderBy('roomNo').snapshots();
  }

  Future<void> deleteUser(String userId) async {
    await _col.doc(userId).delete();
  }

  Future<void> updateUser({
    required String userId,
    required String roomNo,
    required String fullName,
    required String dobText,
    required String gender,
    required String idNumber,
    required String phone,
    required String email,
    required String permanentAddress,
    required String temporaryAddress,
    required String currentAddress,
    required String job,
    required String householdOwner,
    required String relationship,
  }) async {
    Timestamp? dobTs;
    if (dobText.isNotEmpty) {
      dobTs = Timestamp.fromDate(DateFormat('dd/MM/yyyy').parse(dobText));
    }
    await _col.doc(userId).update({
      'roomNo': roomNo,
      'fullName': fullName,
      'dob': dobTs,
      'gender': gender,
      'idNumber': idNumber,
      'phoneNumber': phone,
      'email': email,
      'permanentAddress': permanentAddress,
      'temporaryAddress': temporaryAddress,
      'currentAddress': currentAddress,
      'job': job,
      'householdOwner': householdOwner,
      'relationship': relationship,
    });
  }
}
