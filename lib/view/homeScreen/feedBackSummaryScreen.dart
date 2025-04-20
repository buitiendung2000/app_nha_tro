import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FeedbackSummaryScreen extends StatelessWidget {
  const FeedbackSummaryScreen({super.key});

  // Hàm xử lý cập nhật trạng thái processed
  // Hàm xử lý cập nhật trạng thái và gửi thông báo tới người thuê
  Future<void> _processFeedback(String docId, BuildContext context) async {
    try {
      // Lấy feedback từ Firestore để lấy số điện thoại của người thuê
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('feedbacks')
          .doc(docId)
          .get();
      final data = doc.data() as Map<String, dynamic>;
      final tenantPhone = data['phoneNumber'] ?? '';

      // Cập nhật trạng thái 'processed' trong feedback
      await FirebaseFirestore.instance
          .collection('feedbacks')
          .doc(docId)
          .update({
        'processed': true,
        'processedAt': FieldValue.serverTimestamp(),
      });

      // Gửi thông báo tới người thuê
      // Thay URL endpoint bên dưới bằng URL thực của server của bạn
      final Uri notificationUrl = Uri.parse(
        'https://pushnoti-8jr2.onrender.com/sendTenantNoti',
      );

      // Tạo dữ liệu để gửi đến endpoint gửi thông báo cho người thuê
      Map<String, String> notificationBody = {
        'tenantPhone': tenantPhone,
        'title': 'Góp ý đang được xử lý',
        'body': 'Góp ý của bạn đang được Chủ trọ xem xét và xử lý',
      };
      print(
          '[DEBUG] Gửi notification tới người thuê với body: $notificationBody');

      final http.Response tenantNotiResponse = await http.post(
        notificationUrl,
        body: notificationBody,
      );
      print(
          '[DEBUG] Phản hồi notification tới người thuê: ${tenantNotiResponse.body}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Góp ý đã được xử lý. Thông báo đã gửi cho người thuê.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xử lý góp ý: $e')),
      );
    }
  }

  // Hàm xóa feedback (hiển thị Dialog xác nhận)
  Future<void> _deleteFeedback(String docId, BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa góp ý này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('feedbacks')
            .doc(docId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Góp ý đã được xóa.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa góp ý: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng hợp góp ý'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedbacks')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Có lỗi xảy ra: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final feedbackDocs = snapshot.data!.docs;
          if (feedbackDocs.isEmpty) {
            return const Center(child: Text('Chưa có góp ý nào.'));
          }
          return ListView.builder(
            itemCount: feedbackDocs.length,
            itemBuilder: (context, index) {
              final doc = feedbackDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final roomNo = data['roomNo'] ?? 'Unknown';
              final phoneNumber = data['phoneNumber'] ?? '';
              final selectedIssues = data['selectedIssues'];
              final additionalFeedback = data['additionalFeedback'] ?? '';
              final processed = data['processed'] == true;
              final processedAtTimestamp = data['processedAt'] as Timestamp?;
              DateTime? processedAt;
              if (processedAtTimestamp != null) {
                processedAt = processedAtTimestamp.toDate();
              }
              String issuesText = '';
              if (selectedIssues is List) {
                issuesText = selectedIssues.join(', ');
              } else if (selectedIssues is String) {
                issuesText = selectedIssues;
              }
              final timestamp = data['timestamp'] as Timestamp?;
              final dateTime = timestamp?.toDate() ?? DateTime.now();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(
                    'Phòng trọ số $roomNo',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Từ người thuê: $phoneNumber'),
                      Text('Vấn đề: $issuesText'),
                      if (additionalFeedback.toString().trim().isNotEmpty)
                        Text('Góp ý: $additionalFeedback'),
                      Text(
                        'Ngày: ${dateTime.toLocal()}'.split('.')[0],
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (processed) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Đã xử lý${processedAt != null ? " lúc: ${processedAt.toLocal()}" : ""}',
                          style: const TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'process') {
                        _processFeedback(doc.id, context);
                      } else if (value == 'delete') {
                        _deleteFeedback(doc.id, context);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'process',
                        child: ListTile(
                          leading:
                              Icon(Icons.check_circle, color: Colors.green),
                          title: Text('Xử lý góp ý'),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Xóa'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
