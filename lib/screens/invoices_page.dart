
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
  List<Map<String, dynamic>> generators = [];

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  int? selectedGeneratorId;

  bool loading = true;

  final Color primaryColor = const Color(0xFF008B72);

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

  double number(dynamic value) {
    return (value as num?)?.toDouble() ?? 0;
  }

  String money(dynamic value) {
    return '${number(value).toStringAsFixed(0)} د.ع';
  }

  Future<void> loadData() async {
    final results = await Future.wait([
      db.getInvoices(),
      db.getSubscribers(),
      db.getGenerators(),
    ]);

    if (!mounted) return;

    setState(() {
      invoices = results[0];
      subscribers = results[1];
      generators = results[2];
      loading = false;
    });
  }

  Map<String, dynamic>? getSubscriber(int? id) {
    if (id == null) return null;

    for (final subscriber in subscribers) {
      if (subscriber['id'] == id) return subscriber;
    }

    return null;
  }

  String subscriberName(int? id) {
    return getSubscriber(id)?['name']?.toString() ?? 'مشترك محذوف';
  }

  List<Map<String, dynamic>> get filteredInvoices {
    return invoices.where((invoice) {
      return invoice['month'] == selectedMonth &&
          invoice['year'] == selectedYear;
    }).toList();
  }

  double get totalAmount {
    return filteredInvoices.fold(
      0,
      (sum, invoice) => sum + number(invoice['amount']),
    );
  }

  double get totalPaid {
    return filteredInvoices.fold(
      0,
      (sum, invoice) => sum + number(invoice['paid_amount']),
    );
  }

  double get totalRemaining => totalAmount - totalPaid;

  Future<void> createInvoices() async {
    if (subscribers.isEmpty) {
      showMessage('أضف مشتركين أولاً');
      return;
    }

    try {
      final count = await db.createMonthlyInvoices(
        month: selectedMonth,
        year: selectedYear,
        generatorId: selectedGeneratorId,
      );

      await loadData();

      if (!mounted) return;

      showMessage(
        count == 0
            ? 'الفواتير موجودة مسبقاً أو لا توجد اشتراكات مستحقة'
            : 'تم إنشاء $count فاتورة بنجاح',
      );
    } catch (e) {
      showMessage('حدث خطأ أثناء إنشاء الفواتير: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> addPayment(Map<String, dynamic> invoice) async {
    final controller = TextEditingController();

    final amount = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تسجيل دفعة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('المشترك: ${subscriberName(invoice['subscriber_id'])}'),
              const SizedBox(height: 10),
              Text(
                'المتبقي: ${money(number(invoice['amount']) - number(invoice['paid_amount']))}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'مبلغ الدفعة',
                  suffixText: 'د.ع',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(
                  controller.text.trim().replaceAll(',', '.'),
                );

                if (value == null || value <= 0) return;

                Navigator.pop(context, value);
              },
              child: const Text('تأكيد الدفع'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (amount == null) return;

    try {
      await db.recordPayment({
        'invoice_id': invoice['id'],
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
      });

      await loadData();

      showMessage('تم تسجيل الدفعة بنجاح');
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> showPaymentHistory(
    Map<String, dynamic> invoice,
  ) async {
    final payments = await db.getInvoicePayments(invoice['id']);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('سجل الدفعات'),
          content: SizedBox(
            width: double.maxFinite,
            child: payments.isEmpty
                ? const Text('لا توجد دفعات مسجلة')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: payments.length,
                    separatorBuilder: (_, __) =>
                        const Divider(),
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      final date = DateTime.tryParse(
                        payment['date'].toString(),
                      );

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          money(payment['amount']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        subtitle: Text(
                          date == null
                              ? ''
                              : '${date.year}/${date.month}/${date.day}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: dialogContext,
                              builder: (ctx) => AlertDialog(
                                title: const Text('حذف الدفعة'),
                                content: const Text(
                                  'هل تريد حذف هذه الدفعة؟ سيتم تحديث الفاتورة تلقائياً.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('إلغاء'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('حذف'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await db.deletePayment(payment['id']);

                              if (!mounted) return;

                              Navigator.pop(dialogContext);
                              await loadData();
                              showMessage('تم حذف الدفعة');
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteInvoice(Map<String, dynamic> invoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الفاتورة'),
        content: const Text(
          'سيتم حذف الفاتورة وجميع دفعاتها. هل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await db.deleteInvoice(invoice['id']);
      await loadData();
      showMessage('تم حذف الفاتورة');
    }
  }

  Color statusColor(String status) {
    if (status == 'مدفوع') return Colors.green;
    if (status == 'مدفوع جزئياً') return Colors.orange;
    return Colors.red;
  }

  Widget summaryCard(
    String title,
    double value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 5),
            FittedBox(
              child: Text(
                money(value),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F8),
        appBar: AppBar(
          title: const Text('الفواتير الشهرية'),
          backgroundColor: const Color(0xFF063B35),
          foregroundColor: Colors.white,
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        summaryCard(
                          'إجمالي الفواتير',
                          totalAmount,
                          primaryColor,
                          Icons.receipt_long,
                        ),
                        const SizedBox(width: 8),
                        summaryCard(
                          'المقبوض',
                          totalPaid,
                          Colors.green,
                          Icons.payments,
                        ),
                        const SizedBox(width: 8),
                        summaryCard(
                          'المتبقي',
                          totalRemaining,
                          Colors.red,
                          Icons.account_balance_wallet,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'إنشاء الفواتير',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            DropdownButtonFormField<int>(
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
                                  setState(() {
                                    selectedMonth = value;
                                  });
                                }
                              },
                            ),

                            const SizedBox(height: 12),

                            DropdownButtonFormField<int>(
                              value: selectedYear,
                              decoration: const InputDecoration(
                                labelText: 'السنة',
                                border: OutlineInputBorder(),
                              ),
                              items: List.generate(
                                5,
                                (index) {
                                  final year =
                                      DateTime.now().year - 2 + index;
                                  return DropdownMenuItem(
                                    value: year,
                                    child: Text(year.toString()),
                                  );
                                },
                              ),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedYear = value;
                                  });
                                }
                              },
                            ),

                            const SizedBox(height: 12),

                            DropdownButtonFormField<int?>(
                              value: selectedGeneratorId,
                              decoration: const InputDecoration(
                                labelText: 'المولدة',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('جميع المولدات'),
                                ),
                                ...generators.map((generator) {
                                  return DropdownMenuItem<int?>(
                                    value: generator['id'] as int,
                                    child: Text(
                                      generator['name'].toString(),
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedGeneratorId = value;
                                });
                              },
                            ),

                            const SizedBox(height: 14),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: createInvoices,
                                icon: const Icon(Icons.add),
                                label: const Text('إنشاء الفواتير الشهرية'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'فواتير ${months[selectedMonth - 1]} $selectedYear',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (filteredInvoices.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(25),
                          child: Center(
                            child: Text(
                              'لا توجد فواتير لهذا الشهر',
                            ),
                          ),
                        ),
                      ),

                    ...filteredInvoices.map((invoice) {
                      final amount = number(invoice['amount']);
                      final paid = number(invoice['paid_amount']);
                      final remaining = amount - paid;
                      final status =
                          invoice['status']?.toString() ?? 'غير مدفوع';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      subscriberName(
                                        invoice['subscriber_id'] as int?,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor(status)
                                          .withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor(status),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const Divider(),

                              Text('قيمة الفاتورة: ${money(amount)}'),
                              const SizedBox(height: 5),
                              Text(
                                'المدفوع: ${money(paid)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'المتبقي: ${money(remaining)}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (remaining > 0)
                                    ElevatedButton.icon(
                                      onPressed: () => addPayment(invoice),
                                      icon: const Icon(
                                        Icons.payments,
                                        size: 17,
                                      ),
                                      label: const Text('تسجيل دفعة'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),

                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        showPaymentHistory(invoice),
                                    icon: const Icon(
                                      Icons.history,
                                      size: 17,
                                    ),
                                    label: const Text('سجل الدفعات'),
                                  ),

                                  IconButton(
                                    onPressed: () => deleteInvoice(invoice),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
      ),
    );
  }
}
