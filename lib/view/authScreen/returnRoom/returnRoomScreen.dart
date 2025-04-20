import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class ReturnRoomScreen extends StatelessWidget {
  const ReturnRoomScreen({Key? key}) : super(key: key);

  // Hàm formatDateFromString: trả về chuỗi nếu có, nếu không trả về "N/A"
  String formatDateFromString(dynamic dateValue) {
    if (dateValue == null || dateValue.toString().trim().isEmpty) {
      return 'N/A';
    }
    return dateValue.toString();
  }

  // Hàm buildRoomConditionString: nếu roomCondition là list, join lại thành chuỗi
  String buildRoomConditionString(dynamic roomConditionValue) {
    if (roomConditionValue == null) {
      return 'N/A';
    }
    if (roomConditionValue is List) {
      final conditions = roomConditionValue.map((e) => e.toString()).toList();
      return conditions.join(", ");
    }
    return roomConditionValue.toString();
  }

  // Hàm gửi thông báo cho người thuê
  Future<void> sendTenantNotification({
    required String tenantPhone,
    required String tenantName,
    required String roomNumber,
  }) async {
    // URL của server endpoint gửi thông báo tới người thuê
    const url = 'https://pushnoti-8jr2.onrender.com/sendTenantNoti';
    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'tenantPhone': tenantPhone,
          'title': 'Đơn trả phòng của bạn đã được xử lý',
          'body':
              'SĐT: $tenantPhone, Tên: $tenantName, Phòng trọ số: $roomNumber đã xử lý',
        },
      );
      if (response.statusCode == 200) {
        debugPrint("Thông báo gửi tới người thuê thành công.");
      } else {
        debugPrint("Gửi thông báo người thuê thất bại: ${response.body}");
      }
    } catch (e) {
      debugPrint("Lỗi khi gửi thông báo người thuê: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Đang lắng nghe dữ liệu từ collection 'returnRoom'...");
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đơn Trả Phòng"),
        backgroundColor: Colors.teal,
        centerTitle: true,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('returnRoom').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint("Đang tải dữ liệu...");
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint("Có lỗi: ${snapshot.error}");
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final data = snapshot.data;
          if (data == null || data.docs.isEmpty) {
            debugPrint("Không có đơn trả phòng nào");
            return const Center(child: Text("Không có đơn trả phòng nào"));
          }
          debugPrint("Nhận được ${data.docs.length} đơn trả phòng");

          return ListView.builder(
            itemCount: data.docs.length,
            itemBuilder: (context, index) {
              final doc = data.docs[index];
              final requestData = doc.data()! as Map<String, dynamic>;
              debugPrint(
                  "Đơn trả phòng ${index + 1}: ${requestData.toString()}");

              final roomNumber = requestData['roomNumber']?.toString() ?? 'N/A';
              final tenantName = requestData['tenantName']?.toString() ?? 'N/A';
              final tenantPhone =
                  requestData['tenantPhone']?.toString() ?? 'N/A';
              final checkIn = formatDateFromString(requestData['checkInDate']);
              final expectedCheckOut =
                  formatDateFromString(requestData['expectedCheckOutDate']);
              final roomCondition =
                  buildRoomConditionString(requestData['roomCondition']);
              final paymentMethod =
                  requestData['paymentMethod']?.toString() ?? 'N/A';
              final totalCost = requestData['totalCost'] != null
                  ? (requestData['totalCost'] as num).toDouble()
                  : 0;


              final submittedAt = requestData['submittedAt'] is Timestamp
                  ? (requestData['submittedAt'] as Timestamp).toDate().toLocal()
                  : null;
              final submittedAtStr = submittedAt != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(submittedAt)
                  : 'N/A';
              final currencyFormatter = NumberFormat("#,##0", "vi_VN");
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 6,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade50, Colors.teal.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.meeting_room, color: Colors.teal),
                          const SizedBox(width: 8),
                          Text("Phòng số: $roomNumber",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.deepOrange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text("Tên: $tenantName",
                                style: const TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Text("SĐT: $tenantPhone",
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const Divider(height: 20, thickness: 1),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Colors.purple),
                          const SizedBox(width: 8),
                          Text("Nhận phòng: $checkIn",
                              style: const TextStyle(fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.event, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Text("Dự kiến trả: $expectedCheckOut",
                              style: const TextStyle(fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.assignment, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text("Tình trạng phòng: $roomCondition",
                                style: const TextStyle(fontSize: 15)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.payment, color: Colors.green),
                          const SizedBox(width: 8),
                          Text("Thanh toán: $paymentMethod",
                              style: const TextStyle(fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.attach_money, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            "Tạm tính: ${currencyFormatter.format(totalCost)}đ",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.brown),
                          const SizedBox(width: 8),
                          Text("Nộp đơn: $submittedAtStr",
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            debugPrint("Nhấn vào đơn trả phòng: ${doc.id}");
                            // Gửi thông báo cho người thuê
                            await sendTenantNotification(
                              tenantPhone: tenantPhone,
                              tenantName: tenantName,
                              roomNumber: roomNumber,
                            );
                            // Sau khi gửi thông báo, xóa document khỏi collection 'returnRoom'
                            await FirebaseFirestore.instance
                                .collection('returnRoom')
                                .doc(doc.id)
                                .delete();
                            // Thông báo đã gửi và xóa thành công
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Thông báo đã gửi cho người thuê và đơn trả phòng đã được xóa."),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text("Xác nhận"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      )
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
