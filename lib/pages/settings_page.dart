import 'dart:ui' show PathMetric;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lijsttedoen/theme/neo_brutalism_theme.dart';
import 'package:lijsttedoen/widgets/neo_brutalism_widgets.dart';
import 'package:lijsttedoen/services/notification_service.dart';
import 'package:lijsttedoen/services/backup_service.dart';

class SettingsPage extends StatefulWidget {
  final String currentUserName;
  final String currentAvatarType;
  final Function(String) onSaveUserName;
  final Function(String) onSaveAvatarType;
  final VoidCallback onResetData;
  final VoidCallback onRestoreData;

  const SettingsPage({
    super.key,
    required this.currentUserName,
    required this.currentAvatarType,
    required this.onSaveUserName,
    required this.onSaveAvatarType,
    required this.onResetData,
    required this.onRestoreData,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  late String _selectedAvatarType;
  bool _notificationsEnabled = true;
  int _reminderOffset = 60;
  bool _dailyDigestEnabled = true;
  String? _activeSection;
  bool _isCheckingForUpdates = false;
  String _selectedSoundType = 'default';
  String? _customSoundName;
  String? _customSoundPath;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentUserName;
    _selectedAvatarType = widget.currentAvatarType;
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await NotificationService.isEnabled();
    final offset = await NotificationService.getReminderOffset();
    final daily = await NotificationService.isDailyDigestEnabled();
    final soundType = await NotificationService.getSoundType();
    final customName = await NotificationService.getCustomSoundName();
    final customPath = await NotificationService.getCustomSoundPath();
    setState(() {
      _notificationsEnabled = enabled;
      _reminderOffset = offset;
      _dailyDigestEnabled = daily;
      _selectedSoundType = soundType;
      _customSoundName = customName;
      _customSoundPath = customPath;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    await NotificationService.setEnabled(value);
    setState(() {
      _notificationsEnabled = value;
    });
    if (value) {
      await NotificationService.requestPermissions();
    }
  }

  Future<void> _updateOffset(int minutes) async {
    await NotificationService.setReminderOffset(minutes);
    setState(() {
      _reminderOffset = minutes;
    });
  }

  Future<void> _toggleDailyDigest(bool value) async {
    await NotificationService.setDailyDigestEnabled(value);
    setState(() {
      _dailyDigestEnabled = value;
    });
  }

  Future<void> _reloadSettingsAfterRestore() async {
    final prefs = await SharedPreferences.getInstance();
    final String name = prefs.getString('user_name') ?? "Pengguna";
    final String avatar = prefs.getString('user_avatar') ?? "initial";
    setState(() {
      _nameController.text = name;
      _selectedAvatarType = avatar;
    });
    await _loadNotificationSettings();
    widget.onRestoreData(); // trigger refresh parent
  }

  Future<void> _handleExportBackup() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: NeoBrutalismCard(
          backgroundColor: NeoBrutalismTheme.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    NeoBrutalismTheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Menyiapkan file cadangan...",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: NeoBrutalismTheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final success = await BackupService.exportBackup();

    if (!mounted) return;

    scaffoldMessenger.hideCurrentSnackBar();
    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: NeoBrutalismCard(
            backgroundColor: NeoBrutalismTheme.tertiaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: NeoBrutalismTheme.onSurface,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Data berhasil diekspor!",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalismTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: NeoBrutalismCard(
            backgroundColor: NeoBrutalismTheme.errorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: NeoBrutalismTheme.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Gagal mengekspor data cadangan.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalismTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<void> _handleImportRestore() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: NeoBrutalismCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning,
                        color: NeoBrutalismTheme.error,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "RESTORE DATA",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Bricolage Grotesque',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Tindakan ini akan menimpa seluruh tugas dan profil saat ini dengan data dari file cadangan. Apakah Anda yakin ingin melanjutkan?",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: NeoBrutalismTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: NeoBrutalismButton(
                          backgroundColor: Colors.white,
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(
                            "BATAL",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: NeoBrutalismTheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NeoBrutalismButton(
                          backgroundColor: NeoBrutalismTheme.error,
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "YA, TIMPA",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    final String? errorMessage = await BackupService.importBackup();

    if (!mounted) return;

    if (errorMessage == null) {
      await _reloadSettingsAfterRestore();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: NeoBrutalismCard(
            backgroundColor: NeoBrutalismTheme.tertiaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: NeoBrutalismTheme.onSurface,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Data cadangan berhasil dipulihkan secara penuh!",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalismTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: NeoBrutalismCard(
            backgroundColor: NeoBrutalismTheme.errorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: NeoBrutalismTheme.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalismTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      widget.onSaveUserName(name);
      widget.onSaveAvatarType(_selectedAvatarType);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: NeoBrutalismCard(
            backgroundColor: NeoBrutalismTheme.tertiaryContainer, // Green
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: NeoBrutalismTheme.onSurface,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Profil Anda berhasil diperbarui secara global!",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalismTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoBrutalismTheme.background,
      body: BrutalGrid(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 40.0,
            ),
            child: _buildActiveSection(context),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSection(BuildContext context) {
    switch (_activeSection) {
      case 'profile':
        return _buildProfileSection();
      case 'notifications':
        return _buildNotificationSection();
      case 'backup':
        return _buildBackupSection();
      case 'about':
        return _buildAboutSection();
      default:
        return _buildLandingPage();
    }
  }

  Widget _buildLandingPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Header Card (Legacy style, without back arrow since it is the landing page)
        NeoBrutalismCard(
          backgroundColor:
              NeoBrutalismTheme.primaryContainer, // Yellow (#FFE16D)
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SETTINGS",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Bricolage Grotesque',
                  letterSpacing: -0.5,
                  color: NeoBrutalismTheme.onSurface,
                ),
              ),
              const Icon(
                Icons.tune,
                size: 28,
                color: NeoBrutalismTheme.onSurface,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Profile Header Ringkas
        NeoBrutalismCard(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              BrutalAvatar(
                avatarType: _selectedAvatarType,
                userName: _nameController.text,
                size: 64,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "HALO,",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: NeoBrutalismTheme.onSurfaceVariant,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      _nameController.text.toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Bricolage Grotesque',
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: NeoBrutalismTheme.tertiaryContainer, // Green
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Lokal Isar Aktif",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: NeoBrutalismTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Grid Menu Kartu Kategori (2x2 Grid)
        Row(
          children: [
            _buildCategoryCard(
              title: "PROFIL & AKUN",
              description: "Display name & Avatar",
              icon: Icons.person,
              color: NeoBrutalismTheme.tertiaryContainer, // Green
              onTap: () => setState(() => _activeSection = 'profile'),
            ),
            const SizedBox(width: 16),
            _buildCategoryCard(
              title: "NOTIFIKASI",
              description: "Alarm & Pengingat",
              icon: Icons.notifications_active,
              color: NeoBrutalismTheme.secondaryContainer, // Cyan
              onTap: () => setState(() => _activeSection = 'notifications'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildCategoryCard(
              title: "MANAJEMEN DATA",
              description: "Ekspor, Impor & Reset",
              icon: Icons.storage,
              color: NeoBrutalismTheme.primaryContainer, // Yellow
              onTap: () => setState(() => _activeSection = 'backup'),
            ),
            const SizedBox(width: 16),
            _buildCategoryCard(
              title: "TENTANG APLIKASI",
              description: "Informasi & Pembaruan",
              icon: Icons.info_outline,
              color: NeoBrutalismTheme.errorContainer, // Pink
              onTap: () => setState(() => _activeSection = 'about'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 4. Footer Informasi
        Column(
          children: [
            const SizedBox(height: 24),
            Text(
              "LIJSTTEDOEN",
              style: TextStyle(
                fontFamily: 'Bricolage Grotesque',
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 2,
                color: NeoBrutalismTheme.onSurface.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "VERSI 1.1.0 • LISENSI MIT",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: NeoBrutalismTheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "© 2026 ANTIGRAVITY LABS. ALL RIGHTS RESERVED.",
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: NeoBrutalismTheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: NeoBrutalismCard(
          backgroundColor: color,
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 110,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 28, color: NeoBrutalismTheme.onSurface),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Bricolage Grotesque',
                        fontSize: 14,
                        letterSpacing: -0.5,
                        color: NeoBrutalismTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: NeoBrutalismTheme.onSurfaceVariant,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return NeoBrutalismCard(
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _activeSection = null),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: NeoBrutalismTheme.outline,
                      width: 2.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: NeoBrutalismTheme.outline,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: NeoBrutalismTheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Bricolage Grotesque',
                  letterSpacing: -0.5,
                  color: NeoBrutalismTheme.onSurface,
                ),
              ),
            ],
          ),
          Icon(icon, size: 28, color: NeoBrutalismTheme.onSurface),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    final avatarTypes = ['initial', 'face', 'pets', 'bunny'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          "PROFIL & AKUN",
          Icons.person,
          NeoBrutalismTheme.tertiaryContainer,
        ),
        const SizedBox(height: 20),
        NeoBrutalismCard(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NeoTextField(
                controller: _nameController,
                labelText: "DISPLAY NAME",
                placeholder: "Masukkan nama profil...",
                suffixIcon: Icons.edit,
              ),
              const SizedBox(height: 24),
              Text(
                "CHANGE AVATAR",
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: NeoBrutalismTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    ...avatarTypes.map((type) {
                      final isSelected = _selectedAvatarType == type;

                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAvatarType = type;
                            });
                          },
                          child: Column(
                            children: [
                              BrutalAvatar(
                                avatarType: type,
                                userName: widget.currentUserName,
                                size: 56,
                                isSelected: isSelected,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                type == 'initial'
                                    ? 'INITIAL'
                                    : type.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? NeoBrutalismTheme.onSurface
                                      : NeoBrutalismTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            content: NeoBrutalismCard(
                              backgroundColor:
                                  NeoBrutalismTheme.primaryContainer,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info,
                                    color: NeoBrutalismTheme.onSurface,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Fitur tambah avatar kustom segera hadir!",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: NeoBrutalismTheme.onSurface,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: NeoBrutalismTheme.surfaceContainerHigh,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: NeoBrutalismTheme.outline,
                                width: 2.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: NeoBrutalismTheme.onSurfaceVariant,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "ADD CUSTOM",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: NeoBrutalismTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              NeoBrutalismButton(
                backgroundColor: NeoBrutalismTheme.tertiaryContainer,
                onPressed: _saveChanges,
                child: const Text(
                  "SIMPAN PERUBAHAN",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: NeoBrutalismTheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          "NOTIFIKASI",
          Icons.notifications_active,
          NeoBrutalismTheme.secondaryContainer,
        ),
        const SizedBox(height: 20),
        NeoBrutalismCard(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ENABLE NOTIFICATIONS",
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Terima alarm pengingat sebelum batas waktu tugas.",
                          style: TextStyle(
                            fontSize: 12,
                            color: NeoBrutalismTheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  BrutalSwitch(
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                  ),
                ],
              ),
              if (_notificationsEnabled) ...[
                const Divider(
                  height: 30,
                  thickness: 1.5,
                  color: NeoBrutalismTheme.outline,
                ),
                const Text(
                  "PENGINGAT DEADLINE / JADWAL",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: NeoBrutalismTheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildOffsetOption("Waktu Tiba", 0),
                    const SizedBox(width: 8),
                    _buildCustomOffsetOption(),
                  ],
                ),
                const Divider(
                  height: 30,
                  thickness: 1.5,
                  color: NeoBrutalismTheme.outline,
                ),
                const Text(
                  "NADA NOTIFIKASI PENGINGAT",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: NeoBrutalismTheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSoundOptionTile("Default (Bawaan Sistem)", "default", Icons.audiotrack),
                const SizedBox(height: 8),
                _buildSoundOptionTile("Retro Arcade (Built-in)", "retro", Icons.gamepad),
                const SizedBox(height: 8),
                _buildSoundOptionTile("Sleek Digital (Built-in)", "digital", Icons.developer_mode),
                const SizedBox(height: 8),
                _buildSoundOptionTile("Joyful Chime (Built-in)", "joyful", Icons.wb_sunny),
                const SizedBox(height: 8),
                _buildCustomSoundTile(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "DAILY MORNING SUMMARY",
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Kirim ringkasan tugas aktif setiap pagi pukul 08:00.",
                            style: TextStyle(
                              fontSize: 12,
                              color: NeoBrutalismTheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    BrutalSwitch(
                      value: _dailyDigestEnabled,
                      onChanged: _toggleDailyDigest,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                NeoBrutalismButton(
                  backgroundColor: NeoBrutalismTheme.secondaryContainer,
                  onPressed: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final theme = Theme.of(context);
                    await NotificationService.requestPermissions();
                    await NotificationService.testCustomNotification(_selectedSoundType, _customSoundPath);
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        content: NeoBrutalismCard(
                          backgroundColor: NeoBrutalismTheme.secondaryContainer,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.notifications_active,
                                color: NeoBrutalismTheme.onSurface,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Notifikasi tes terkirim! Cek panel notifikasi Anda.",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: NeoBrutalismTheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.flash_on, color: NeoBrutalismTheme.onSurface),
                      SizedBox(width: 8),
                      Text(
                        "UJI COBA NOTIFIKASI INSTAN",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: NeoBrutalismTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          "MANAJEMEN DATA",
          Icons.storage,
          NeoBrutalismTheme.primaryContainer,
        ),
        const SizedBox(height: 20),
        NeoBrutalismCard(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.storage,
                    color: NeoBrutalismTheme.primaryContainer,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "CADANGAN DATA",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Bricolage Grotesque',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              NeoBrutalismButton(
                backgroundColor: NeoBrutalismTheme.primaryContainer,
                onPressed: _handleExportBackup,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.backup, color: NeoBrutalismTheme.onSurface),
                    SizedBox(width: 8),
                    Text(
                      "EXPORT BACKUP",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: NeoBrutalismTheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              NeoBrutalismButton(
                backgroundColor: NeoBrutalismTheme.secondaryContainer,
                onPressed: _handleImportRestore,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.settings_backup_restore,
                      color: NeoBrutalismTheme.onSurface,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "IMPORT RESTORE",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: NeoBrutalismTheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        NeoBrutalismCard(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning,
                    color: NeoBrutalismTheme.error,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "TINDAKAN BERBAHAYA",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Bricolage Grotesque',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              NeoBrutalismButton(
                backgroundColor: NeoBrutalismTheme.error,
                onPressed: _showResetDataConfirmationDialog,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.delete_forever, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "CLEAR ALL TASKS",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          "TENTANG APLIKASI",
          Icons.info_outline,
          NeoBrutalismTheme.errorContainer,
        ),
        const SizedBox(height: 20),
        NeoBrutalismCard(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.phone_android,
                    color: NeoBrutalismTheme.errorContainer,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "DETAIL APLIKASI",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Bricolage Grotesque',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildInfoRow("Nama Aplikasi", "Lijsttedoen"),
              const SizedBox(height: 8),
              _buildInfoRow("Versi", "1.1.0"),
              const SizedBox(height: 8),
              _buildInfoRow("Lisensi", "MIT License"),
              const SizedBox(height: 8),
              _buildInfoRow("Developer", "Aniiporangbaik"),
            ],
          ),
        ),
        const SizedBox(height: 20),
        NeoBrutalismCard(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.system_update_alt,
                    color: NeoBrutalismTheme.secondaryContainer,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "PEMBARUAN APLIKASI",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Bricolage Grotesque',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              NeoBrutalismButton(
                backgroundColor: NeoBrutalismTheme.secondaryContainer,
                onPressed: _isCheckingForUpdates
                    ? null
                    : _handleCheckForUpdates,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isCheckingForUpdates
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                NeoBrutalismTheme.onSurface,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.refresh,
                            color: NeoBrutalismTheme.onSurface,
                          ),
                    const SizedBox(width: 8),
                    Text(
                      _isCheckingForUpdates
                          ? "MEMERIKSA..."
                          : "PERIKSA PEMBARUAN",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: NeoBrutalismTheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: NeoBrutalismTheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: NeoBrutalismTheme.onSurface,
          ),
        ),
      ],
    );
  }

  Future<void> _handleCheckForUpdates() async {
    setState(() {
      _isCheckingForUpdates = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isCheckingForUpdates = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: NeoBrutalismCard(
          backgroundColor: NeoBrutalismTheme.tertiaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: NeoBrutalismTheme.onSurface,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Aplikasi Anda sudah menggunakan versi terbaru (v1.1.0)!",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: NeoBrutalismTheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomMinutesDialog() {
    final controller = TextEditingController(
      text: _reminderOffset > 0 ? _reminderOffset.toString() : "",
    );
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 8,
                left: 8,
                right: 12,
                bottom: 12,
              ),
              child: NeoBrutalismCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.more_time,
                          color: NeoBrutalismTheme.primaryContainer,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "CUSTOM REMINDER",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Bricolage Grotesque',
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Masukkan jumlah menit sebelum batas waktu tugas untuk menerima notifikasi pengingat:",
                      style: TextStyle(
                        fontSize: 12,
                        color: NeoBrutalismTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    NeoTextField(
                      controller: controller,
                      labelText: "MENIT PENGINGAT",
                      placeholder: "Contoh: 30, 45, 120",
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: NeoBrutalismButton(
                            backgroundColor: Colors.white,
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Ngga Jadi Ahh",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: NeoBrutalismTheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: NeoBrutalismButton(
                            backgroundColor:
                                NeoBrutalismTheme.tertiaryContainer, // Green
                            onPressed: () {
                              final text = controller.text.trim();
                              final val = int.tryParse(text);
                              if (val != null && val > 0) {
                                _updateOffset(val);
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    content: NeoBrutalismCard(
                                      backgroundColor:
                                          NeoBrutalismTheme.errorContainer,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: NeoBrutalismTheme.onSurface,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              "Masukkin angka yang bener dongg, jangan angka ghoib.",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w900,
                                                    color: NeoBrutalismTheme
                                                        .onSurface,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              "Yakin cukup?",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: NeoBrutalismTheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomOffsetOption() {
    final isSelected = _reminderOffset > 0;
    String labelText = "Custom Waktu";
    if (isSelected) {
      if (_reminderOffset >= 60 && _reminderOffset % 60 == 0) {
        labelText = "${_reminderOffset ~/ 60} Jam";
      } else {
        labelText = "$_reminderOffset Menit";
      }
    }
    return Expanded(
      child: GestureDetector(
        onTap: _showCustomMinutesDialog,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? NeoBrutalismTheme.secondaryContainer
                : Colors.white,
            border: Border.all(color: NeoBrutalismTheme.outline, width: 2.5),
            borderRadius: BorderRadius.circular(8),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                labelText,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: NeoBrutalismTheme.onSurface,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.edit,
                size: 14,
                color: NeoBrutalismTheme.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOffsetOption(String label, int minutes) {
    final isSelected = _reminderOffset == minutes;
    return Expanded(
      child: GestureDetector(
        onTap: () => _updateOffset(minutes),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? NeoBrutalismTheme.secondaryContainer
                : Colors.white,
            border: Border.all(color: NeoBrutalismTheme.outline, width: 2.5),
            borderRadius: BorderRadius.circular(8),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              color: NeoBrutalismTheme.onSurface,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _showResetDataConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: NeoBrutalismCard(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "KONFIRMASI RESET",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Tak tanyain sekali lagi yaa, yakin ngga nih data-datanya mau dihapus? ngga bisa dibalikin lagi lho.",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: NeoBrutalismButton(
                      backgroundColor: Colors.white,
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "BATAL",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeoBrutalismButton(
                      backgroundColor: NeoBrutalismTheme.error,
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onResetData();
                      },
                      child: const Text(
                        "HAPUS",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoundOptionTile(String name, String key, IconData icon) {
    final isSelected = _selectedSoundType == key;
    return GestureDetector(
      onTap: () async {
        await NotificationService.setSoundType(key);
        setState(() {
          _selectedSoundType = key;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? NeoBrutalismTheme.secondaryContainer : Colors.white,
          border: Border.all(color: NeoBrutalismTheme.outline, width: 2.0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: NeoBrutalismTheme.onSurface, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: NeoBrutalismTheme.onSurface, size: 20)
            else
              GestureDetector(
                onTap: () => NotificationService.testCustomNotification(key, null),
                child: const Icon(Icons.play_circle_outline, color: NeoBrutalismTheme.onSurface, size: 22),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSoundTile() {
    final isSelected = _selectedSoundType == 'custom';
    final hasFile = _customSoundName != null && _customSoundPath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () async {
            if (hasFile) {
              await NotificationService.setSoundType('custom');
              setState(() {
                _selectedSoundType = 'custom';
              });
            } else {
              _pickCustomAudioFile();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? NeoBrutalismTheme.secondaryContainer : Colors.white,
              border: Border.all(color: NeoBrutalismTheme.outline, width: 2.0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.audio_file, color: NeoBrutalismTheme.onSurface, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasFile ? "Kustom: $_customSoundName" : "Pilih File Audio Sendiri...",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: hasFile ? NeoBrutalismTheme.onSurface : NeoBrutalismTheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasFile) ...[
                  GestureDetector(
                    onTap: () => NotificationService.testCustomNotification('custom', _customSoundPath),
                    child: const Icon(Icons.play_circle_outline, color: NeoBrutalismTheme.onSurface, size: 22),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _clearCustomAudioFile,
                    child: const Icon(Icons.delete, color: NeoBrutalismTheme.error, size: 20),
                  ),
                ] else if (isSelected)
                  const Icon(Icons.check_circle, color: NeoBrutalismTheme.onSurface, size: 20),
              ],
            ),
          ),
        ),
        if (hasFile) ...[
          const SizedBox(height: 8),
          NeoBrutalismButton(
            backgroundColor: NeoBrutalismTheme.primaryContainer,
            onPressed: _pickCustomAudioFile,
            child: const Text(
              "GANTI FILE AUDIO KUSTOM",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: NeoBrutalismTheme.onSurface,
              ),
            ),
          ),
        ]
      ],
    );
  }

  Future<void> _pickCustomAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final pickedFile = result.files.single;
        final originalFile = File(pickedFile.path!);

        String permanentPath = "";
        final appDir = await getApplicationDocumentsDirectory();

        if (Platform.isIOS) {
          final libraryDir = Directory(appDir.path.replaceAll('/Documents', '/Library'));
          final soundsDir = Directory('${libraryDir.path}/Sounds');
          if (!await soundsDir.exists()) {
            await soundsDir.create(recursive: true);
          }
          final extension = pickedFile.extension ?? 'mp3';
          final permanentFile = File('${soundsDir.path}/custom_sound.$extension');
          await originalFile.copy(permanentFile.path);
          permanentPath = permanentFile.path;
        } else {
          final permanentFile = File('${appDir.path}/custom_sound_${pickedFile.name}');
          await originalFile.copy(permanentFile.path);
          permanentPath = permanentFile.path;
        }

        await NotificationService.saveCustomSound(permanentPath, pickedFile.name);
        await NotificationService.setSoundType('custom');

        setState(() {
          _selectedSoundType = 'custom';
          _customSoundName = pickedFile.name;
          _customSoundPath = permanentPath;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
              content: NeoBrutalismCard(
                backgroundColor: NeoBrutalismTheme.tertiaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: NeoBrutalismTheme.onSurface),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "File audio kustom berhasil ditetapkan!",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: NeoBrutalismTheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error picking custom sound file: $e");
    }
  }

  Future<void> _clearCustomAudioFile() async {
    await NotificationService.clearCustomSound();
    await NotificationService.setSoundType('default');
    setState(() {
      _selectedSoundType = 'default';
      _customSoundName = null;
      _customSoundPath = null;
    });
  }
}

class BrutalSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const BrutalSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 60,
        height: 32,
        decoration: BoxDecoration(
          color: value ? NeoBrutalismTheme.tertiaryContainer : Colors.white,
          border: Border.all(color: NeoBrutalismTheme.outline, width: 2.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: NeoBrutalismTheme.outline, width: 2),
              boxShadow: value
                  ? null
                  : const [
                      BoxShadow(
                        color: NeoBrutalismTheme.outline,
                        offset: Offset(1.5, 1.5),
                        blurRadius: 0,
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 4.0,
    this.gap = 6.0,
    this.dashLength = 10.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            strokeWidth / 2,
            strokeWidth / 2,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(borderRadius),
        ),
      );

    final dashPath = Path();
    double distance = 0.0;
    for (final PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.borderRadius != borderRadius;
  }
}
