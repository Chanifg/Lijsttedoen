import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/todo_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // SharedPreferences Keys
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyReminderOffset =
      'notifications_reminder_offset'; // dalam menit (0, 15, 60)
  static const String _keyDailyDigestEnabled = 'notifications_daily_digest';

  /// Cek apakah platform mendukung local notifications (Android, iOS, macOS)
  static bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  /// Inisialisasi Service Notifikasi
  static Future<void> init() async {
    if (!_isSupportedPlatform) return;

    // 1. Inisialisasi Zona Waktu Lokal
    tz.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
    } catch (_) {
      // Fallback jika gagal membaca timezone lokal
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }

    // 2. Setelan Platform Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // 3. Setelan Platform iOS/macOS (Darwin)
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 4. Lakukan Inisialisasi
    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Logika ketika notifikasi diklik (bisa dipasangkan handler navigasi)
      },
    );

    // 5. Jadwalkan Daily Digest jika aktif
    await syncDailyDigest();
  }

  /// Request Izin Notifikasi untuk Android 13+ dan iOS
  static Future<bool> requestPermissions() async {
    if (!_isSupportedPlatform) return false;
    // Request untuk Android (wajib Android 13+)
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }

    // Request untuk iOS (IOS)
    final IOSFlutterLocalNotificationsPlugin? iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosImplementation != null) {
      final bool? allowed = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return allowed ?? false;
    }

    return true;
  }

  // --- PREFERENSI & SETTING NOTIFIKASI ---

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, value);
    if (!value) {
      // Batalkan seluruh alarm terjadwal jika dinonaktifkan
      await cancelAllReminders();
    }
  }

  static Future<int> getReminderOffset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyReminderOffset) ?? 60; // Default 1 jam (60 menit)
  }

  static Future<void> setReminderOffset(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReminderOffset, minutes);
  }

  static Future<bool> isDailyDigestEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDailyDigestEnabled) ?? true;
  }

  static Future<void> setDailyDigestEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailyDigestEnabled, value);
    await syncDailyDigest();
  }

  // --- LOGIKA UTAMA ALARM & JADWAL NOTIFIKASI ---

  /// Sinkronisasi jadwal Daily Digest jam 08.00 pagi
  static Future<void> syncDailyDigest() async {
    if (!_isSupportedPlatform) return;
    await _notifications.cancel(id: 999); // Bersihkan sisa alarm daily digest

    if (!await isEnabled() || !await isDailyDigestEnabled()) return;

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      8,
      0,
    ); // Pukul 08:00

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id: 999, // ID Unik khusus Daily Digest
      title: '⚡ Rencana Agenda Hari Ini!',
      body:
          'Kamu memiliki tugas produktif yang menunggumu. Buka aplikasi untuk melihat!',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_digest_channel',
          'Daily Digest',
          channelDescription: 'Morning productivity summary notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Jadwalkan pengingat alarm untuk satu Tugas/Todo
  static Future<void> scheduleTodoReminder(TodoModel todo) async {
    if (!_isSupportedPlatform) return;
    // Hapus sisa jadwal notifikasi yang lama agar tidak duplikat
    await cancelTodoReminder(todo.id);

    if (!await isEnabled()) return;
    if (todo.isDone) return; // Tidak menjadwalkan jika tugas sudah selesai

    // 1. Tentukan tanggal pelaksanaan acuan
    // Prioritaskan deadlineDate jika opsi isDeadline aktif, selain itu dueDate
    final String targetDateStr = todo.isDeadline
        ? (todo.deadlineDate ?? todo.dueDate)
        : todo.dueDate;

    final String targetTimeStr = todo.isDeadline
        ? (todo.deadlineTime ?? todo.dueTime)
        : todo.dueTime;

    try {
      // 2. Parse Tanggal dan Waktu
      final List<String> dateParts = targetDateStr.split('-');
      final List<String> timeParts = targetTimeStr.split(':');

      final int year = int.parse(dateParts[0]);
      final int month = int.parse(dateParts[1]);
      final int day = int.parse(dateParts[2]);

      final int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);

      final DateTime targetDateTime = DateTime(year, month, day, hour, minute);

      // 3. Jadwalkan notifikasi TEPAT WAKTU (exact due time) jika berada di masa depan
      if (targetDateTime.isAfter(DateTime.now())) {
        final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
          targetDateTime,
          tz.local,
        );
        await _notifications.zonedSchedule(
          id: todo.id, // Gunakan ID asli langsung sebagai ID notifikasi unik
          title: todo.isDeadline
              ? '⚠️ Batas Deadline Tiba!'
              : '🔔 Waktu Tugas Tiba!',
          body: todo.isDeadline
              ? 'Waktu pengerjaan tugas "${todo.title}" telah habis sekarang!'
              : 'Saatnya mengerjakan tugas "${todo.title}" sekarang!',
          scheduledDate: scheduledDate,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'todo_reminders_channel',
              'Pengingat Tugas',
              channelDescription:
                  'Notifications for approaching todo items and deadlines',
              importance: Importance.max,
              priority: Priority.high,
              styleInformation: BigTextStyleInformation(
                todo.isDeadline
                    ? 'Batas waktu pengerjaan tugas "${todo.title}" telah habis!'
                    : 'Tugas "${todo.title}" dijadwalkan untuk dikerjakan sekarang!',
              ),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }

      // 4. Jadwalkan pra-pengingat dengan offset (15 mnt, 1 jam, dst) jika diaktifkan dan berada di masa depan
      final int offsetMin = await getReminderOffset();
      if (offsetMin > 0) {
        final DateTime triggerDateTime = targetDateTime.subtract(
          Duration(minutes: offsetMin),
        );
        if (triggerDateTime.isAfter(DateTime.now())) {
          final tz.TZDateTime scheduledReminderDate = tz.TZDateTime.from(
            triggerDateTime,
            tz.local,
          );
          await _notifications.zonedSchedule(
            id: todo.id + 10000, // ID Unik terpisah untuk pra-pengingat
            title: todo.isDeadline
                ? '⚠️ Deadline Mendekat!'
                : '🔔 Jadwal Tugas Mendekat!',
            body: todo.isDeadline
                ? 'Tugas "${todo.title}" harus selesai dalam $offsetMin menit lagi!'
                : 'Tugas "${todo.title}" akan dimulai dalam $offsetMin menit lagi!',
            scheduledDate: scheduledReminderDate,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                'todo_pre_reminders_channel',
                'Pra-Pengingat Tugas',
                channelDescription:
                    'Notifications for approaching todo items and deadlines (pre-reminders)',
                importance: Importance.max,
                priority: Priority.high,
                styleInformation: BigTextStyleInformation(
                  todo.isDeadline
                      ? 'Tugas "${todo.title}" memiliki batas deadline jam $targetTimeStr hari ini!'
                      : 'Tugas "${todo.title}" dijadwalkan untuk dikerjakan jam $targetTimeStr!',
                ),
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      }
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print("Error scheduling todo reminder for ID ${todo.id}: $e");
      // ignore: avoid_print
      print(stackTrace);
    }
  }

  /// Batalkan notifikasi untuk satu Tugas
  static Future<void> cancelTodoReminder(int todoId) async {
    if (!_isSupportedPlatform) return;
    await _notifications.cancel(id: todoId);
    await _notifications.cancel(id: todoId + 10000);
  }

  /// Batalkan seluruh alarm terjadwal (misal saat fitur dinonaktifkan)
  static Future<void> cancelAllReminders() async {
    if (!_isSupportedPlatform) return;
    await _notifications.cancelAll();
  }

  /// Tes Notifikasi Instan untuk pembuktian fungsionalitas
  static Future<void> testInstantNotification() async {
    if (!_isSupportedPlatform) return;
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'test_channel',
          'Tes Notifikasi',
          channelDescription: 'Channel for instant functional testing',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      id: 888,
      title: '🎉 Notifikasi Berfungsi!',
      body:
          'Pengingat Lijsttedoen Anda telah diatur dan diaktifkan dengan sempurna.',
      notificationDetails: details,
    );
  }
}
