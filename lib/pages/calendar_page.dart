import 'package:flutter/material.dart';
import 'package:lijsttedoen/models/todo_model.dart';
import 'package:lijsttedoen/theme/neo_brutalism_theme.dart';
import 'package:lijsttedoen/widgets/neo_brutalism_widgets.dart';

class CalendarPage extends StatefulWidget {
  final List<TodoModel> todos;
  final String userName;
  final String avatarType;
  final Function(TodoModel) onToggleTodo;

  const CalendarPage({
    super.key,
    required this.todos,
    required this.userName,
    required this.avatarType,
    required this.onToggleTodo,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  final List<String> _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _selectedDate = DateTime.now();
  }

  // Menghitung hari-hari dalam bulan yang sedang fokus
  List<DateTime?> _generateCalendarDays() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    // Cari hari dalam seminggu untuk hari pertama bulan (Monday = 1, Sunday = 7)
    // Ubah agar hari senin berada di index 0, dst.
    int firstWeekday = firstDayOfMonth.weekday; // 1 = Senin, 7 = Minggu
    int leadingEmptySpaces = firstWeekday - 1;

    final List<DateTime?> days = [];
    
    // Ruang kosong untuk hari sebelum tanggal 1
    for (int i = 0; i < leadingEmptySpaces; i++) {
      days.add(null);
    }

    // Hari dari tanggal 1 sampai akhir bulan
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      days.add(DateTime(_focusedMonth.year, _focusedMonth.month, i));
    }

    return days;
  }

  // Cek apakah tanggal memiliki tugas
  bool _dateHasTasks(DateTime date) {
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return widget.todos.any((t) => (t.isDeadline ? t.deadlineDate : t.dueDate) == dateStr);
  }

  @override
  Widget build(BuildContext context) {
    final days = _generateCalendarDays();
    final activeCount = widget.todos.where((t) => !t.isDone).length;
    
    // Ambil daftar tugas untuk tanggal terpilih
    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final displayedTodos = widget.todos.where((t) => (t.isDeadline ? t.deadlineDate : t.dueDate) == dateStr).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrutalGrid(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header Profil (Sama dengan Tasks & Stats)
                NeoBrutalismCard(
                  backgroundColor: NeoBrutalismTheme.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      BrutalAvatar(
                        avatarType: widget.avatarType,
                        userName: widget.userName,
                        size: 48,
                      ),
                      const SizedBox(width: 12),
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
                const SizedBox(height: 20),

                // 2. Main Calendar Container (October 2023 Style)
                NeoBrutalismCard(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bulan & Navigasi Chevrons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${_months[_focusedMonth.month - 1]} ${_focusedMonth.year}",
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                                  });
                                },
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: NeoBrutalismTheme.outline, width: 2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.chevron_left, size: 20),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                                  });
                                },
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: NeoBrutalismTheme.outline, width: 2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.chevron_right, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Nama Hari (M, T, W, T, F, S, S)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: _weekdays.map((day) {
                          return Expanded(
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: NeoBrutalismTheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Grid Angka Tanggal
                      Builder(
                        builder: (context) {
                          final double screenWidth = MediaQuery.of(context).size.width;
                          final double calendarWidth = screenWidth - 64.0;
                          final double cellHeight = calendarWidth / 7;
                          final int rows = (days.length / 7).ceil();
                          final double gridHeight = rows * cellHeight + (rows - 1) * 8.0 + 16.0;
                          return SizedBox(
                            height: gridHeight,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: days.length,
                              itemBuilder: (context, index) {
                                final dayDate = days[index];
                                if (dayDate == null) {
                                  return const SizedBox.shrink();
                                }

                                final isSelected = _selectedDate.year == dayDate.year &&
                                    _selectedDate.month == dayDate.month &&
                                    _selectedDate.day == dayDate.day;

                                final hasTasks = _dateHasTasks(dayDate);

                                final now = DateTime.now();
                                final isToday = now.year == dayDate.year &&
                                    now.month == dayDate.month &&
                                    now.day == dayDate.day;

                                Widget cellChild = Center(
                                  child: Text(
                                    "${dayDate.day}",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected || isToday ? FontWeight.w900 : FontWeight.w600,
                                      color: isSelected
                                          ? NeoBrutalismTheme.onSurface
                                          : isToday
                                              ? Colors.deepPurple[700]
                                              : NeoBrutalismTheme.onSurface,
                                    ),
                                  ),
                                );

                                if (isSelected) {
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {},
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: NeoBrutalismTheme.outline,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Transform.translate(
                                        offset: const Offset(-2, -2),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: NeoBrutalismTheme.primaryContainer, // Yellow
                                            border: Border.all(color: NeoBrutalismTheme.outline, width: 2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: cellChild,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    setState(() {
                                      _selectedDate = dayDate;
                                    });
                                  },
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (isToday)
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.deepPurple.withValues(alpha: 0.3),
                                              width: 1.5,
                                              style: BorderStyle.solid,
                                            ),
                                          ),
                                        ),
                                      cellChild,
                                      if (hasTasks)
                                        Positioned(
                                          bottom: 4,
                                          child: Container(
                                            width: 5,
                                            height: 5,
                                            decoration: const BoxDecoration(
                                              color: NeoBrutalismTheme.outline,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      ),

                      // Divider Pemisah Tebal
                      const Divider(
                        color: NeoBrutalismTheme.outline,
                        thickness: 3.5,
                        height: 24,
                      ),

                      // 3. Section Tasks for today
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Tasks for today",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 12),
                          displayedTodos.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                                    child: Text(
                                      "Tidak ada tugas dijadwalkan hari ini.",
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: NeoBrutalismTheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: displayedTodos.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final todo = displayedTodos[index];
                                    final labelColor = todo.category == 'Work'
                                        ? NeoBrutalismTheme.primaryContainer
                                        : todo.category == 'Personal'
                                            ? NeoBrutalismTheme.secondaryContainer
                                            : NeoBrutalismTheme.tertiaryContainer;

                                    final labelText = todo.category.toUpperCase();

                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: NeoBrutalismTheme.outline, width: 2.5),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: NeoBrutalismTheme.outline,
                                            offset: Offset(3, 3),
                                            blurRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          NeoCheckbox(
                                            value: todo.isDone,
                                            onChanged: (_) => widget.onToggleTodo(todo),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  todo.title,
                                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                        fontWeight: FontWeight.w800,
                                                        decoration: todo.isDone
                                                            ? TextDecoration.lineThrough
                                                            : null,
                                                        color: todo.isDone
                                                            ? Colors.grey[500]
                                                            : NeoBrutalismTheme.onSurface,
                                                      ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (todo.isDeadline) ...[
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.warning_amber_rounded,
                                                        size: 11,
                                                        color: NeoBrutalismTheme.error,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: labelColor,
                                              border: Border.all(color: NeoBrutalismTheme.outline, width: 1.5),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              labelText,
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 9,
                                                    color: NeoBrutalismTheme.onSurface,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
