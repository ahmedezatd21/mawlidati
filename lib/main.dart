
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/subscribers_page.dart';
import 'screens/generators_page.dart';
import 'screens/invoices_page.dart';
import 'screens/debts_page.dart';
import 'screens/expenses_page.dart';
import 'screens/profits_page.dart';
import 'screens/activation_page.dart';

import 'services/license_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const MawlidatiApp());
}

class MawlidatiApp extends StatelessWidget {
  const MawlidatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مولدتي',

      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox(),
        );
      },

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008B72),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7F8),
        fontFamily: 'Arial',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF063B35),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
      ),

      home: const LicenseGate(),
    );
  }
}

// فحص اشتراك التطبيق قبل فتح لوحة التحكم
class LicenseGate extends StatefulWidget {
  const LicenseGate({super.key});

  @override
  State<LicenseGate> createState() => _LicenseGateState();
}

class _LicenseGateState extends State<LicenseGate> {
  late Future<LicenseResult> licenseFuture;

  @override
  void initState() {
    super.initState();
    licenseFuture = LicenseService.instance.checkLicense();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LicenseResult>(
      future: licenseFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F7F8),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF008B72),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'جارٍ التحقق من الاشتراك...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data!.allowed) {
          return const DashboardPage();
        }

        return const ActivationPage(
          home: DashboardPage(),
        );
      },
    );
  }
}

// لوحة التحكم الرئيسية
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  void openPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مولدتي',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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

              children: [
                DashboardCard(
                  title: 'المولدات',
                  value: 'إدارة المولدات',
                  icon: Icons.electric_bolt,
                  onTap: () => openPage(
                    context,
                    const GeneratorsPage(),
                  ),
                ),

                DashboardCard(
                  title: 'المشتركون',
                  value: 'إدارة المشتركين',
                  icon: Icons.people,
                  onTap: () => openPage(
                    context,
                    const SubscribersPage(),
                  ),
                ),

                DashboardCard(
                  title: 'الفواتير',
                  value: 'إدارة الفواتير',
                  icon: Icons.receipt_long,
                  onTap: () => openPage(
                    context,
                    const InvoicesPage(),
                  ),
                ),

                DashboardCard(
                  title: 'الديون',
                  value: 'ديون المشتركين',
                  icon: Icons.account_balance_wallet,
                  onTap: () => openPage(
                    context,
                    const DebtsPage(),
                  ),
                ),

                DashboardCard(
                  title: 'المصاريف',
                  value: 'تسجيل المصاريف',
                  icon: Icons.payments,
                  onTap: () => openPage(
                    context,
                    const ExpensesPage(),
                  ),
                ),

                DashboardCard(
                  title: 'الأرباح',
                  value: 'تقارير الأرباح',
                  icon: Icons.trending_up,
                  onTap: () => openPage(
                    context,
                    const ProfitsPage(),
                  ),
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

            ServiceTile(
              title: 'إدارة المولدات',
              icon: Icons.electric_bolt,
              onTap: () => openPage(
                context,
                const GeneratorsPage(),
              ),
            ),

            ServiceTile(
              title: 'إدارة المشتركين',
              icon: Icons.people_outline,
              onTap: () => openPage(
                context,
                const SubscribersPage(),
              ),
            ),

            ServiceTile(
              title: 'إدارة الفواتير',
              icon: Icons.receipt_long,
              onTap: () => openPage(
                context,
                const InvoicesPage(),
              ),
            ),

            ServiceTile(
              title: 'إدارة الديون',
              icon: Icons.account_balance_wallet,
              onTap: () => openPage(
                context,
                const DebtsPage(),
              ),
            ),

            ServiceTile(
              title: 'تسجيل المصاريف',
              icon: Icons.money,
              onTap: () => openPage(
                context,
                const ExpensesPage(),
              ),
            ),

            ServiceTile(
              title: 'تقارير الأرباح',
              icon: Icons.bar_chart,
              onTap: () => openPage(
                context,
                const ProfitsPage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// بطاقات لوحة التحكم
class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),

        child: Container(
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Icon(
                icon,
                color: const Color(0xFF008B72),
                size: 29,
              ),

              Text(
                title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                value,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// قائمة الخدمات
class ServiceTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const ServiceTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,

      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF008B72),
        ),

        title: Text(title),

        trailing: const Icon(
          Icons.arrow_back_ios,
          size: 16,
        ),

        onTap: onTap,
      ),
    );
  }
}
