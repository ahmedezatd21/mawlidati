
import 'package:flutter/material.dart';
import '../services/license_service.dart';

class ActivationPage extends StatefulWidget {
  final Widget home;

  const ActivationPage({
    super.key,
    required this.home,
  });

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final TextEditingController tokenController = TextEditingController();
  bool loading = false;

  Future<void> activate() async {
    final token = tokenController.text.trim();

    if (token.isEmpty) {
      showMessage('أدخل رمز التفعيل أولاً');
      return;
    }

    setState(() => loading = true);

    try {
      final result =
          await LicenseService.instance.verifyActivation(token);

      if (!mounted) return;

      if (result.allowed) {
        showMessage('تم تفعيل تطبيق مولدتي بنجاح');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => widget.home,
          ),
        );
      } else {
        showMessage(result.message);
      }
    } catch (e) {
      if (mounted) {
        showMessage('تعذر التفعيل. تحقق من الإنترنت والرمز.');
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F8),
        appBar: AppBar(
          title: const Text('تفعيل مولدتي'),
          centerTitle: true,
          backgroundColor: const Color(0xFF063B35),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.electric_bolt,
                      size: 65,
                      color: Color(0xFF008B72),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'مرحباً بك في مولدتي',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF063B35),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'أدخل رمز الاشتراك الذي استلمته لتفعيل التطبيق والبدء بإدارة مولدتك.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: tokenController,
                      maxLength: 48,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'رمز التفعيل',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.key),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: loading ? null : activate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF008B72),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'تفعيل التطبيق',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
