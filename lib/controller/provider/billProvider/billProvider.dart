import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/controller/services/billServices/billServices.dart';
 

class BillProvider with ChangeNotifier {
  final BillService _service = BillService();

  bool isLoading = true;
  List<Map<String, dynamic>> bills = [];
  double totalRevenue = 0.0;

  // Truyền dữ liệu vào màn hình AllBills
  Stream<QuerySnapshot> fetchBillsByUser(String phoneNumber) {
    return _service.getBillsByUser(phoneNumber);
  }

  // Truy vấn tất cả hóa đơn đã thanh toán
  Stream<QuerySnapshot> fetchPaidBills() {
    return _service.getPaidBills();
  }

  // Cập nhật tổng doanh thu từ hóa đơn
  void calculateTotalRevenue(List<DocumentSnapshot> billDocs) {
    totalRevenue = 0.0;
    for (var doc in billDocs) {
      final data = doc.data() as Map<String, dynamic>;
      totalRevenue += (data['grandTotal'] ?? 0.0);
    }
    notifyListeners();
  }
}
