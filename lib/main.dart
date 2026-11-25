
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tnyrbthjncuveagitlgm.supabase.co/rest/v1/',
    anonKey: 'sb_publishable_T_1ojE6n87K9kUQi2EAUTQ_SsW0NPBy',
  );

  runApp(const MawlidatiApp());
}

class MawlidatiApp extends StatelessWidget {
  const MawlidatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مولدتي',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008B72),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7F8),
        fontFamily: 'Arial',
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF063B35),
          foregroundColor: Colors.white,
          title: const Text(
            'مولدتي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF063B35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً بك في مولدتي',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'إدارة مولدتك أصبحت أسهل',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'لوحة التحكم',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: const [
                  DashboardCard(
                    title: 'المولدات',
                    value: '0',
                    icon: Icons.electric_bolt,
                  ),
                  DashboardCard(
                    title: 'المشتركون',
                    value: '0',
                    icon: Icons.people,
                  ),
                  DashboardCard(
                    title: 'الفواتير',
                    value: '0',
                    icon: Icons.receipt_long,
                  ),
                  DashboardCard(
                    title: 'الديون',
                    value: '0 د.ع',
                    icon: Icons.account_balance_wallet,
                  ),
                  DashboardCard(
                    title: 'المصاريف',
                    value: '0 د.ع',
                    icon: Icons.payments,
                  ),
                  DashboardCard(
                    title: 'الأرباح',
                    value: '0 د.ع',
                    icon: Icons.trending_up,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'الخدمات',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const ServiceTile(
                title: 'إدارة المشتركين',
                icon: Icons.people_outline,
              ),
              const ServiceTile(
                title: 'إدارة الفواتير',
                icon: Icons.receipt_long,
              ),
              const ServiceTile(
                title: 'تسجيل المصاريف',
                icon: Icons.money,
              ),
              const ServiceTile(
                title: 'تقارير المولدة',
                icon: Icons.bar_chart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: const Color(0xFF008B72), size: 29),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceTile extends StatelessWidget {
  final String title;
  final IconData icon;

  const ServiceTile({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF008B72)),
        title: Text(title),
        trailing: const Icon(Icons.arrow_back_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}
