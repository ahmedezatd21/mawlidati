
import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ProfitsPage extends StatefulWidget {
  const ProfitsPage({super.key});

  @override
  State<ProfitsPage> createState() => _ProfitsPageState();
}

class _ProfitsPageState extends State<ProfitsPage> {
  final db = DatabaseHelper.instance;

  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> expenses = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final i = await db.getInvoices();
    final e = await db.getExpenses();

    if (!mounted) return;

    setState(() {
      invoices = i;
      expenses = e;
      loading = false;
    });
  }

  double get totalInvoices {
    return invoices.fold<double>(
      0,
      (sum, item) =>
          sum + (item['amount'] as num).toDouble(),
    );
  }

  double get totalPaid {
    return invoices.fold<double>(
      0,
      (sum, item) =>
          sum + (item['paid_amount'] as num).toDouble(),
    );
  }

  double get totalDebts => totalInvoices - totalPaid;

  double get totalExpenses {
    return expenses.fold<double>(
      0,
      (sum, item) =>
          sum + (item['amount'] as num).toDouble(),
    );
  }

  double get netProfit => totalPaid - totalExpenses;

  Widget reportItem(
    String title,
    double amount,
    IconData icon, {
    Color color = const Color(0xFF008B72),
  }) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title),
        trailing: Text(
          '${amount.toStringAsFixed(0)} د.ع',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الأرباح والتقارير'),
          backgroundColor: const Color(0xFF063B35),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: loadData,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: loadData,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Card(
                      color: const Color(0xFF063B35),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            const Text(
                              'صافي الربح النقدي',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${netProfit.toStringAsFixed(0)} د.ع',
                              style: TextStyle(
                                color: netProfit >= 0
                                    ? Colors.white
                                    : Colors.orangeAccent,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    reportItem(
                      'إجمالي الفواتير',
                      totalInvoices,
                      Icons.receipt_long,
                    ),
                    reportItem(
                      'المبالغ المستلمة',
                      totalPaid,
                      Icons.account_balance_wallet,
                    ),
                    reportItem(
                      'الديون المتبقية',
                      totalDebts,
                      Icons.money_off,
                      color: Colors.red,
                    ),
                    reportItem(
                      'إجمالي المصاريف',
                      totalExpenses,
                      Icons.payments,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 15),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'ملاحظة: صافي الربح هنا محسوب نقدياً '
                          'من المبالغ المستلمة فعلياً بعد طرح '
                          'المصاريف المسجلة، وليس من إجمالي '
                          'الفواتير غير المحصلة.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
