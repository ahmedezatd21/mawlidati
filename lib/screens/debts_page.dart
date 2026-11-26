
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  List<Map<String, dynamic>> generators = [];

  bool loading = true;
  int? selectedGeneratorId;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  double number(dynamic value) =>
      (value as num?)?.toDouble() ?? 0;

  String money(double value) =>
      '${value.toStringAsFixed(0)} د.ع';

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

  Map<String, dynamic>? findSubscriber(int? id) {
    for (final item in subscribers) {
      if (item['id'] == id) return item;
    }
    return null;
  }

  List<Map<String, dynamic>> get debts {
    return invoices.where((invoice) {
      final remaining =
          number(invoice['amount']) -
          number(invoice['paid_amount']);

      if (remaining <= 0) return false;

      final subscriber = findSubscriber(
        invoice['subscriber_id'] as int?,
      );

      if (subscriber == null) return false;

      if (selectedGeneratorId != null &&
          subscriber['generator_id'] != selectedGeneratorId) {
        return false;
      }

      return true;
    }).toList();
  }

  double get totalDebts {
    return debts.fold(
      0,
      (sum, invoice) =>
          sum +
          number(invoice['amount']) -
          number(invoice['paid_amount']),
    );
  }

  Future<void> callSubscriber(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      showMessage('رقم الهاتف غير متوفر');
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone.trim());

    try {
      if (!await launchUrl(uri)) {
        showMessage('تعذر فتح تطبيق الاتصال');
      }
    } catch (_) {
      showMessage('تعذر فتح تطبيق الاتصال');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F8),
        appBar: AppBar(
          title: const Text('الديون والمتأخرات'),
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF063B35),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 35,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'إجمالي الديون المتبقية',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            money(totalDebts),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'عدد الفواتير غير المسددة: ${debts.length}',
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    DropdownButtonFormField<int?>(
                      value: selectedGeneratorId,
                      decoration: const InputDecoration(
                        labelText: 'تصفية حسب المولدة',
                        filled: true,
                        fillColor: Colors.white,
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

                    const SizedBox(height: 18),

                    const Text(
                      'المشتركون المتأخرون بالدفع',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (debts.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(25),
                          child: Center(
                            child: Text(
                              'ممتاز! لا توجد ديون مستحقة حالياً',
                            ),
                          ),
                        ),
                      ),

                    ...debts.map((invoice) {
                      final subscriber = findSubscriber(
                        invoice['subscriber_id'] as int?,
                      )!;

                      final remaining =
                          number(invoice['amount']) -
                          number(invoice['paid_amount']);

                      final month = invoice['month'];
                      final year = invoice['year'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFFE0F2EE),
                                    child: Icon(
                                      Icons.person,
                                      color: Color(0xFF008B72),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      subscriber['name'].toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    money(remaining),
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const Divider(),

                              Text(
                                'الفاتورة: $month / $year',
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'قيمة الفاتورة: ${money(number(invoice['amount']))}',
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'المدفوع: ${money(number(invoice['paid_amount']))}',
                                style: const TextStyle(
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'رقم الهاتف: ${subscriber['phone']?.toString().isNotEmpty == true ? subscriber['phone'] : 'غير متوفر'}',
                              ),

                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => callSubscriber(
                                    subscriber['phone']?.toString(),
                                  ),
                                  icon: const Icon(Icons.call),
                                  label: const Text('اتصال بالمشترك'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF008B72),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
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
