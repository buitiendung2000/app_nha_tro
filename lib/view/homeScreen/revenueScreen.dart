import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({Key? key}) : super(key: key);

  @override
  _RevenueScreenState createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  double totalRevenue = 0.0; // Tổng doanh thu của tất cả các phòng trong tháng
  bool isLoading = true;
  final currencyFormatter = NumberFormat("#,##0", "vi_VN");
  List<Map<String, dynamic>> bills = [];

  // Doanh thu theo từng phòng, ví dụ: {"Phòng trọ số 1": 500000.0, ...}
  Map<String, double> revenueByRoom = {};

  // Khởi tạo giá trị tháng, năm mặc định theo thời gian hiện tại
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  // Khởi tạo danh sách năm (ví dụ 6 năm gần nhất)
  List<int> years =
      List.generate(6, (index) => DateTime.now().year - 5 + index);

  // Danh sách tháng từ 1 đến 12
  final List<int> months = List.generate(12, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    fetchRevenueData();
  }

  Future<void> fetchRevenueData() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Xác định khoảng thời gian cho tháng đã chọn:
      final startDate = DateTime(selectedYear, selectedMonth, 1);
      final endDate = selectedMonth < 12
          ? DateTime(selectedYear, selectedMonth + 1, 1)
          : DateTime(selectedYear + 1, 1, 1);

      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collectionGroup('bills')
          .where('isPaid', isEqualTo: true)
          .where('paidAt', isGreaterThanOrEqualTo: startDate)
          .where('paidAt', isLessThan: endDate)
          .get();

      double total = 0.0;
      List<Map<String, dynamic>> billsList = [];
      Map<String, double> roomRevenueMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        double amount = 0.0;
        if (data['grandTotal'] != null) {
          if (data['grandTotal'] is int) {
            amount = (data['grandTotal'] as int).toDouble();
          } else if (data['grandTotal'] is double) {
            amount = data['grandTotal'];
          }
        }
        final roomName = data['roomNo'] != null
            ? 'Phòng ${data['roomNo']}'
            : 'Phòng chưa rõ';
        roomRevenueMap[roomName] = (roomRevenueMap[roomName] ?? 0.0) + amount;
        total += amount;
        billsList.add(data);
      }

      setState(() {
        totalRevenue = total;
        bills = billsList;
        revenueByRoom = roomRevenueMap;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint("❌ Lỗi khi lấy dữ liệu doanh thu: $e");
    }
  }

  // Cập nhật lại dữ liệu khi người dùng thay đổi tháng hoặc năm.
  void updateDateFilter({int? month, int? year}) {
    setState(() {
      if (month != null) {
        selectedMonth = month;
      }
      if (year != null) {
        selectedYear = year;
      }
    });
    fetchRevenueData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doanh thu theo tháng"),
        backgroundColor: Colors.teal,
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.blueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Phần chọn tháng và năm được đặt trong Card với góc bo tròn.
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: selectedMonth,
                          items: months.map((int month) {
                            return DropdownMenuItem<int>(
                              value: month,
                              child: Text(
                                "Tháng $month",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              updateDateFilter(month: value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: selectedYear,
                          items: years.map((int year) {
                            return DropdownMenuItem<int>(
                              value: year,
                              child: Text(
                                "$year",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              updateDateFilter(year: value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: fetchRevenueData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hiển thị tổng doanh thu trong Card với thiết kế nổi bật.
                              Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Tổng doanh thu",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "${currencyFormatter.format(totalRevenue)} VNĐ",
                                        style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Tháng $selectedMonth/$selectedYear",
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Chi tiết hóa đơn:",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: bills.length,
                                itemBuilder: (context, index) {
                                  final bill = bills[index];
                                  final amount = bill['grandTotal'] != null
                                      ? currencyFormatter
                                          .format(bill['grandTotal'])
                                      : '0.00';
                                  final room =
                                      bill['roomName'] ?? 'Phòng chưa rõ';
                                  return Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: ListTile(
                                      leading: const Icon(Icons.receipt_long,
                                          color: Colors.teal),
                                      title: Text(
                                        "Hóa đơn ${index + 1} - Phòng $room",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text("Số tiền: $amount VNĐ"),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
