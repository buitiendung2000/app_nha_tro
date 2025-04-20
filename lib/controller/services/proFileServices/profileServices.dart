 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

typedef UserData = Map<String, dynamic>;

/// Service xử lý CRUD cho hồ sơ người thuê trọ
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lắng nghe stream users
  Stream<QuerySnapshot> getUsersStream() {
    return _firestore.collection('users').snapshots();
  }

  /// Xóa user theo ID
  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  /// Cập nhật thông tin user
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
    Timestamp? dobTimestamp;
    if (dobText.isNotEmpty) {
      dobTimestamp = Timestamp.fromDate(
        DateFormat('dd/MM/yyyy').parse(dobText),
      );
    }
    await _firestore.collection('users').doc(userId).update({
      'roomNo': roomNo,
      'fullName': fullName,
      'dob': dobTimestamp,
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
