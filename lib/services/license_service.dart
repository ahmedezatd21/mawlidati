
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../database/database_helper.dart';

enum LicenseState {
  needsActivation,
  active,
  gracePeriod,
  expired,
  suspended,
  verificationRequired,
  invalid,
}

class LicenseResult {
  final LicenseState state;
  final String message;

  const LicenseResult(this.state, this.message);

  bool get allowed =>
      state == LicenseState.active ||
      state == LicenseState.gracePeriod;
}

class LicenseService {
  static final LicenseService instance = LicenseService._();

  LicenseService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  static const int graceDays = 7;

  static const String databaseUrl =
      'https://mawalidati-4db02-default-rtdb.asia-southeast1.firebasedatabase.app';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseDatabase get _firebase {
    return FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseUrl,
    );
  }

  // التحقق من رمز التفعيل لأول مرة
  Future<LicenseResult> verifyActivation(String token) async {
    final cleanToken = token.trim().toLowerCase();

    if (!RegExp(r'^[a-f0-9]{48}$').hasMatch(cleanToken)) {
      return const LicenseResult(
        LicenseState.invalid,
        'رمز التفعيل غير صحيح',
      );
    }

    try {
      return await _verifyOnline(cleanToken);
    } on FirebaseException catch (e) {
      return LicenseResult(
        LicenseState.verificationRequired,
        'تعذر التحقق من الرمز: ${e.message ?? e.code}',
      );
    } catch (_) {
      return const LicenseResult(
        LicenseState.verificationRequired,
        'تعذر الاتصال بخدمة التفعيل',
      );
    }
  }

  // فحص الترخيص عند فتح التطبيق
  Future<LicenseResult> checkLicense() async {
    final saved = await _db.getLicense();

    if (saved == null) {
      return const LicenseResult(
        LicenseState.needsActivation,
        'يرجى إدخال رمز التفعيل',
      );
    }

    final token = saved['license_token']?.toString() ?? '';

    if (!RegExp(r'^[a-f0-9]{48}$').hasMatch(token)) {
      return const LicenseResult(
        LicenseState.invalid,
        'بيانات الترخيص المحلية غير صحيحة',
      );
    }

    try {
      return await _verifyOnline(token);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const LicenseResult(
          LicenseState.verificationRequired,
          'تعذر الوصول إلى الترخيص. تحقق من إعدادات الصلاحيات',
        );
      }

      return _checkOffline(saved);
    } catch (_) {
      return _checkOffline(saved);
    }
  }

  // التحقق من Firebase
  Future<LicenseResult> _verifyOnline(String token) async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }

    final snapshot = await _firebase
        .ref()
        .child('licenses')
        .child(token)
        .get();

    if (!snapshot.exists || snapshot.value == null) {
      return const LicenseResult(
        LicenseState.invalid,
        'رمز التفعيل غير موجود',
      );
    }

    final raw = snapshot.value;

    if (raw is! Map) {
      return const LicenseResult(
        LicenseState.invalid,
        'بيانات الترخيص غير صحيحة',
      );
    }

    final license = Map<String, dynamic>.from(raw);

    final ownerId = license['owner_id']?.toString() ?? '';
    final status = license['status']?.toString() ?? '';
    final expiryText = license['expiry_date']?.toString() ?? '';

    if (ownerId.isEmpty || expiryText.isEmpty) {
      return const LicenseResult(
        LicenseState.invalid,
        'بيانات الترخيص ناقصة',
      );
    }

    // إذا أوقف المدير الاشتراك
    if (status != 'active') {
      await _saveLocal(
        ownerId: ownerId,
        token: token,
        expiry: expiryText,
        status: status,
      );

      return const LicenseResult(
        LicenseState.suspended,
        'تم إيقاف هذا الاشتراك',
      );
    }

    final expiry = DateTime.tryParse(expiryText);

    if (expiry == null) {
      return const LicenseResult(
        LicenseState.invalid,
        'تاريخ انتهاء الاشتراك غير صحيح',
      );
    }

    final now = DateTime.now();

    final expiryEnd = DateTime(
      expiry.year,
      expiry.month,
      expiry.day,
      23,
      59,
      59,
    );

    final finalAllowedDate =
        expiryEnd.add(const Duration(days: graceDays));

    // انتهى الاشتراك وفترة السماح
    if (now.isAfter(finalAllowedDate)) {
      await _saveLocal(
        ownerId: ownerId,
        token: token,
        expiry: expiryText,
        status: 'active',
      );

      return const LicenseResult(
        LicenseState.expired,
        'انتهى الاشتراك. يرجى تجديده',
      );
    }

    // حفظ الترخيص محلياً
    await _saveLocal(
      ownerId: ownerId,
      token: token,
      expiry: expiryText,
      status: 'active',
    );

    // فترة السماح
    if (now.isAfter(expiryEnd)) {
      return const LicenseResult(
        LicenseState.gracePeriod,
        'أنت في فترة السماح. يرجى تجديد الاشتراك',
      );
    }

    return const LicenseResult(
      LicenseState.active,
      'الاشتراك فعال',
    );
  }

  // حفظ الترخيص محلياً
  Future<void> _saveLocal({
    required String ownerId,
    required String token,
    required String expiry,
    required String status,
  }) async {
    await _db.saveLicense({
      'owner_id': ownerId,
      'license_token': token,
      'expiry_date': expiry,
      'last_verified_at': DateTime.now().toIso8601String(),
      'status': status,
    });
  }

  // العمل عند انقطاع الإنترنت
  LicenseResult _checkOffline(Map<String, dynamic> saved) {
    final status = saved['status']?.toString() ?? '';

    if (status != 'active') {
      return const LicenseResult(
        LicenseState.suspended,
        'الاشتراك غير فعال',
      );
    }

    final expiry = DateTime.tryParse(
      saved['expiry_date']?.toString() ?? '',
    );

    final lastVerified = DateTime.tryParse(
      saved['last_verified_at']?.toString() ?? '',
    );

    if (expiry == null || lastVerified == null) {
      return const LicenseResult(
        LicenseState.invalid,
        'بيانات الترخيص المحلية غير مكتملة',
      );
    }

    final now = DateTime.now();

    final expiryEnd = DateTime(
      expiry.year,
      expiry.month,
      expiry.day,
      23,
      59,
      59,
    );

    final finalAllowedDate =
        expiryEnd.add(const Duration(days: graceDays));

    if (now.isAfter(finalAllowedDate)) {
      return const LicenseResult(
        LicenseState.expired,
        'انتهت صلاحية الاشتراك',
      );
    }

    final offlineLimit =
        lastVerified.add(const Duration(days: graceDays));

    if (now.isAfter(offlineLimit)) {
      return const LicenseResult(
        LicenseState.verificationRequired,
        'يجب الاتصال بالإنترنت للتحقق من الاشتراك',
      );
    }

    if (now.isAfter(expiryEnd)) {
      return const LicenseResult(
        LicenseState.gracePeriod,
        'التطبيق يعمل خلال فترة السماح دون إنترنت',
      );
    }

    return const LicenseResult(
      LicenseState.active,
      'الاشتراك فعال - يعمل دون إنترنت',
    );
  }
}
