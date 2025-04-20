import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class TransferInfoScreen extends StatefulWidget {
  const TransferInfoScreen({Key? key}) : super(key: key);

  @override
  State<TransferInfoScreen> createState() => _TransferInfoScreenState();
}

class _TransferInfoScreenState extends State<TransferInfoScreen> {
  File? _image;
  bool _isUploading = false;
  String? _uploadedFileURL;
  final ImagePicker _picker = ImagePicker();

  Future<void> _getImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_image == null) return;
    setState(() {
      _isUploading = true;
    });
    try {
      final String fileName =
          'transfer_${DateTime.now().millisecondsSinceEpoch}.png';
      final Reference storageRef =
          FirebaseStorage.instance.ref().child('transfer_info').child(fileName);

      UploadTask uploadTask = storageRef.putFile(_image!);
      await uploadTask;
      final String downloadURL = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('transfer_info').add({
        'imageUrl': downloadURL,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _uploadedFileURL = downloadURL;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Tải lên thành công!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Có lỗi khi tải lên: $e")),
      );
    }
    setState(() {
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông tin chuyển khoản"),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        size: 60, color: Colors.teal),
                    const SizedBox(height: 10),
                    const Text(
                      "Tải ảnh chụp thông tin chuyển khoản của bạn.\nVí dụ: ảnh có số tài khoản, tên ngân hàng, tên chủ tài khoản...",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text("Chọn hình ảnh"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _getImage,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_image!, height: 250),
                  )
                : const Text(
                    "Chưa có hình ảnh được chọn",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
            const SizedBox(height: 24),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text("Tải ảnh lên"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 14),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _uploadFile,
                  ),
            const SizedBox(height: 24),
            if (_uploadedFileURL != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Đã tải lên: $_uploadedFileURL",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
