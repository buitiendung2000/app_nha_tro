import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tinh_tien_dien_nuoc_phong_tro/controller/provider/revenue_provider/revenue_provider.dart';
 

class RevenueScreen extends StatelessWidget {
  const RevenueScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rev = context.watch<RevenueProvider>();
    final fmt = NumberFormat('#,##0', 'vi_VN');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doanh thu theo tháng'),
        centerTitle: true,
        backgroundColor: Colors.teal,
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
            // Filter
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: rev.selectedMonth,
                          items: rev.months
                              .map((m) => DropdownMenuItem<int>(
                                    value: m,
                                    child: Text('Tháng $m'),
                                  ))
                              .toList(),
                          onChanged: (m) => rev.updateFilter(month: m),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: rev.selectedYear,
                          items: rev.years
                              .map((y) => DropdownMenuItem<int>(
                                    value: y,
                                    child: Text('$y'),
                                  ))
                              .toList(),
                          onChanged: (y) => rev.updateFilter(year: y),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tổng doanh thu
            if (rev.isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng doanh thu',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${fmt.format(rev.totalRevenue)} VNĐ',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tháng ${rev.selectedMonth}/${rev.selectedYear}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              // Danh sách hoá đơn
              Expanded(
                child: RefreshIndicator(
                  onRefresh: rev.fetchData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rev.bills.length,
                    itemBuilder: (_, i) {
                      final b = rev.bills[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.receipt_long,
                              color: Colors.teal),
                          title: Text(
                            'Hoá đơn ${i + 1} - Phòng ${b['roomNo']}',
                          ),
                          subtitle: Text(
                            'Số tiền: ${fmt.format(b['grandTotal'])} VNĐ',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
