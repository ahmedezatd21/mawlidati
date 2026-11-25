
import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class GeneratorsPage extends StatefulWidget {
  const GeneratorsPage({super.key});

  @override
  State<GeneratorsPage> createState() => _GeneratorsPageState();
}

class _GeneratorsPageState extends State<GeneratorsPage> {
  final db = DatabaseHelper.instance;

  final nameController = TextEditingController();
  final priceController = TextEditingController();

  List<Map<String, dynamic>> generators = [];
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadGenerators();
  }

  Future<void> loadGenerators() async {
    try {
      final data = await db.getGenerators();

      if (!mounted) return;

      setState(() {
        generators = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      message('خطأ في تحميل المولدات: $e');
    }
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> saveGenerator({
    int? id,
    required BuildContext sheetContext,
  }) async {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim());

    if (name.isEmpty || price == null || price < 0) {
      message('أدخل اسم المولدة وسعر الأمبير بشكل صحيح');
      return;
    }

    setState(() => saving = true);

    try {
      final data = {
        'name': name,
        'amp_price': price,
      };

      if (id == null) {
        await db.insertGenerator(data);
      } else {
        await db.updateGenerator(id, data);
      }

      nameController.clear();
      priceController.clear();

      if (!mounted) return;

      Navigator.pop(sheetContext);
      await loadGenerators();

      message(
        id == null
            ? 'تمت إضافة المولدة بنجاح'
            : 'تم تعديل المولدة بنجاح',
      );
    } catch (e) {
      if (mounted) {
        message('حدث خطأ أثناء الحفظ: $e');
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  void showGeneratorForm({Map<String, dynamic>? generator}) {
    final isEditing = generator != null;

    nameController.text =
        isEditing ? generator['name']?.toString() ?? '' : '';

    priceController.text =
        isEditing ? generator['amp_price']?.toString() ?? '0' : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEditing ? 'تعديل المولدة' : 'إضافة مولدة جديدة',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المولدة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'سعر الأمبير بالدينار',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              setSheetState(() {});
                              await saveGenerator(
                                id: isEditing ? generator['id'] as int : null,
                                sheetContext: sheetContext,
                              );
                              if (sheetContext.mounted) {
                                setSheetState(() {});
                              }
                            },
                      child: Text(
                        saving ? 'جارٍ الحفظ...' : 'حفظ المولدة',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> deleteGenerator(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المولدة'),
        content: const Text('هل أنت متأكد من حذف هذه المولدة؟'),
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

    if (confirm != true) return;

    try {
      await db.deleteGenerator(id);
      await loadGenerators();
      message('تم حذف المولدة');
    } catch (e) {
      message('تعذر حذف المولدة: $e');
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المولدات'),
          backgroundColor: const Color(0xFF063B35),
          foregroundColor: Colors.white,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showGeneratorForm(),
          backgroundColor: const Color(0xFF063B35),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('إضافة مولدة'),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : generators.isEmpty
                ? const Center(
                    child: Text('لا توجد مولدات حالياً'),
                  )
                : RefreshIndicator(
                    onRefresh: loadGenerators,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 90),
                      itemCount: generators.length,
                      itemBuilder: (context, index) {
                        final generator = generators[index];

                        return Card(
                          margin: const EdgeInsets.all(10),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE0F2EF),
                              child: Icon(
                                Icons.electrical_services,
                                color: Color(0xFF008B72),
                              ),
                            ),
                            title: Text(
                              generator['name']?.toString() ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'سعر الأمبير: ${generator['amp_price'] ?? 0} دينار',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  showGeneratorForm(
                                    generator: generator,
                                  );
                                } else if (value == 'delete') {
                                  deleteGenerator(generator['id'] as int);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('تعديل'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('حذف'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
