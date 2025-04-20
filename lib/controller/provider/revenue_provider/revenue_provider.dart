import 'package:flutter/material.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/controller/services/revenueServices/revenueServices.dart';
 

/// Provider quản lý state và gọi RevenueService
class RevenueProvider with ChangeNotifier {
  final RevenueService _service;

  RevenueProvider({RevenueService? service})
      : _service = service ?? RevenueService() {
    _init();
  }

  /// Filter: tháng hoặc năm hiện tại
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  final List<int> months = List.generate(12, (i) => i + 1);
  final List<int> years = List.generate(6, (i) => DateTime.now().year - 5 + i);

  /// State
  bool isLoading = false;
  double totalRevenue = 0.0;
  List<Map<String, dynamic>> bills = [];
  Map<String, double> revenueByRoom = {};

  void _init() {
    fetchData();
  }

  /// Fetch dữ liệu từ service
  Future<void> fetchData() async {
    isLoading = true;
    notifyListeners();

    final result = await _service.fetchRevenue(
      month: selectedMonth,
      year: selectedYear,
    );

    totalRevenue = result.totalRevenue;
    bills = result.bills;
    revenueByRoom = result.revenueByRoom;

    isLoading = false;
    notifyListeners();
  }

  /// Cập nhật filter và fetch lại
  void updateFilter({int? month, int? year}) {
    if (month != null) selectedMonth = month;
    if (year != null) selectedYear = year;
    fetchData();
  }
}
