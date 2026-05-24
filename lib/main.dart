import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:lijsttedoen/models/todo_model.dart';
import 'package:lijsttedoen/theme/neo_brutalism_theme.dart';
import 'package:lijsttedoen/pages/tasks_page.dart';
import 'package:lijsttedoen/pages/calendar_page.dart';
import 'package:lijsttedoen/pages/stats_page.dart';
import 'package:lijsttedoen/pages/settings_page.dart';
import 'package:lijsttedoen/widgets/neo_brutalism_widgets.dart';
import 'package:lijsttedoen/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint("Failed to initialize NotificationService: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Lijsttedoen",
      theme: NeoBrutalismTheme.themeData,
      debugShowCheckedModeBanner: false,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  List<TodoModel> _todos = [];
  String _userName = "Pengguna";
  String _avatarType = "initial"; // Pilihan avatar global: initial, face, pets, bunny
  bool _isLoading = true;

  // Data Dummy Awal (FR-01)
  final List<TodoModel> _dummyTodos = [
    TodoModel(
      id: 1,
      title: 'Desain UI Neo-Brutalism',
      description: 'Terapkan stroke 4px solid dan hard shadow tebal',
      isDone: true,
      dueTime: '08:00',
      category: 'Work',
    ),
    TodoModel(
      id: 2,
      title: 'Integrasi SharedPreferences',
      description: 'Simpan status tugas secara dinamis ke penyimpanan lokal',
      isDone: false,
      dueTime: '12:00',
      category: 'Study',
    ),
    TodoModel(
      id: 3,
      title: 'Uji coba fungsionalitas CRUD',
      description: 'Pastikan tambah, edit, hapus, dan ceklis berfungsi lancar',
      isDone: false,
      dueTime: '14:00',
      category: 'Personal',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAppState();
  }

  // Load data dari SharedPreferences (FR-02)
  Future<void> _loadAppState() async {
    final prefs = await SharedPreferences.getInstance();
    final String? todosJson = prefs.getString('todos_list');
    final String? name = prefs.getString('user_name');
    final String? avatar = prefs.getString('user_avatar');

    setState(() {
      _userName = name ?? "Pengguna";
      _avatarType = avatar ?? "initial";

      if (todosJson != null) {
        final List<dynamic> decoded = json.decode(todosJson);
        _todos = decoded.map((item) => TodoModel.fromMap(item)).toList();
      } else {
        // Jika data kosong, gunakan data dummy bawaan
        _todos = List.from(_dummyTodos);
        _saveTodos();
      }
      _isLoading = false;
    });
  }

  // Simpan data Todos ke SharedPreferences (FR-02)
  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> todosMap =
        _todos.map((todo) => todo.toMap()).toList();
    final String encoded = json.encode(todosMap);
    await prefs.setString('todos_list', encoded);
  }

  // Tambah Todo baru (FR-03)
  void _addTodo(String title, String description, String dueTime, String dueDate, String category, bool isDeadline, String? deadlineDate, String? deadlineTime) {
    final int newId = _todos.isNotEmpty ? _todos.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1 : 1;
    final newTodo = TodoModel(
      id: newId,
      title: title,
      description: description,
      dueTime: dueTime,
      dueDate: dueDate,
      category: category,
      isDeadline: isDeadline,
      deadlineDate: deadlineDate,
      deadlineTime: deadlineTime,
    );

    setState(() {
      _todos.add(newTodo);
    });
    _saveTodos();
    
    // Jadwalkan pengingat notifikasi untuk tugas baru
    NotificationService.scheduleTodoReminder(newTodo);
  }

  // Toggle status Todo (FR-03 & FR-04)
  void _toggleTodo(TodoModel todo) {
    setState(() {
      todo.isDone = !todo.isDone;
    });
    _saveTodos();

    // Jika selesai, batalkan notifikasinya. Jika belum, jadwalkan pengingat kembali.
    if (todo.isDone) {
      NotificationService.cancelTodoReminder(todo.id);
    } else {
      NotificationService.scheduleTodoReminder(todo);
    }
  }

  // Edit/Update Todo (FR-03)
  void _editTodo(TodoModel todo, String title, String description, String dueTime, String dueDate, String category, bool isDeadline, String? deadlineDate, String? deadlineTime) {
    setState(() {
      todo.title = title;
      todo.description = description;
      todo.dueTime = dueTime;
      todo.dueDate = dueDate;
      todo.category = category;
      todo.isDeadline = isDeadline;
      todo.deadlineDate = deadlineDate;
      todo.deadlineTime = deadlineTime;
    });
    _saveTodos();

    // Jadwalkan ulang notifikasi dengan waktu baru (jika belum selesai)
    if (todo.isDone) {
      NotificationService.cancelTodoReminder(todo.id);
    } else {
      NotificationService.scheduleTodoReminder(todo);
    }
  }

  // Hapus/Delete Todo (FR-04)
  void _deleteTodo(TodoModel todo) {
    setState(() {
      _todos.removeWhere((t) => t.id == todo.id);
    });
    _saveTodos();

    // Batalkan notifikasi dari alarm lokal
    NotificationService.cancelTodoReminder(todo.id);
  }

  // Update profil nama (FR-10)
  Future<void> _updateUserName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = newName;
    });
    await prefs.setString('user_name', newName);
  }

  // Update profil avatar global
  Future<void> _updateAvatarType(String newType) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _avatarType = newType;
    });
    await prefs.setString('user_avatar', newType);
  }

  // Hapus semua data (FR-11 & FR-12)
  Future<void> _clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _todos.clear();
      _userName = "Pengguna";
      _avatarType = "initial";
    });
    await prefs.remove('todos_list');
    await prefs.remove('user_name');
    await prefs.remove('user_avatar');

    // Batalkan seluruh pengingat notifikasi yang dijadwalkan
    await NotificationService.cancelAllReminders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: NeoBrutalismCard(
            backgroundColor: NeoBrutalismTheme.errorContainer, // Pink
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: NeoBrutalismTheme.error),
                const SizedBox(width: 10),
                Text(
                  "Semua data lokal telah disetel ulang!",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: NeoBrutalismTheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          currentUserName: _userName,
          currentAvatarType: _avatarType,
          onSaveUserName: _updateUserName,
          onSaveAvatarType: _updateAvatarType,
          onResetData: _clearAllData,
          onRestoreData: _loadAppState,
        ),
      ),
    );
  }

  // Pilihan Halaman (FR-08)
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: NeoBrutalismTheme.outline,
          strokeWidth: 4,
        ),
      );
    }

    switch (_currentIndex) {
      case 0:
        return TasksPage(
          todos: _todos,
          userName: _userName,
          avatarType: _avatarType,
          onAddTodo: _addTodo,
          onToggleTodo: _toggleTodo,
          onEditTodo: _editTodo,
          onDeleteTodo: _deleteTodo,
          onSettingsPressed: _openSettings,
        );
      case 1:
        return CalendarPage(
          todos: _todos,
          userName: _userName,
          avatarType: _avatarType,
          onToggleTodo: _toggleTodo,
          onSettingsPressed: _openSettings,
        );
      case 2:
        return StatsPage(
          todos: _todos,
          userName: _userName,
          avatarType: _avatarType,
          onSettingsPressed: _openSettings,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Kustomisasi Tab Navigasi Neo-Brutalism (FR-08)
  Widget _buildBottomNavigationBar() {
    return NeoBrutalismBottomBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoBrutalismTheme.background, // Off-white
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
