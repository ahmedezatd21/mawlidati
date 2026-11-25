

import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
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

  String subscriberName(dynamic id) {
    final subscriber = subscribers.where(
      (s) => s['id'] == id,
    );

    if (subscriber.isEmpty) return 'مشترك محذوف';
    return subscriber.first['name'].toString();
  }

  Future<void> addInvoice() async {
    if (subscribers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أضف مشتركاً أولاً'),
        ),
      );
      return;
    }

    int? subscriberId = subscribers.first['id'] as int;
    final amount = TextEditingController();
    final paid = TextEditingController(text: '0');
    final month = TextEditingController(
      text: DateTime.now().month.toString(),
    );
    final year = TextEditingController(
      text: DateTime.now().year.toString(),
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة فاتورة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: subscriberId,
                      decoration: const InputDecoration(
                        labelText: 'المشترك',
                      ),
                      items: subscribers.map((s) {
                        return DropdownMenuItem<int>(
                          value: s['id'] as int,
                          child: Text(s['name'].toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          subscriberId = value;
                          final s = subscribers.firstWhere(
                            (x) => x['id'] == value,
                          );
                          amount.text =
                              s['monthly_fee'].toString();
                        });
                      },
                    ),
                    TextField(
                      controller: amount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'مبلغ الفاتورة',
                      ),
                    ),
                    TextField(
                      controller: paid,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ المدفوع',
                      ),
                    ),
                    TextField(
                      controller: month,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'الشهر',
                      ),
                    ),
                    TextField(
                      controller: year,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'السنة',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final a = double.tryParse(amount.text);
                    final p = double.tryParse(paid.text);
                    final m = int.tryParse(month.text);
                    final y = int.tryParse(year.text);

                    if (subscriberId == null ||
                        a == null || a <= 0 ||
                        p == null || p < 0 ||
                        p > a ||
                        m == null || m < 1 || m > 12 ||
                        y == null || y < 2000) {
                      return;
                    }

                    await db.insertInvoice({
                      'subscriber_id': subscriberId,
                      'month': m,
                      'year': y,
                      'amount': a,
                      'paid_amount': p,
                      'status': p >= a
                          ? 'مدفوع'
                          : p > 0
                              ? 'مدفوع جزئياً'
                              : 'غير مدفوع',
                    });

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    await loadData();
                  },
                  child: const Text('حفظ الفاتورة'),
                ),
              ],
            );
          },
        );
      },
    );

    amount.dispose();
    paid.dispose();
    month.dispose();
    year.dispose();
  }

  Future<void> addPayment(Map<String, dynamic> invoice) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل دفعة'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'المبلغ المستلم',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final payment = double.tryParse(controller.text);
              final total = (invoice['amount'] as num).toDouble();
              final oldPaid =
                  (invoice['paid_amount'] as num).toDouble();

              if (payment == null ||
                  payment <= 0 ||
                  oldPaid + payment > total) {
                return;
              }

              final newPaid = oldPaid + payment;

              await db.updateInvoice(
                invoice['id'] as int,
                {
                  'paid_amount': newPaid,
                  'status': newPaid >= total
                      ? 'مدفوع'
                      : 'مدفوع جزئياً',
                },
              );

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }

              await loadData();
            },
            child: const Text('تأكيد الدفع'),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  Future<void> deleteInvoice(int id) async {
    await db.deleteInvoice(id);
    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    final total = invoices.fold<double>(
      0,
      (sum, i) => sum + (i['amount'] as num).toDouble(),
    );

    final paid = invoices.fold<double>(
      0,
      (sum, i) => sum + (i['paid_amount'] as num).toDouble(),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الفواتير'),
          backgroundColor: const Color(0xFF063B35),
          foregroundColor: Colors.white,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: addInvoice,
          backgroundColor: const Color(0xFF008B72),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('فاتورة جديدة'),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Card(
                    margin: const EdgeInsets.all(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text('إجمالي الفواتير: ${total.toStringAsFixed(0)} د.ع'),
                          Text('المبلغ المستلم: ${paid.toStringAsFixed(0)} د.ع'),
                          Text(
                            'المتبقي: ${(total - paid).toStringAsFixed(0)} د.ع',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: invoices.isEmpty
                        ? const Center(
                            child: Text('لا توجد فواتير حتى الآن'),
                          )
                        : ListView.builder(
                            itemCount: invoices.length,
                            itemBuilder: (context, index) {
                              final invoice = invoices[index];
                              final amount =
                                  (invoice['amount'] as num).toDouble();
                              final paidAmount =
                                  (invoice['paid_amount'] as num).toDouble();

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                child: ListTile(
                                  title: Text(
                                    subscriberName(
                                      invoice['subscriber_id'],
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'الشهر: ${invoice['month']}/${invoice['year']}\n'
                                    'الفاتورة: ${amount.toStringAsFixed(0)} د.ع\n'
                                    'المدفوع: ${paidAmount.toStringAsFixed(0)} د.ع\n'
                                    'الحالة: ${invoice['status']}',
                                  ),
                                  isThreeLine: true,
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'payment') {
                                        addPayment(invoice);
                                      } else if (value == 'delete') {
                                        deleteInvoice(
                                          invoice['id'] as int,
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'payment',
                                        child: Text('تسجيل دفعة'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('حذف الفاتورة'),
                                      ),
                                    ],
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
