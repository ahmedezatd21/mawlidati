
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

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final notesController = TextEditingController();

  DateTime selectedDate = DateTime.now();

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

  List<Map<String, dynamic>> get filteredExpenses {
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

  double get totalExpenses {
    return filteredExpenses.fold(
      0.0,
      (sum, item) =>
          sum + (double.tryParse(item['amount'].toString()) ?? 0),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> showExpenseDialog({
    Map<String, dynamic>? expense,
  }) async {
    final editing = expense != null;

    titleController.text = editing
        ? expense['title']?.toString() ?? ''
        : '';

    amountController.text = editing
        ? expense['amount']?.toString() ?? ''
        : '';

    notesController.text = editing
        ? expense['notes']?.toString() ?? ''
        : '';

    selectedDate = editing
        ? DateTime.tryParse(expense['date']?.toString() ?? '') ??
            DateTime.now()
        : DateTime.now();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                editing ? 'تعديل المصروف' : 'إضافة مصروف جديد',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المصروف',
                        hintText: 'مثلاً: وقود أو صيانة',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المبلغ بالدينار',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );

                        if (date != null) {
                          setDialogState(() {
                            selectedDate = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        'التاريخ: ${selectedDate.year}-'
                        '${selectedDate.month.toString().padLeft(2, '0')}-'
                        '${selectedDate.day.toString().padLeft(2, '0')}',
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
                    final amount =
                        double.tryParse(amountController.text.trim());

                    if (title.isEmpty || amount == null || amount <= 0) {
                      showMessage('أدخل اسم المصروف ومبلغاً صحيحاً');
                      return;
                    }

                    final data = {
                      'title': title,
                      'amount': amount,
                      'notes': notesController.text.trim(),
                      'date':
                          '${selectedDate.year}-'
                          '${selectedDate.month.toString().padLeft(2, '0')}-'
                          '${selectedDate.day.toString().padLeft(2, '0')}',
                    };

                    if (editing) {
                      await db.updateExpense(
                        expense['id'] as int,
                        data,
                      );
                    } else {
                      await db.insertExpense(data);
                    }

                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);

                    await loadExpenses();

                    if (!mounted) return;
                    showMessage(
                      editing
                          ? 'تم تعديل المصروف'
                          : 'تمت إضافة المصروف',
                    );
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteExpense(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المصروف'),
        content: const Text('هل تريد حذف هذا المصروف؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await db.deleteExpense(id);
      await loadExpenses();

      if (!mounted) return;
      showMessage('تم حذف المصروف');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مصاريف المولدة'),
        backgroundColor: const Color(0xFF063B35),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showExpenseDialog(),
        backgroundColor: const Color(0xFF008B72),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('إضافة مصروف'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                          items: List.generate(
                            8,
                            (index) {
                              final year =
                                  DateTime.now().year - 3 + index;

                              return DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              );
                            },
                          ),
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
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  color: const Color(0xFFE3F2EF),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF008B72),
                      child: Icon(
                        Icons.money_off,
                        color: Colors.white,
                      ),
                    ),
                    title: const Text('مجموع مصاريف الشهر'),
                    subtitle: Text(
                      '${filteredExpenses.length} مصروف',
                    ),
                    trailing: Text(
                      '${totalExpenses.toStringAsFixed(0)} د.ع',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF063B35),
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredExpenses.isEmpty
                      ? const Center(
                          child: Text('لا توجد مصاريف لهذا الشهر'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            bottom: 85,
                          ),
                          itemCount: filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final item = filteredExpenses[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFE3F2EF),
                                  child: Icon(
                                    Icons.receipt_long,
                                    color: Color(0xFF008B72),
                                  ),
                                ),
                                title: Text(
                                  item['title']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item['date'] ?? ''}\n'
                                  '${item['notes'] ?? ''}',
                                ),
                                isThreeLine: true,
                                trailing: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${item['amount']} د.ع',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          visualDensity:
                                              VisualDensity.compact,
                                          onPressed: () =>
                                              showExpenseDialog(
                                            expense: item,
                                          ),
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 19,
                                          ),
                                        ),
                                        IconButton(
                                          visualDensity:
                                              VisualDensity.compact,
                                          onPressed: () => deleteExpense(
                                            item['id'] as int,
                                          ),
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 19,
                                          ),
                                        ),
                                      ],
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
    );
  }
}
