import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class CreateNotificationPage extends StatefulWidget {
  const CreateNotificationPage({Key? key}) : super(key: key);

  @override
  State<CreateNotificationPage> createState() => _CreateNotificationPageState();
}

class _CreateNotificationPageState extends State<CreateNotificationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Lưu vào Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'createdAt': Timestamp.now(),
        'createdBy': 'admin',
        'isPublic': true,
      });

      // 2. Gửi thông báo đến người thuê
      await sendNotificationToAllTenants();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Thêm & gửi thông báo thành công')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi: ${e.toString()}')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> sendNotificationToAllTenants() async {
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    for (var user in usersSnapshot.docs) {
      final tenantPhone = user.id; // Giả sử ID document là số điện thoại
      await sendNotificationToTenant(tenantPhone);
    }
  }

  Future<void> sendNotificationToTenant(String tenantPhone) async {
    const String serverUrl =
        'https://pushnoti-8jr2.onrender.com/sendTenantNoti';

    final body = jsonEncode({
      'tenantPhone': tenantPhone,
      'title': 'Thông báo mới từ chủ trọ',
      'body': '📢 Bạn đã có thông báo mới từ Chủ trọ. Xin cảm ơn!',
    });

    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Đã gửi thông báo tới $tenantPhone');
      } else {
        debugPrint(
            '❌ Lỗi từ server khi gửi cho $tenantPhone: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Lỗi kết nối khi gửi cho $tenantPhone: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo thông báo'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Vui lòng nhập tiêu đề'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Nội dung thông báo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Vui lòng nhập nội dung'
                    : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _submitNotification,
                      icon: const Icon(Icons.send),
                      label: const Text('Gửi thông báo'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
