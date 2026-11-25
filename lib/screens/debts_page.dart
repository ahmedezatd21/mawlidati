
import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  final db = DatabaseHelper.instance;

  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> subscribers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final i = await db.getInvoices();
    final s = await db.getSubscribers();

    if (!mounted) return;

    setState(() {
      invoices = i;
      subscribers = s;
      loading = false;
    });
  }

  double debtFor(int subscriberId) {
    return invoices
        .where((i) => i['subscriber_id'] == subscriberId)
        .fold<double>(
          0,
          (sum, i) {
            final amount = (i['amount'] as num).toDouble();
            final paid = (i['paid_amount'] as num).toDouble();
            return sum + (amount - paid);
          },
        );
  }

  double get totalDebts {
    return invoices.fold<double>(
      0,
      (sum, i) {
        final amount = (i['amount'] as num).toDouble();
        final paid = (i['paid_amount'] as num).toDouble();
        return sum + (amount - paid);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final debtors = subscribers.where((s) {
      return debtFor(s['id'] as int) > 0;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ديون المشتركين'),
          backgroundColor: const Color(0xFF063B35),
          foregroundColor: Colors.white,
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Card(
                    margin: const EdgeInsets.all(12),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'إجمالي الديون',
                            style: TextStyle(fontSize: 17),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${totalDebts.toStringAsFixed(0)} د.ع',
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('عدد المدينين: ${debtors.length}'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: debtors.isEmpty
                        ? const Center(
                            child: Text('لا توجد ديون حالياً'),
                          )
                        : ListView.builder(
                            itemCount: debtors.length,
                            itemBuilder: (context, index) {
                              final subscriber = debtors[index];
                              final debt = debtFor(
                                subscriber['id'] as int,
                              );

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                  title: Text(
                                    subscriber['name'].toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'الهاتف: ${subscriber['phone'] ?? '-'}',
                                  ),
                                  trailing: Text(
                                    '${debt.toStringAsFixed(0)} د.ع',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
