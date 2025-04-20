import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PendingBillsPage extends StatefulWidget {
  const PendingBillsPage({super.key});

  @override
  State<PendingBillsPage> createState() => _PendingBillsPageState();
}

class _PendingBillsPageState extends State<PendingBillsPage> {
  late Future<List<Map<String, dynamic>>> billsFuture;

  @override
  void initState() {
    super.initState();
    debugPrint("PendingBillsPage initState: Fetching pending bills...");
    billsFuture = fetchPendingBills();
  }

  Future<void> refreshBills() async {
    setState(() {
      billsFuture = fetchPendingBills();
    });
  }

  Future<List<Map<String, dynamic>>> fetchPendingBills() async {
    debugPrint("fetchPendingBills: Starting query...");
    final billsSnapshot = await FirebaseFirestore.instance
        .collectionGroup('bills')
        .where('isPending', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .get();

    debugPrint(
        "fetchPendingBills: Fetched ${billsSnapshot.docs.length} bill documents");

    List<Map<String, dynamic>> bills = [];

    for (var doc in billsSnapshot.docs) {
      debugPrint("Processing bill doc ID: ${doc.id}");
      // Lấy thông tin tenant từ tài liệu cha của subcollection bills
      final tenantSnapshot = await doc.reference.parent.parent!.get();
      final tenantData = tenantSnapshot.data() as Map<String, dynamic>;
      final roomNo = tenantData['roomNo'] ?? 'Chưa cập nhật';
      debugPrint("Tenant phone: ${tenantSnapshot.id}, roomNo: $roomNo");

      bills.add({
        'id': doc.id,
        'docRef': doc.reference,
        'tenantPhone': tenantSnapshot.id,
        'roomNo': roomNo,
        ...doc.data(),
      });
    }

    debugPrint("fetchPendingBills: Total bills processed: ${bills.length}");
    return bills;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat("#,##0", "vi_VN");
    return Scaffold(
      appBar: AppBar(title: const Text('Hóa đơn cần xử lý')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: billsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint("FutureBuilder: Waiting for bills data...");
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint("FutureBuilder Error: ${snapshot.error}");
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final bills = snapshot.data!;
          if (bills.isEmpty) {
            debugPrint("FutureBuilder: No pending bills found.");
            return const Center(child: Text('Không có hóa đơn cần xử lý.'));
          }

          return ListView.builder(
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              final formattedDate = DateFormat('dd/MM/yyyy')
                  .format((bill['timestamp'] as Timestamp).toDate());

              final formattedTotal =
                  currencyFormatter.format(bill['grandTotal']);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.orange,
                      size: 30,
                    ),
                  ),
                  title: Text(
                    "Phòng: ${bill['roomNo']}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        "Ngày tạo: $formattedDate",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Thanh toán: ${bill['paymentMethod']}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: Text(
                    "$formattedTotalđ",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.orange, size: 24),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Xác nhận đã xử lý hóa đơn?',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          'Xác nhận khách đã thanh toán thành công? Hóa đơn sẽ chuyển sang "Đã thanh toán".',
                          style:
                              TextStyle(fontSize: 15, color: Colors.grey[700]),
                        ),
                        actionsPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        actions: [
                          TextButton(
                            child: const Text('Không'),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Đã thanh toán',
                                style: TextStyle(color: Colors.white)),
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      try {
                        final DocumentReference ref = bill['docRef'];
                        // Sử dụng roomNo (vì roomName chính là roomNo)
                        String userRoomNo = bill['roomNo'];
                        debugPrint(
                            "Updating bill (doc ID: ${bill['id']}) with roomNo: $userRoomNo");
                        await ref.update({
                          'isPaid': true,
                          'isPending': false,
                          'paidAt': FieldValue.serverTimestamp(),
                          'roomName': userRoomNo,
                        });

                        debugPrint(
                            "Bill updated successfully. Sending notification...");

                        await sendNotificationToTenant(
                          bill['tenantPhone'],
                          bill['roomNo'],
                          formattedTotal,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Đã xác nhận hóa đơn thành công!')),
                        );

                        setState(() {
                          billsFuture = fetchPendingBills();
                        });
                      } catch (e) {
                        debugPrint("Error updating bill: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi cập nhật hóa đơn: $e')),
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> sendNotificationToTenant(
      String tenantPhone, String roomNo, String totalAmount) async {
    const String serverUrl =
        'https://pushnoti-8jr2.onrender.com/sendTenantNoti';

    final body = jsonEncode({
      'tenantPhone': tenantPhone,
      'title': 'Hóa đơn đã thanh toán thành công',
      'body':
          'Phòng $roomNo đã được xác nhận thanh toán $totalAmountđ. Cảm ơn bạn!',
    });

    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        debugPrint('🔔 Gửi thông báo cho người thuê thành công');
      } else {
        debugPrint('❌ Lỗi server khi gửi thông báo: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Lỗi kết nối khi gửi thông báo: $e');
    }
  }
}
