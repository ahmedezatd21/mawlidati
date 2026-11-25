
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscribersPage extends StatefulWidget {
  const SubscribersPage({super.key});

  @override
  State<SubscribersPage> createState() => _SubscribersPageState();
}

class _SubscribersPageState extends State<SubscribersPage> {
  final db = Supabase.instance.client;

  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final amperes = TextEditingController();
  final price = TextEditingController();
  final search = TextEditingController();

  List<Map<String, dynamic>> generators = [];
  List<Map<String, dynamic>> subscribers = [];

  String? selectedGeneratorId;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadGenerators();
  }

  Future<void> loadGenerators() async {
    try {
      final data = await db
          .from('generators')
          .select('id, name, amp_price')
          .order('created_at', ascending: false);

      if (!mounted) return;

      generators = List<Map<String, dynamic>>.from(data);

      if (generators.isNotEmpty) {
        selectedGeneratorId = generators.first['id'].toString();
        await loadData();
      } else {
        setState(() => loading = false);
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
      final data = await db
          .from('subscribers')
          .select()
          .eq('generator_id', selectedGeneratorId!)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        subscribers = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      message('خطأ في تحميل المشتركين: $e');
    }
  }

  void message(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> addSubscriber() async {
    if (saving) return;

    final a = int.tryParse(amperes.text.trim());
    final p = double.tryParse(price.text.trim());

    if (selectedGeneratorId == null ||
        name.text.trim().isEmpty ||
        address.text.trim().isEmpty ||
        a == null ||
        a <= 0 ||
        p == null ||
        p < 0) {
      message('أدخل البيانات المطلوبة بشكل صحيح');
      return;
    }

    setState(() => saving = true);

    try {
      await db.from('subscribers').insert({
        'generator_id': selectedGeneratorId,
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'address': address.text.trim(),
        'amps': a,
        'price_per_ampere': p,
      });

      name.clear();
      phone.clear();
      address.clear();
      amperes.clear();
      price.clear();

      if (!mounted) return;

      Navigator.pop(context);
      await loadData();
      message('تمت إضافة المشترك بنجاح');
    } catch (e) {
      message('تعذرت الإضافة: $e');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  void showAddForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'إضافة مشترك جديد',
                  style: TextStyle(
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
                  keyboard: TextInputType.number,
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
                    onPressed: saving ? null : addSubscriber,
                    child: Text(
                      saving ? 'جارٍ الحفظ...' : 'حفظ المشترك',
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      return n.contains(search.text) || p.contains(search.text);
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
                onPressed: showAddForm,
                backgroundColor: const Color(0xFF063B35),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.person_add),
                label: const Text('إضافة مشترك'),
              ),
        body: loading && generators.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : generators.isEmpty
                ? const Center(
                    child: Text('أضف مولدة أولاً حتى تتمكن من إضافة المشتركين'),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: DropdownButtonFormField<String>(
                          value: selectedGeneratorId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'اختر المولدة',
                            border: OutlineInputBorder(),
                          ),
                          items: generators.map((g) {
                            return DropdownMenuItem<String>(
                              value: g['id'].toString(),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                    child: Text('لا يوجد مشتركون حالياً'),
                                  )
                                : RefreshIndicator(
                                    onRefresh: loadData,
                                    child: ListView.builder(
                                      itemCount: filtered.length,
                                      itemBuilder: (context, index) {
                                        final s = filtered[index];

                                        return Card(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 6,
                                          ),
                                          child: ListTile(
                                            leading: const CircleAvatar(
                                              child: Icon(Icons.person),
                                            ),
                                            title: Text(
                                              s['name']?.toString() ?? '',
                                            ),
                                            subtitle: Text(
                                              'الهاتف: ${s['phone'] ?? '-'}\n'
                                              'الأمبير: ${s['amps'] ?? 0}\n'
                                              'سعر الأمبير: ${s['price_per_ampere'] ?? 0} د.ع\n'
                                              'الفاتورة الشهرية: ${s['monthly_fee'] ?? 0} د.ع',
                                            ),
                                            isThreeLine: true,
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
