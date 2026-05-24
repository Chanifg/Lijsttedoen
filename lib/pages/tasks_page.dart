import 'package:flutter/material.dart';
import 'package:lijsttedoen/models/todo_model.dart';
import 'package:lijsttedoen/theme/neo_brutalism_theme.dart';
import 'package:lijsttedoen/widgets/neo_brutalism_widgets.dart';
import 'package:lijsttedoen/pages/add_edit_dialog.dart';

class TasksPage extends StatefulWidget {
  final List<TodoModel> todos;
  final String userName;
  final String avatarType;
  final Function(String title, String description, String dueTime, String dueDate, String category, bool isDeadline, String? deadlineDate, String? deadlineTime) onAddTodo;
  final Function(TodoModel todo) onToggleTodo;
  final Function(TodoModel todo, String title, String description, String dueTime, String dueDate, String category, bool isDeadline, String? deadlineDate, String? deadlineTime) onEditTodo;
  final Function(TodoModel todo) onDeleteTodo;
  final VoidCallback onSettingsPressed;

  const TasksPage({
    super.key,
    required this.todos,
    required this.userName,
    required this.avatarType,
    required this.onAddTodo,
    required this.onToggleTodo,
    required this.onEditTodo,
    required this.onDeleteTodo,
    required this.onSettingsPressed,
  });

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedPeriod = "All"; // "All", "Weekly", "Monthly", "Year"

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TodoModel> _getFilteredTodos() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Batas Mingguan (Senin sampai Minggu pada minggu ini)
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final filtered = widget.todos.where((t) {
      // 1. Filter by search query
      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        final matchTitle = t.title.toLowerCase().contains(query);
        final matchDesc = t.description.toLowerCase().contains(query);
        if (!matchTitle && !matchDesc) {
          return false;
        }
      }

      // 2. Filter by period
      if (_selectedPeriod == "All") {
        return true;
      }

      String dateStr = t.isDeadline ? (t.deadlineDate ?? t.dueDate) : t.dueDate;
      try {
        final todoDate = DateTime.parse(dateStr);
        final todoDay = DateTime(todoDate.year, todoDate.month, todoDate.day);

        if (_selectedPeriod == "Weekly") {
          return todoDay.isAfter(
                startOfWeek.subtract(const Duration(seconds: 1)),
              ) &&
              todoDay.isBefore(endOfWeek.add(const Duration(days: 1)));
        } else if (_selectedPeriod == "Monthly") {
          return todoDay.year == today.year && todoDay.month == today.month;
        } else if (_selectedPeriod == "Year") {
          return todoDay.year == today.year;
        }
      } catch (_) {
        return true; // Fallback jika parsing gagal
      }
      return true;
    }).toList();

    // Urutkan tugas berdasarkan waktu tugas / deadlinenya
    filtered.sort((a, b) {
      final dateAStr = a.isDeadline ? (a.deadlineDate ?? a.dueDate) : a.dueDate;
      final timeAStr = a.isDeadline ? (a.deadlineTime ?? a.dueTime) : a.dueTime;
      final dateBStr = b.isDeadline ? (b.deadlineDate ?? b.dueDate) : b.dueDate;
      final timeBStr = b.isDeadline ? (b.deadlineTime ?? b.dueTime) : b.dueTime;

      DateTime dtA;
      DateTime dtB;
      try {
        dtA = DateTime.parse('$dateAStr $timeAStr');
      } catch (_) {
        try {
          dtA = DateTime.parse(dateAStr);
        } catch (_) {
          dtA = DateTime(1970);
        }
      }

      try {
        dtB = DateTime.parse('$dateBStr $timeBStr');
      } catch (_) {
        try {
          dtB = DateTime.parse(dateBStr);
        } catch (_) {
          dtB = DateTime(1970);
        }
      }

      return dtA.compareTo(dtB);
    });

    return filtered;
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? NeoBrutalismTheme.outline : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Transform.translate(
          offset: isSelected ? const Offset(0, 0) : const Offset(-2, -2),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? (period == 'All'
                      ? NeoBrutalismTheme.primaryContainer // Yellow
                      : period == 'Weekly'
                      ? NeoBrutalismTheme.secondaryContainer // Cyan
                      : period == 'Monthly'
                      ? NeoBrutalismTheme.tertiaryContainer // Green
                      : NeoBrutalismTheme.errorContainer) // Pink for Year
                  : Colors.white,
              border: Border.all(color: NeoBrutalismTheme.outline, width: 2.5),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? null
                  : const [
                      BoxShadow(
                        color: NeoBrutalismTheme.outline,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
            ),
            child: Center(
              child: Text(
                period.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: NeoBrutalismTheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTodos = _getFilteredTodos();
    final activeCount = filteredTodos.where((t) => !t.isDone).length;

    return Scaffold(
      backgroundColor: Colors.transparent, // Agar grid background terlihat
      body: BrutalGrid(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Card (Sesuai Visual Stitch)
                NeoBrutalismCard(
                  backgroundColor: NeoBrutalismTheme.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            // Profil Avatar Global
                            BrutalAvatar(
                              avatarType: widget.avatarType,
                              userName: widget.userName,
                              size: 48,
                            ),
                            const SizedBox(width: 12),
                            // Informasi Status Tugas & Username
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.todos.isEmpty
                                        ? "0 tasks left"
                                        : "$activeCount tasks left",
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                          height: 1.1,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: NeoBrutalismTheme.tertiaryContainer, // Lively Green
                                      border: Border.all(color: NeoBrutalismTheme.outline, width: 1.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "@${widget.userName}",
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: NeoBrutalismTheme.onSurface,
                                            fontSize: 11,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tombol Settings Cepat
                      GestureDetector(
                        onTap: widget.onSettingsPressed,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: NeoBrutalismTheme.outline,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Transform.translate(
                            offset: const Offset(-2, -2),
                            child: Container(
                              decoration: BoxDecoration(
                                color: NeoBrutalismTheme.secondaryContainer, // Cyan
                                border: Border.all(color: NeoBrutalismTheme.outline, width: 2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.settings_outlined,
                                size: 22,
                                color: NeoBrutalismTheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Bar Pencarian Neo-Brutalist Premium
                Container(
                  decoration: BoxDecoration(
                    color: NeoBrutalismTheme.outline,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Transform.translate(
                    offset: const Offset(-4, -4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: NeoBrutalismTheme.outline, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() {}),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, color: NeoBrutalismTheme.outline),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: NeoBrutalismTheme.outline),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          hintText: "Cari tugas...",
                          hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w600),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Filter Periode Neo-Brutalist
                Row(
                  children: [
                    Expanded(child: _buildPeriodButton("All")),
                    const SizedBox(width: 6),
                    Expanded(child: _buildPeriodButton("Weekly")),
                    const SizedBox(width: 6),
                    Expanded(child: _buildPeriodButton("Monthly")),
                    const SizedBox(width: 6),
                    Expanded(child: _buildPeriodButton("Year")),
                  ],
                ),
                const SizedBox(height: 16),

                // Daftar Tugas Harian (Scrollable)
                Expanded(
                  child: filteredTodos.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: NeoBrutalismCard(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: NeoBrutalismTheme.tertiaryContainer,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: NeoBrutalismTheme.outline, width: 3),
                                      ),
                                      child: Icon(
                                        _searchController.text.isNotEmpty || _selectedPeriod != "All"
                                            ? Icons.search_off
                                            : Icons.check_circle_outline,
                                        size: 40,
                                        color: NeoBrutalismTheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchController.text.isNotEmpty || _selectedPeriod != "All"
                                          ? "Tidak Ada Cocok"
                                          : "Tugas Bersih!",
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _searchController.text.isNotEmpty || _selectedPeriod != "All"
                                          ? "Coba ubah kata kunci pencarian atau bersihkan filter periode Anda."
                                          : "Tidak ada tugas tersisa untuk hari ini. Tambahkan tugas baru dengan tombol di bawah!",
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: NeoBrutalismTheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          clipBehavior: Clip.hardEdge, // Sembunyikan item saat di-scroll di bawah filter
                          padding: const EdgeInsets.fromLTRB(6, 8, 6, 100), // Ruang padding di dalam viewport agar bayangan kartu pertama tidak kepotong
                          itemCount: filteredTodos.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final todo = filteredTodos[index];

                            return NeoBrutalismCard(
                              margin: EdgeInsets.zero,
                              backgroundColor: todo.isDone
                                  ? NeoBrutalismTheme.surfaceContainerHigh
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Checkbox Brutalist
                                      NeoCheckbox(
                                        value: todo.isDone,
                                        onChanged: (_) => widget.onToggleTodo(todo),
                                      ),
                                      const SizedBox(width: 14),
                                      // Judul & Deskripsi Tugas
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              todo.title,
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.w900,
                                                    decoration: todo.isDone
                                                        ? TextDecoration.lineThrough
                                                        : null,
                                                    color: todo.isDone
                                                        ? Colors.grey[500]
                                                        : NeoBrutalismTheme.onSurface,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (todo.description.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                todo.description,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: todo.isDone
                                                          ? Colors.grey[400]
                                                          : NeoBrutalismTheme.onSurfaceVariant,
                                                      fontSize: 14,
                                                      decoration: todo.isDone
                                                          ? TextDecoration.lineThrough
                                                          : null,
                                                    ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Baris Tindakan & Jam (Berdasarkan Stitch UI)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Row containing Time/Date and Category badges
                                      Expanded(
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            if (todo.isDeadline) ...[
                                              // Badge Deadline (Pink/Red warning)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: todo.isDone
                                                      ? Colors.grey[300]
                                                      : NeoBrutalismTheme.errorContainer, // Pink
                                                  border: Border.all(color: NeoBrutalismTheme.outline, width: 2),
                                                  borderRadius: BorderRadius.circular(6),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: NeoBrutalismTheme.outline,
                                                      offset: Offset(2, 2),
                                                      blurRadius: 0,
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.warning_amber_rounded,
                                                      size: 14,
                                                      color: NeoBrutalismTheme.onSurface,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      todo.isDone ? "SELESAI" : "${todo.deadlineDate} • ${todo.deadlineTime ?? '12:00'}",
                                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                            fontWeight: FontWeight.w900,
                                                            color: NeoBrutalismTheme.onSurface,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ] else ...[
                                              // Badge Tanggal & Waktu (dueDate & dueTime)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: todo.isDone
                                                      ? Colors.grey[300]
                                                      : NeoBrutalismTheme.secondaryContainer,
                                                  border: Border.all(color: NeoBrutalismTheme.outline, width: 2),
                                                  borderRadius: BorderRadius.circular(6),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: NeoBrutalismTheme.outline,
                                                      offset: Offset(2, 2),
                                                      blurRadius: 0,
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.schedule,
                                                      size: 14,
                                                      color: NeoBrutalismTheme.onSurface,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      todo.isDone ? "Tadi" : "${todo.dueDate} • ${todo.dueTime}",
                                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                            fontWeight: FontWeight.w900,
                                                            color: NeoBrutalismTheme.onSurface,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            // Badge Kategori Kustom
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: todo.category == 'Work'
                                                    ? NeoBrutalismTheme.primaryContainer // Yellow
                                                    : todo.category == 'Personal'
                                                        ? NeoBrutalismTheme.secondaryContainer // Cyan
                                                        : NeoBrutalismTheme.tertiaryContainer, // Green
                                                border: Border.all(color: NeoBrutalismTheme.outline, width: 2),
                                                borderRadius: BorderRadius.circular(6),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: NeoBrutalismTheme.outline,
                                                    offset: Offset(2, 2),
                                                    blurRadius: 0,
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                todo.category.toUpperCase(),
                                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 10,
                                                      color: NeoBrutalismTheme.onSurface,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Tombol Edit & Hapus
                                      Row(
                                        children: [
                                          // Tombol EDIT Kuning Tebal (Stitch style)
                                          NeoBrutalismButton(
                                            backgroundColor: NeoBrutalismTheme.primaryContainer, // Yellow
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            radius: 8,
                                            onPressed: () async {
                                              final result = await showDialog<Map<String, String>>(
                                                context: context,
                                                builder: (context) => AddEditDialog(todo: todo),
                                              );
                                              if (result != null) {
                                                widget.onEditTodo(
                                                  todo,
                                                  result['title']!,
                                                  result['description']!,
                                                  result['dueTime']!,
                                                  result['dueDate']!,
                                                  result['category']!,
                                                  result['isDeadline'] == 'true',
                                                  result['deadlineDate'], result['deadlineTime'],
                                                );
                                              }
                                            },
                                            child: const Text(
                                              "EDIT",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 12,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Tombol Hapus (Neo Trash)
                                          GestureDetector(
                                            onTap: () => widget.onDeleteTodo(todo),
                                            child: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: NeoBrutalismTheme.outline,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Transform.translate(
                                                offset: const Offset(-2, -2),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: NeoBrutalismTheme.errorContainer, // Pink
                                                    border: Border.all(color: NeoBrutalismTheme.outline, width: 2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(
                                                    Icons.delete_outline,
                                                    size: 18,
                                                    color: NeoBrutalismTheme.error,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Floating Action Button Tambah Tugas Baru (Stitch circular FAB style)
      floatingActionButton: GestureDetector(
        onTap: () async {
          final result = await showDialog<Map<String, String>>(
            context: context,
            builder: (context) => const AddEditDialog(),
          );
          if (result != null) {
            widget.onAddTodo(
              result['title']!,
              result['description']!,
              result['dueTime']!,
              result['dueDate']!,
              result['category']!,
              result['isDeadline'] == 'true',
              result['deadlineDate'], result['deadlineTime'],
            );
          }
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: NeoBrutalismTheme.outline,
            shape: BoxShape.circle,
          ),
          child: Transform.translate(
            offset: const Offset(-4, -4),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: NeoBrutalismTheme.primaryContainer, // Yellow
                shape: BoxShape.circle,
                border: Border.all(color: NeoBrutalismTheme.outline, width: 3.5),
                boxShadow: const [
                  BoxShadow(
                    color: NeoBrutalismTheme.outline,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                size: 32,
                color: NeoBrutalismTheme.onSurface,
                weight: 900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
