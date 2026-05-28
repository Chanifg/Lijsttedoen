import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:isar/isar.dart';
import 'notification_service.dart';
import '../models/todo_model.dart';

class BackupService {
  /// Melakukan ekspor data ke file JSON dan memunculkan Share Sheet sistem
  static Future<bool> exportBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isar = Isar.getInstance();
      if (isar == null) return false;

      // 1. Ambil seluruh data dari Isar dan setelan dari SharedPreferences
      final todos = await isar.todoModels.where().findAll();
      final List<Map<String, dynamic>> todosMapList = todos.map((t) => t.toMap()).toList();
      final String todosListJson = json.encode(todosMapList);

      final String? userName = prefs.getString('user_name');
      final String? userAvatar = prefs.getString('user_avatar');
      final bool notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      final int reminderOffset = prefs.getInt('notifications_reminder_offset') ?? 60;
      final bool dailyDigestEnabled = prefs.getBool('notifications_daily_digest') ?? true;

      // 2. Susun dalam bentuk Map/JSON terstruktur
      final Map<String, dynamic> backupData = {
        'app': 'lijsttedoen',
        'version': 1,
        'backup_date': DateTime.now().toIso8601String(),
        'data': {
          'todos_list': todosListJson,
          'user_name': userName,
          'user_avatar': userAvatar,
          'notifications_enabled': notificationsEnabled,
          'notifications_reminder_offset': reminderOffset,
          'notifications_daily_digest': dailyDigestEnabled,
        }
      };

      final String jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // 3. Simpan sementara ke direktori temp menggunakan path_provider
      final tempDir = await getTemporaryDirectory();
      final String fileName = 'lijsttedoen_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final File backupFile = File('${tempDir.path}/$fileName');
      
      await backupFile.writeAsString(jsonString);

      // 4. Bagikan file menggunakan share_plus
      final params = ShareParams(
        files: [XFile(backupFile.path)],
        subject: 'Lijsttedoen Backup Data',
      );

      final result = await SharePlus.instance.share(params);

      // Di perangkat/emulator tertentu, status share tidak bisa dilacak dan mengembalikan 'unavailable'.
      // Selama dialog share berhasil dibuka, kita menganggap proses ekspor telah berhasil dipicu.
      return result.status == ShareResultStatus.success || 
             result.status == ShareResultStatus.dismissed ||
             result.status == ShareResultStatus.unavailable;
    } catch (e) {
      // ignore: avoid_print
      print("Error during exportBackup: $e");
      return false;
    }
  }

  /// Membuka file picker untuk mengimpor file JSON backup dan menyimpannya
  static Future<String?> importBackup() async {
    try {
      // 1. Buka File Picker untuk memilih file JSON
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Android custom extension pickers bisa bermasalah, FileType.any paling andal
      );

      if (result == null || result.files.isEmpty) {
        return 'Batal memilih file.'; // Batal oleh pengguna
      }

      final file = result.files.first;
      String? jsonContent;

      if (file.path != null) {
        final File selectedFile = File(file.path!);
        jsonContent = await selectedFile.readAsString();
      } else if (file.bytes != null) {
        jsonContent = utf8.decode(file.bytes!);
      }

      if (jsonContent == null || jsonContent.trim().isEmpty) {
        return 'File kosong atau tidak dapat dibaca.';
      }

      // 2. Decode dan Validasi struktur JSON
      Map<String, dynamic> backupMap;
      try {
        backupMap = json.decode(jsonContent) as Map<String, dynamic>;
      } catch (_) {
        return 'Format file tidak valid. File harus berupa teks berformat JSON.';
      }

      if (backupMap['app'] != 'lijsttedoen' || backupMap['data'] == null) {
        return 'File backup ini bukan berasal dari aplikasi Lijsttedoen.';
      }

      final Map<String, dynamic> data = backupMap['data'] as Map<String, dynamic>;

      // 3. Tulis data yang valid ke SharedPreferences & Isar
      final prefs = await SharedPreferences.getInstance();
      final isar = Isar.getInstance();
      if (isar == null) return 'Database tidak siap.';

      if (data['user_name'] != null) {
        await prefs.setString('user_name', data['user_name'] as String);
      }
      if (data['user_avatar'] != null) {
        await prefs.setString('user_avatar', data['user_avatar'] as String);
      }
      if (data['notifications_enabled'] != null) {
        await prefs.setBool('notifications_enabled', data['notifications_enabled'] as bool);
      }
      if (data['notifications_reminder_offset'] != null) {
        await prefs.setInt('notifications_reminder_offset', data['notifications_reminder_offset'] as int);
      }
      if (data['notifications_daily_digest'] != null) {
        await prefs.setBool('notifications_daily_digest', data['notifications_daily_digest'] as bool);
      }

      // Pastikan flag migrasi diset true dan bersihkan data lama SharedPreferences
      await prefs.setBool('migrated_to_isar', true);
      await prefs.remove('todos_list');

      // 4. Hapus data Isar saat ini dan masukkan data baru
      List<TodoModel> todos = [];
      if (data['todos_list'] != null) {
        final String todosJson = data['todos_list'] as String;
        final List<dynamic> decodedTodos = json.decode(todosJson);
        todos = decodedTodos.map((item) => TodoModel.fromMap(item)).toList();
      }

      await isar.writeTxn(() async {
        await isar.todoModels.clear();
        if (todos.isNotEmpty) {
          await isar.todoModels.putAll(todos);
        }
      });

      // 5. Jadwalkan ulang seluruh alarm notifikasi untuk data baru
      await NotificationService.cancelAllReminders();

      for (var todo in todos) {
        if (!todo.isDone) {
          await NotificationService.scheduleTodoReminder(todo);
        }
      }

      // 6. Sinkronisasi Daily Digest notifikasi
      await NotificationService.syncDailyDigest();

      return null; // Mengembalikan null jika sukses (tidak ada pesan error)
    } catch (e) {
      // ignore: avoid_print
      print("Error during importBackup: $e");
      return 'Terjadi kesalahan sistem: $e';
    }
  }
}
