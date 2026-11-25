
import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class SubscribersPage extends StatefulWidget {
  const SubscribersPage({super.key});

  @override
  State<SubscribersPage> createState() => _SubscribersPageState();
}

class _SubscribersPageState extends State<SubscribersPage> {
  final db = DatabaseHelper.instance;

  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final amperes = TextEditingController();
  final price = TextEditingController();
  final search = TextEditingController();

  List<Map<String, dynamic>> generators = [];
  List<Map<String, dynamic>> subscribers = [];

  int? selectedGeneratorId;

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

        if (generators.isNotEmpty) {
          selectedGeneratorId = generators.first['id'] as int;
        }

        loading = false;
      });

      if (selectedGeneratorId != null) {
        await loadData();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      message('خطأ في تحميل المولدات: $e');
    }
  }

  Future<void> loadData() async {
    if (selectedGeneratorId == null) return;

    setState(() => loading = true);

    try {
      final data = await db.getSubscribers();

      if (!mounted) return;

      setState(() {
        subscribers = data.where((s) {
          return s['generator_id'] == selectedGeneratorId;
        }).toList();

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      message('خطأ في تحميل المشتركين: $e');
    }
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> saveSubscriber({
    int? id,
    required BuildContext sheetContext,
  }) async {
    if (saving) return;

    final subscriberName = name.text.trim();
    final subscriberPhone = phone.text.trim();
    final subscriberAddress = address.text.trim();

    final a = double.tryParse(amperes.text.trim());
    final p = double.tryParse(price.text.trim());

    if (selectedGeneratorId == null ||
        subscriberName.isEmpty ||
        subscriberAddress.isEmpty ||
        a == null ||
        a <= 0 ||
        p == null ||
        p < 0) {
      message('أدخل البيانات المطلوبة بشكل صحيح');
      return;
    }

    setState(() => saving = true);

    try {
      final monthlyFee = a * p;

      final data = {
        'generator_id': selectedGeneratorId,
        'name': subscriberName,
        'phone': subscriberPhone,
        'ampere': a,
        'monthly_fee': monthlyFee,
        'notes': subscriberAddress,
      };

      if (id == null) {
        await db.insertSubscriber(data);
      } else {
        await db.updateSubscriber(id, data);
      }

      if (!mounted) return;

      Navigator.pop(sheetContext);

      name.clear();
      phone.clear();
      address.clear();
      amperes.clear();
      price.clear();

      await loadData();

      message(
        id == null
            ? 'تمت إضافة المشترك بنجاح'
            : 'تم تعديل بيانات المشترك بنجاح',
      );
    } catch (e) {
      message('حدث خطأ أثناء الحفظ: $e');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  void showSubscriberForm({Map<String, dynamic>? subscriber}) {
    final isEditing = subscriber != null;

    name.text = isEditing
        ? subscriber['name']?.toString() ?? ''
        : '';

    phone.text = isEditing
        ? subscriber['phone']?.toString() ?? ''
        : '';

    address.text = isEditing
        ? subscriber['notes']?.toString() ?? ''
        : '';

    amperes.text = isEditing
        ? subscriber['ampere']?.toString() ?? ''
        : '';

    if (isEditing) {
      final amp = double.tryParse(amperes.text) ?? 0;
      final fee =
          double.tryParse(subscriber['monthly_fee'].toString()) ?? 0;

      price.text = amp > 0 ? (fee / amp).toString() : '0';
    } else {
      price.clear();
    }

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEditing
                          ? 'تعديل بيانات المشترك'
                          : 'إضافة مشترك جديد',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    field(name, 'اسم المشترك'),
                    field(phone, 'رقم الهاتف'),
                    field(address, 'العنوان'),

                    field(
                      amperes,
                      'عدد الأمبير',
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),

                    field(
                      price,
                      'سعر الأمبير بالدينار',
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                setSheetState(() {});
                                await saveSubscriber(
                                  id: isEditing
                                      ? subscriber['id'] as int
                                      : null,
                                  sheetContext: sheetContext,
                                );

                                if (sheetContext.mounted) {
                                  setSheetState(() {});
                                }
                              },
                        child: Text(
                          saving ? 'جارٍ الحفظ...' : 'حفظ المشترك',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget field(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> deleteSubscriber(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المشترك'),
        content: const Text(
          'هل أنت متأكد من حذف هذا المشترك؟',
        ),
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
      await db.deleteSubscriber(id);
      await loadData();
      message('تم حذف المشترك بنجاح');
    } catch (e) {
      message('تعذر حذف المشترك: $e');
    }
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    address.dispose();
    amperes.dispose();
    price.dispose();
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = subscribers.where((s) {
      final n = (s['name'] ?? '').toString();
      final p = (s['phone'] ?? '').toString();

      return n.contains(search.text) ||
          p.contains(search.text);
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المشتركين'),
          backgroundColor: const Color(0xFF063B35),
          foregroundColor: Colors.white,
        ),

        floatingActionButton: generators.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () => showSubscriberForm(),
                backgroundColor: const Color(0xFF063B35),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.person_add),
                label: const Text('إضافة مشترك'),
              ),

        body: loading && generators.isEmpty
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : generators.isEmpty
                ? const Center(
                    child: Text(
                      'أضف مولدة أولاً حتى تتمكن من إضافة المشتركين',
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: DropdownButtonFormField<int>(
                          value: selectedGeneratorId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'اختر المولدة',
                            border: OutlineInputBorder(),
                          ),
                          items: generators.map((g) {
                            return DropdownMenuItem<int>(
                              value: g['id'] as int,
                              child: Text(g['name'].toString()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              selectedGeneratorId = value;
                              search.clear();
                            });

                            loadData();
                          },
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: TextField(
                          controller: search,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'ابحث عن مشترك...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),

                      Expanded(
                        child: loading
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : filtered.isEmpty
                                ? const Center(
                                    child: Text(
                                      'لا يوجد مشتركون حالياً',
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: loadData,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.only(
                                        bottom: 90,
                                      ),
                                      itemCount: filtered.length,
                                      itemBuilder: (context, index) {
                                        final s = filtered[index];

                                        final ampere =
                                            double.tryParse(
                                                  s['ampere'].toString(),
                                                ) ??
                                                0;

                                        final monthlyFee =
                                            double.tryParse(
                                                  s['monthly_fee'].toString(),
                                                ) ??
                                                0;

                                        final pricePerAmpere =
                                            ampere > 0
                                                ? monthlyFee / ampere
                                                : 0;

                                        return Card(
                                          margin:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 6,
                                          ),
                                          child: ListTile(
                                            leading: const CircleAvatar(
                                              child: Icon(Icons.person),
                                            ),

                                            title: Text(
                                              s['name']?.toString() ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                            subtitle: Text(
                                              'الهاتف: ${s['phone'] ?? '-'}\n'
                                              'العنوان: ${s['notes'] ?? '-'}\n'
                                              'الأمبير: $ampere\n'
                                              'سعر الأمبير: ${pricePerAmpere.toStringAsFixed(0)} د.ع\n'
                                              'الفاتورة الشهرية: ${monthlyFee.toStringAsFixed(0)} د.ع',
                                            ),

                                            isThreeLine: true,

                                            trailing:
                                                PopupMenuButton<String>(
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  showSubscriberForm(
                                                    subscriber: s,
                                                  );
                                                } else if (value ==
                                                    'delete') {
                                                  deleteSubscriber(
                                                    s['id'] as int,
                                                  );
                                                }
                                              },
                                              itemBuilder: (context) =>
                                                  const [
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
                    ],
                  ),
      ),
    );
  }
}
