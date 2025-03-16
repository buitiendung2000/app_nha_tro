import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/view/homeScreen/homeScreen.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/controller/services/pushNotificationServices/pushNotificationServices.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  // Tạo controllers cho tất cả các trường
  final TextEditingController _roomNoController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController(); // ✅ Số điện thoại
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _permanentAddressController =
      TextEditingController();
  final TextEditingController _temporaryAddressController =
      TextEditingController();
  final TextEditingController _currentAddressController =
      TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _householdOwnerController =
      TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPhoneNumber(); // ✅ Load số điện thoại từ Firebase Auth
  }

  /// ✅ Lấy số điện thoại từ Firebase Auth
  void _loadPhoneNumber() {
    String? phoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;
    if (phoneNumber != null) {
      _phoneController.text = phoneNumber;
    }
  }

  /// ✅ Đăng ký người dùng
  Future<void> _submitForm() async {
    try {
      String phoneNumber = _phoneController.text.trim(); // ✅ Lấy số điện thoại

      if (phoneNumber.isEmpty) {
        throw Exception('Vui lòng nhập số điện thoại');
      }

      // ✅ Kiểm tra nếu số điện thoại đã tồn tại
      final phoneDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get();

      if (phoneDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Số điện thoại này đã được đăng ký!')),
        );
        return;
      }

      // ✅ Lưu thông tin vào Firestore với `phoneNumber` là documentId
      await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .set({
        'roomNo': _roomNoController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'dob': _dobController.text.trim(),
        'gender': _genderController.text.trim(),
        'idNumber': _idNumberController.text.trim(),
        'phoneNumber': phoneNumber, // ✅ Sử dụng phoneNumber làm documentId
        'email': _emailController.text.trim(),
        'permanentAddress': _permanentAddressController.text.trim(),
        'temporaryAddress': _temporaryAddressController.text.trim(),
        'currentAddress': _currentAddressController.text.trim(),
        'job': _jobController.text.trim(),
        'householdOwner': _householdOwnerController.text.trim(),
        'relationship': _relationshipController.text.trim(),
        'registrationDate': DateTime.now(),
        'isRegistered': true,
      });

      // ✅ Hiển thị thông báo thành công
      PushNotificationServices.showSuccessNotification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công!')),
      );

      // ✅ Chuyển hướng đến HomeScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'TRANG ĐĂNG KÝ THÔNG TIN',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              /// ✅ TextField cho các thông tin cơ bản
              _buildTextField(_roomNoController, 'Nhập số phòng (từ 1 đến 8)'),
              _buildTextField(_fullNameController, 'Họ và tên'),
              _buildTextField(_dobController, 'Ngày tháng năm sinh'),
              _buildTextField(_genderController, 'Giới tính'),
              _buildTextField(_idNumberController, 'Số định danh cá nhân/CCCD'),

              /// ✅ Trường số điện thoại (Chỉ đọc)
              _buildTextField(_phoneController, 'Số điện thoại',
                  readOnly: true),

              _buildTextField(_emailController, 'Email'),
              _buildTextField(_permanentAddressController, 'Nơi thường trú'),
              _buildTextField(_temporaryAddressController, 'Nơi tạm trú'),
              _buildTextField(_currentAddressController, 'Nơi ở hiện tại'),
              _buildTextField(_jobController, 'Nghề nghiệp'),
              _buildTextField(_householdOwnerController, 'Tên chủ hộ'),
              _buildTextField(_relationshipController, 'Quan hệ với chủ hộ'),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Đăng ký'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Hàm tạo TextField
  Widget _buildTextField(TextEditingController controller, String hintText,
      {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        readOnly: readOnly, // ✅ Vô hiệu hóa khi readOnly = true
        decoration: InputDecoration(
          hintText: hintText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
