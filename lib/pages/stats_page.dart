import 'package:flutter/material.dart';
import 'package:lijsttedoen/models/todo_model.dart';
import 'package:lijsttedoen/theme/neo_brutalism_theme.dart';
import 'package:lijsttedoen/widgets/neo_brutalism_widgets.dart';

class ProductivityBadgeStyle {
  final String title;
  final String description;
  final Color backgroundColor;
  final IconData icon;

  const ProductivityBadgeStyle({
    required this.title,
    required this.description,
    required this.backgroundColor,
    required this.icon,
  });
}

class StatsPage extends StatefulWidget {
  final List<TodoModel> todos;
  final String userName;
  final String avatarType;

  const StatsPage({
    super.key,
    required this.todos,
    required this.userName,
    required this.avatarType,
  });

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String _selectedPeriod = "Weekly"; // "Weekly", "Monthly", "Year"

  // Selector Gaya Dinamis untuk Banner Produktivitas berdasarkan completionPct
  ProductivityBadgeStyle _getBadgeStyle(
    int pct,
    int total,
    String periodLabel,
    int activeCount,
  ) {
    if (total == 0) {
      return const ProductivityBadgeStyle(
        title: "RENCANAKAN HARIMU!",
        description:
            "Belum ada tugas yang dibuat untuk periode ini. Ayo tambahkan tugas barumu!",
        backgroundColor: Colors.white,
        icon: Icons.edit_note_outlined,
      );
    }
    if (pct == 100) {
      return ProductivityBadgeStyle(
        title: "GG!",
        description:
            "Sak Joss euy! Semua tugas $periodLabel ini telah diselesaikan tanpa sisa. MANTAPPP!",
        backgroundColor: const Color(
          0xFFC3C7FF,
        ), // Custom Neon Purple/Indigo Brutalist
        icon: Icons.emoji_events_outlined,
      );
    }
    if (pct >= 75) {
      return ProductivityBadgeStyle(
        title: "JOS JISS!",
        description:
            "Mantapp! Mayoritas tugasmu telah rampung. Tinggal $activeCount tugas lagi! HABISKANN!",
        backgroundColor: NeoBrutalismTheme.tertiaryContainer, // Lively Green
        icon: Icons.rocket_launch_outlined,
      );
    }
    if (pct >= 40) {
      return ProductivityBadgeStyle(
        title: "NOT BAD, LANJOTTTTT!",
        description:
            "Progres lumayan! Teruskan momentum ini untuk menyelesaikan $activeCount tugas tersisa.",
        backgroundColor: NeoBrutalismTheme.primaryContainer, // Vibrant Yellow
        icon: Icons.trending_up_outlined,
      );
    }
    return ProductivityBadgeStyle(
      title: "AYO BROO!",
      description:
          "Awal-awal pancen kepekso, soyo suwi dadi kulino, tembe mburine dadi wong MULYO!!",
      backgroundColor: NeoBrutalismTheme.errorContainer, // Vibrant Pink
      icon: Icons.directions_run_outlined,
    );
  }

