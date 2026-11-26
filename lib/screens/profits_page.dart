
import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ProfitsPage extends StatefulWidget {
  const ProfitsPage({super.key});

  @override
  State<ProfitsPage> createState() => _ProfitsPageState();
}

class _ProfitsPageState extends State<ProfitsPage> {
  final db = DatabaseHelper.instance;

  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> expenses = [];

  bool loading = true;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  final List<String> months = [
    'كانون الثاني',
    'شباط',
    'آذار',
    'نيسان',
    'أيار',
    'حزيران',
    'تموز',
    'آب',
    'أيلول',
    'تشرين الأول',
    'تشرين الثاني',
    'كانون الأول',
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final results = await Future.wait([
        db.getPayments(),
        db.getExpenses(),
      ]);

      if (!mounted) return;

      setState(() {
        payments = results[0];
        expenses = results[1];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحميل البيانات: $e')),
      );
    }
  }

  List<Map<String, dynamic>> get monthlyPayments {
    return payments.where((payment) {
      final date = DateTime.tryParse(
        payment['date']?.toString() ?? '',
      );

      return date != null &&
          date.month == selectedMonth &&
          date.year == selectedYear;
    }).toList()
      ..sort((a, b) {
        return (b['date'] ?? '').toString().compareTo(
              (a['date'] ?? '').toString(),
            );
      });
  }

  List<Map<String, dynamic>> get monthlyExpenses {
    return expenses.where((expense) {
      final date = DateTime.tryParse(
        expense['date']?.toString() ?? '',
      );

      return date != null &&
          date.month == selectedMonth &&
          date.year == selectedYear;
    }).toList()
      ..sort((a, b) {
        return (b['date'] ?? '').toString().compareTo(
              (a['date'] ?? '').toString(),
            );
      });
  }

  double get totalIncome {
    return monthlyPayments.fold(
      0.0,
      (sum, item) =>
          sum + (double.tryParse(item['amount'].toString()) ?? 0),
    );
  }

  double get totalExpenses {
    return monthlyExpenses.fold(
      0.0,
      (sum, item) =>
          sum + (double.tryParse(item['amount'].toString()) ?? 0),
    );
  }

  double get netProfit => totalIncome - totalExpenses;

  String money(double value) {
    return '${value.toStringAsFixed(0)} د.ع';
  }

  Widget summaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    money(amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: color,
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

  Widget sectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            '$count عملية',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أرباح المولدة'),
        backgroundColor: const Color(0xFF063B35),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 25),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedMonth,
                            decoration: const InputDecoration(
                              labelText: 'الشهر',
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(
                              12,
                              (index) => DropdownMenuItem(
                                value: index + 1,
                                child: Text(months[index]),
                              ),
                            ),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => selectedMonth = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedYear,
                            decoration: const InputDecoration(
                              labelText: 'السنة',
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(8, (index) {
                              final year =
                                  DateTime.now().year - 3 + index;

                              return DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              );
                            }),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => selectedYear = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  summaryCard(
                    title: 'المقبوضات الفعلية',
                    amount: totalIncome,
                    icon: Icons.account_balance_wallet,
                    color: Colors.green,
                  ),

                  summaryCard(
                    title: 'مجموع المصاريف',
                    amount: totalExpenses,
                    icon: Icons.money_off,
                    color: Colors.red,
                  ),

                  Card(
                    margin: const EdgeInsets.all(12),
                    color: const Color(0xFFE3F2EF),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          const Text(
                            'صافي الربح الشهري',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF063B35),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            money(netProfit),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: netProfit >= 0
                                  ? const Color(0xFF008B72)
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            netProfit >= 0
                                ? 'المولدة حققت ربحاً خلال هذا الشهر'
                                : 'المصاريف أكثر من المقبوضات خلال هذا الشهر',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),

                  sectionTitle(
                    'المقبوضات خلال الشهر',
                    monthlyPayments.length,
                  ),

                  if (monthlyPayments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'لا توجد مبالغ مستلمة خلال هذا الشهر',
                        textAlign: TextAlign.center,
                      ),
                    ),

                  ...monthlyPayments.map((payment) {
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(
                          Icons.arrow_downward,
                          color: Colors.green,
                        ),
                      ),
                      title: Text(
                        money(
                          double.tryParse(
                                payment['amount'].toString(),
                              ) ??
                              0,
                        ),
                      ),
                      subtitle: Text(
                        'تاريخ الاستلام: ${payment['date'] ?? ''}',
                      ),
                    );
                  }),

                  const Divider(),

                  sectionTitle(
                    'المصاريف خلال الشهر',
                    monthlyExpenses.length,
                  ),

                  if (monthlyExpenses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'لا توجد مصاريف خلال هذا الشهر',
                        textAlign: TextAlign.center,
                      ),
                    ),

                  ...monthlyExpenses.map((expense) {
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(
                          Icons.money_off,
                          color: Colors.red,
                        ),
                      ),
                      title: Text(
                        expense['title']?.toString() ?? 'مصروف',
                      ),
                      subtitle: Text(
                        'التاريخ: ${expense['date'] ?? ''}',
                      ),
                      trailing: Text(
                        money(
                          double.tryParse(
                                expense['amount'].toString(),
                              ) ??
                              0,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
