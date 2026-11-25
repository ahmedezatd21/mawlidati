

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GeneratorsPage extends StatefulWidget {
  const GeneratorsPage({super.key});

  @override
  State<GeneratorsPage> createState() => _GeneratorsPageState();
}

class _GeneratorsPageState extends State<GeneratorsPage> {
  final db = Supabase.instance.client;
  final nameController = TextEditingController();
  final priceController = TextEditingController();

  List<Map<String, dynamic>> generators = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadGenerators();
  }

  Future<void> loadGenerators() async {
    try {
      final data = await db
          .from('generators')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        generators = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      message('خطأ في تحميل المولدات: $e');
    }
  }

  void message(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> addGenerator() async {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim());

    if (name.isEmpty || price == null || price < 0) {
      message('أدخل اسم المولدة وسعر الأمبير بشكل صحيح');
      return;
    }

    try {
      await db.from('generators').insert({
        'owner_id': db.auth.currentUser!.id,
        'name': name,
        'amp_price': price,
      });

      nameController.clear();
      priceController.clear();

      if (!mounted) return;
      Navigator.pop(context);
      await loadGenerators();
      message('تمت إضافة المولدة بنجاح');
    } catch (e) {
      message('تعذرت إضافة المولدة: $e');
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'إضافة مولدة جديدة',
                style: TextStyle(
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
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'سعر الأمبير بالدينار',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: addGenerator,
                  child: const Text('حفظ المولدة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          title: const Text('مولداتي'),
          backgroundColor: const Color(0xFF063B35),
          foregroundColor: Colors.white,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: showAddForm,
          backgroundColor: const Color(0xFF063B35),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('إضافة مولدة'),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : generators.isEmpty
                ? const Center(child: Text('لا توجد مولدات حالياً'))
                : RefreshIndicator(
                    onRefresh: loadGenerators,
                    child: ListView.builder(
                      itemCount: generators.length,
                      itemBuilder: (context, index) {
                        final generator = generators[index];
                        return Card(
                          margin: const EdgeInsets.all(10),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.electrical_services),
                            ),
                            title: Text(generator['name'] ?? ''),
                            subtitle: Text(
                              'سعر الأمبير: ${generator['amp_price']} دينار',
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
