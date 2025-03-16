import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String roomNo;
  final String fullName;
  final Timestamp? dob;
  final String gender;
  final String idNumber;
  final String phone;
  final String email;
  final String permanentAddress;
  final String temporaryAddress;
  final String currentAddress;
  final String job;
  final String householdOwner;
  final String relationship;

  UserModel({
    required this.id,
    required this.roomNo,
    required this.fullName,
    this.dob,
    required this.gender,
    required this.idNumber,
    required this.phone,
    required this.email,
    required this.permanentAddress,
    required this.temporaryAddress,
    required this.currentAddress,
    required this.job,
    required this.householdOwner,
    required this.relationship,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      roomNo: data['roomNo'] ?? '',
      fullName: data['fullName'] ?? '',
      dob: data['dob'],
      gender: data['gender'] ?? '',
      idNumber: data['idNumber'] ?? '',
      phone: data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      permanentAddress: data['permanentAddress'] ?? '',
      temporaryAddress: data['temporaryAddress'] ?? '',
      currentAddress: data['currentAddress'] ?? '',
      job: data['job'] ?? '',
      householdOwner: data['householdOwner'] ?? '',
      relationship: data['relationship'] ?? '',
    );
  }
}