  // Helper untuk menentukan apakah suatu todo berstatus telat/melewati deadline/due time
  bool _isOverdue(TodoModel t) {
    if (t.isDone) {
      return false; // Sudah selesai tidak dianggap telat dalam rasio
    }

    final String targetDateStr = t.isDeadline
        ? (t.deadlineDate ?? t.dueDate)
        : t.dueDate;

    final String targetTimeStr = t.isDeadline
        ? (t.deadlineTime ?? t.dueTime)
        : t.dueTime;

    try {
      final List<String> dateParts = targetDateStr.split('-');
      final List<String> timeParts = targetTimeStr.split(':');

      final int year = int.parse(dateParts[0]);
      final int month = int.parse(dateParts[1]);
      final int day = int.parse(dateParts[2]);

      final int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);

      final DateTime targetDateTime = DateTime(year, month, day, hour, minute);

      return targetDateTime.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  // Menyaring tugas sesuai periode pilihan (Weekly/Monthly/Year)
  List<TodoModel> _getFilteredTodos() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Batas Mingguan (Senin sampai Minggu pada minggu ini)
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return widget.todos.where((t) {
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
  }

  // Tombol pilihan periode Neo-Brutalist
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
                  ? (period == 'Weekly'
                        ? NeoBrutalismTheme.primaryContainer // Yellow
                        : period == 'Monthly'
                        ? NeoBrutalismTheme.secondaryContainer // Cyan
                        : NeoBrutalismTheme.tertiaryContainer) // Green
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
                  fontSize: 12,
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
    final periodTodos = _getFilteredTodos();
    final total = periodTodos.length;
    final doneCount = periodTodos.where((t) => t.isDone).length;
    final activeCount = total - doneCount;

    // Menghitung jumlah sukses berdasarkan aturan: dianggap sukses jika tidak melewati deadline
    final overdueCount = periodTodos.where((t) => _isOverdue(t)).length;
    final suksesCount = total - overdueCount;

    final double completionRatio = total == 0 ? 0.0 : (doneCount / total);
    final int completionPct = (completionRatio * 100).round();

    final double successRatio = total == 0 ? 0.0 : (suksesCount / total);
    final int successPct = (successRatio * 100).round();

    // Perhitungan distribusi kategori untuk Category Focus
    final double workPct = total == 0
        ? 0.0
        : (periodTodos.where((t) => t.category == 'Work').length / total);
    final double personalPct = total == 0
        ? 0.0
        : (periodTodos.where((t) => t.category == 'Personal').length / total);
    final double studyPct = total == 0
        ? 0.0
        : (periodTodos.where((t) => t.category == 'Study').length / total);

    final String periodLabel = _selectedPeriod == 'Weekly'
        ? 'minggu'
        : _selectedPeriod == 'Monthly'
        ? 'bulan'
        : _selectedPeriod == 'Year'
        ? 'tahun'
        : 'keseluruhan';

    final badgeStyle = _getBadgeStyle(
      completionPct,
      total,
      periodLabel,
      activeCount,
    );

    // Detail sisa tugas riil secara dinamis (menggantikan persentase simulasi growth)
    final String offsetText = total == 0
        ? ''
        : activeCount == 0
        ? "Semua tugas $periodLabel ini telah diselesaikan!"
        : "Tersisa $activeCount tugas lagi untuk $periodLabel ini.";

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BrutalGrid(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header Profil Neo-Brutalist (Sama dengan Tasks & Calendar)
                NeoBrutalismCard(
                  backgroundColor: NeoBrutalismTheme.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
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
                              periodTodos.isEmpty
                                  ? "0 tasks left"
                                  : "$activeCount tasks left",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                    height: 1.1,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: NeoBrutalismTheme
                                    .tertiaryContainer, // Lively Green
                                border: Border.all(
                                  color: NeoBrutalismTheme.outline,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "@${widget.userName}",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
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
                const SizedBox(height: 16),

                // 1.5. Period Filter Selector (Segmented Button Row)
                Row(
                  children: [
                    Expanded(child: _buildPeriodButton("Weekly")),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPeriodButton("Monthly")),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPeriodButton("Year")),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Productivity Rocket Banner (Sesuai Stitch stats.html)
                NeoBrutalismCard(
                  backgroundColor: badgeStyle.backgroundColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 18.0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: NeoBrutalismTheme.outline,
                            width: 2.5,
                          ),
                        ),
                        child: Icon(
                          badgeStyle.icon,
                          size: 32,
                          color: NeoBrutalismTheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              badgeStyle.title,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: NeoBrutalismTheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              badgeStyle.description,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: NeoBrutalismTheme.onSurface
                                        .withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Completion Card (Weekly/Monthly/Year Completion Sesuai Stitch)
                NeoBrutalismCard(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "$_selectedPeriod Completion",
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                  color: NeoBrutalismTheme.onSurface,
                                ),
                          ),
                          Text(
                            "$completionPct%",
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: NeoBrutalismTheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Progress Bar Container dengan Fire Icon di ujung aktif (Sesuai Stitch)
                      Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: NeoBrutalismTheme.background,
                          border: Border.all(
                            color: NeoBrutalismTheme.outline,
                            width: 3.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: NeoBrutalismTheme.outline,
                              offset: Offset(4, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              // Active Progress Fill
                              FractionallySizedBox(
                                widthFactor: completionRatio.clamp(0.0, 1.0),
                                child: Container(
                                  color: NeoBrutalismTheme
                                      .primaryContainer, // Vibrant Yellow
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 8),
                                  child: completionPct > 12
                                      ? const Icon(
                                          Icons
                                              .whatshot, // Fire Icon sesuai Stitch
                                          size: 16,
                                          color: NeoBrutalismTheme.onSurface,
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (offsetText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        // Offset status perkembangan (Sesuai Stitch)
                        Text(
                          offsetText,
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: NeoBrutalismTheme.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Key Metrics Grid - TIGA CARD SUSUN (Sesuai Stitch stats.html, Tersinkronisasi Sempurna)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // A. Kiri: Total Tasks (2-Span Height Card - Cyan)
                      Expanded(
                        child: NeoBrutalismCard(
                          backgroundColor: NeoBrutalismTheme
                              .secondaryContainer, // Vibrant Cyan
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "TOTAL\nTASKS",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                          height: 1.1,
                                        ),
                                  ),

                                  // White Circle Badge Assignment Icon (Sesuai Stitch)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: NeoBrutalismTheme.outline,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: NeoBrutalismTheme.outline,
                                          offset: Offset(2, 2),
                                          blurRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.assignment_outlined,
                                      size: 14,
                                      color: NeoBrutalismTheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // Large Number Align Bottom-Right
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  "$total",
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 44,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // B. Kanan: Done Card & Left Card (Vertically Stacked, Center Aligned dengan total tasks)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 1. Done Card (Neon Green)
                            NeoBrutalismCard(
                              backgroundColor: NeoBrutalismTheme
                                  .tertiaryContainer, // Lively Green
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14.0,
                                vertical: 12.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "DONE",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                        ),
                                  ),
                                  Text(
                                    "$doneCount",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // 2. Left Card (Pink/Light Red)
                            NeoBrutalismCard(
                              backgroundColor: NeoBrutalismTheme
                                  .errorContainer, // Pink/Light Red
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14.0,
                                vertical: 12.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "LEFT",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                        ),
                                  ),
                                  Text(
                                    "$activeCount",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Kartu Total Rasio Penyelesaian (Pink - Full Width)
                NeoBrutalismCard(
                  backgroundColor: NeoBrutalismTheme.errorContainer, // Pink
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.query_stats_rounded,
                                size: 28,
                                color: NeoBrutalismTheme.onSurface,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Rasio Sukses",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: NeoBrutalismTheme.outline, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "$successPct% Sukses",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: NeoBrutalismTheme.onSurface,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 2.5,
                        color: NeoBrutalismTheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: NeoBrutalismTheme.outline, width: 2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: NeoBrutalismTheme.tertiaryContainer, // Green
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Tepat Waktu",
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                fontWeight: FontWeight.w900,
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                        Text(
                                          "$doneCount Tugas",
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: NeoBrutalismTheme.outline, width: 2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: overdueCount > 0 
                                        ? NeoBrutalismTheme.error 
                                        : NeoBrutalismTheme.onSurface.withValues(alpha: 0.5),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Lewat Deadline",
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                fontWeight: FontWeight.w900,
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                        Text(
                                          "$overdueCount Tugas",
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Category Focus Card (Sesuai Stitch stats.html)
                NeoBrutalismCard(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "CATEGORY FOCUS",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              fontFamily: 'Bricolage Grotesque',
                            ),
                      ),
                      const SizedBox(height: 4),
                      Container(height: 4, color: NeoBrutalismTheme.outline),
                      const SizedBox(height: 16),

                      // Work Category
                      _buildCategoryFocusRow(
                        context,
                        title: "Work",
                        icon: Icons.work,
                        containerColor:
                            NeoBrutalismTheme.primaryContainer, // Yellow
                        percentage: workPct,
                      ),
                      const SizedBox(height: 14),

                      // Personal Category
                      _buildCategoryFocusRow(
                        context,
                        title: "Personal",
                        icon: Icons.person,
                        containerColor:
                            NeoBrutalismTheme.secondaryContainer, // Cyan
                        percentage: personalPct,
                      ),
                      const SizedBox(height: 14),

                      // Study Category
                      _buildCategoryFocusRow(
                        context,
                        title: "Study",
                        icon: Icons.school,
                        containerColor:
                            NeoBrutalismTheme.tertiaryContainer, // Green
                        percentage: studyPct,
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

  Widget _buildCategoryFocusRow(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color containerColor,
    required double percentage,
  }) {
    final int pctInt = (percentage * 100).round();
    return Row(
      children: [
        // Icon Square
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: containerColor,
            border: Border.all(color: NeoBrutalismTheme.outline, width: 2.5),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: NeoBrutalismTheme.outline,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Icon(icon, color: NeoBrutalismTheme.onSurface, size: 24),
        ),
        const SizedBox(width: 14),

        // Progress Info & Progress Bar
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: NeoBrutalismTheme.onSurface,
                    ),
                  ),
                  Text(
                    "$pctInt%",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: NeoBrutalismTheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Neo Brutalist Progress Bar
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(
                    color: NeoBrutalismTheme.outline,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: [
                      if (percentage > 0)
                        Expanded(
                          flex: (percentage * 100).round(),
                          child: Container(
                            color: containerColor,
                            height: double.infinity,
                          ),
                        ),
                      if (1 - percentage > 0)
                        Expanded(
                          flex: ((1 - percentage) * 100).round(),
                          child: const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
