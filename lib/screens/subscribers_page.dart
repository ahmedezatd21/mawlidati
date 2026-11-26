
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
  final search = TextEditingController();

  List<Map<String, dynamic>> generators = [];
  List<Map<String, dynamic>> subscribers = [];

  int? selectedGeneratorId;

  bool loading = true;
  bool saving = false;

  double get selectedAmpPrice {
    final generator = generators.firstWhere(
      (g) => g['id'] == selectedGeneratorId,
      orElse: () => {},
    );

    return double.tryParse(
          generator['amp_price']?.toString() ?? '0',
        ) ??
        0;
  }

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

        if (!generators.any(
          (g) => g['id'] == selectedGeneratorId,
        )) {
          selectedGeneratorId = generators.isNotEmpty
              ? generators.first['id'] as int
              : null;
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

    final ampPrice = selectedAmpPrice;

    if (selectedGeneratorId == null ||
        subscriberName.isEmpty ||
        a == null ||
        a <= 0 ||
        ampPrice <= 0) {
      message('أدخل اسم المشترك وعدد الأمبير بشكل صحيح وتأكد من سعر المولدة');
      return;
    }

    setState(() => saving = true);

    try {
      final monthlyFee = a * ampPrice;

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

  void showSubscriberForm({
    Map<String, dynamic>? subscriber,
  }) {
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

    final ampPrice = selectedAmpPrice;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            double currentFee() {
              final a = double.tryParse(amperes.text) ?? 0;
              return a * ampPrice;
            }

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

                    const SizedBox(height: 20),

                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'اسم المشترك',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: address,
                      decoration: const InputDecoration(
                        labelText: 'العنوان',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: amperes,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'عدد الأمبير',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setSheetState(() {});
                      },
                    ),

                    const SizedBox(height: 15),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2EF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سعر الأمبير: ${ampPrice.toStringAsFixed(0)} دينار',
                            style: const TextStyle(fontSize: 15),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'الفاتورة الشهرية:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            '${currentFee().toStringAsFixed(0)} دينار',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF008B72),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                await saveSubscriber(
                                  id: isEditing
                                      ? subscriber['id'] as int
                                      : null,
                                  sheetContext: sheetContext,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF063B35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(15),
                        ),
                        child: Text(
                          saving
                              ? 'جارٍ الحفظ...'
                              : 'حفظ المشترك',
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
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = subscribers.where((s) {
      final n = (s['name'] ?? '').toString();
      final p = (s['phone'] ?? '').toString();
      final query = search.text.trim();

      return n.contains(query) || p.contains(query);
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
                              child: Text(
                                g['name'].toString(),
                              ),
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
                                              backgroundColor:
                                                  Color(0xFFE0F2EF),
                                              child: Icon(
                                                Icons.person,
                                                color: Color(0xFF008B72),
                                              ),
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
                                              'سعر الأمبير: ${pricePerAmpere.toStringAsFixed(0)} دينار\n'
                                              'الفاتورة الشهرية: ${monthlyFee.toStringAsFixed(0)} دينار',
                                            ),

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
