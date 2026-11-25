
import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final db = DatabaseHelper.instance;

  List<Map<String, dynamic>> expenses = [];
  bool loading = true;

  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> loadExpenses() async {
    final data = await db.getExpenses();

    if (!mounted) return;

    setState(() {
      expenses = data;
      loading = false;
    });
  }

  double get totalExpenses {
    return expenses.fold<double>(
      0,
      (sum, item) =>
          sum + (item['amount'] as num).toDouble(),
    );
  }

  Future<void> addExpense() async {
    titleController.clear();
    amountController.clear();
    notesController.clear();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة مصروف جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'اسم المصروف',
                  hintText: 'مثلاً: كاز أو زيت أو صيانة',
                ),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المبلغ بالدينار',
                ),
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
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
              final title = titleController.text.trim();
              final amount = double.tryParse(
                amountController.text,
              );

              if (title.isEmpty ||
                  amount == null ||
                  amount <= 0) {
                return;
              }

              await db.insertExpense({
                'title': title,
                'amount': amount,
                'notes': notesController.text.trim(),
                'date': DateTime.now().toIso8601String(),
              });

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }

              await loadExpenses();
            },
            child: const Text('حفظ المصروف'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteExpense(int id) async {
    await db.deleteExpense(id);
    await loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المصاريف'),
          backgroundColor: const Color(0xFF063B35),
          foregroundColor: Colors.white,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: addExpense,
          backgroundColor: const Color(0xFF008B72),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('إضافة مصروف'),
        ),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  Card(
                    margin: const EdgeInsets.all(12),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'إجمالي المصاريف',
                            style: TextStyle(fontSize: 17),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${totalExpenses.toStringAsFixed(0)} د.ع',
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: expenses.isEmpty
                        ? const Center(
                            child: Text('لا توجد مصاريف مسجلة'),
                          )
                        : ListView.builder(
                            itemCount: expenses.length,
                            itemBuilder: (context, index) {
                              final item = expenses[index];

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.payments),
                                  ),
                                  title: Text(
                                    item['title'].toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${item['notes'] ?? ''}\n'
                                    '${item['date'].toString().substring(0, 10)}',
                                  ),
                                  isThreeLine: true,
                                  trailing: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${(item['amount'] as num).toStringAsFixed(0)} د.ع',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => deleteExpense(
                                          item['id'] as int,
                                        ),
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
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
