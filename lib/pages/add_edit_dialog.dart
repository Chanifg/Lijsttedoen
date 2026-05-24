import 'package:flutter/material.dart';
import 'package:lijsttedoen/models/todo_model.dart';
import 'package:lijsttedoen/theme/neo_brutalism_theme.dart';
import 'package:lijsttedoen/widgets/neo_brutalism_widgets.dart';

class AddEditDialog extends StatefulWidget {
  final TodoModel? todo;

  const AddEditDialog({super.key, this.todo});

  @override
  State<AddEditDialog> createState() => _AddEditDialogState();
}

class _AddEditDialogState extends State<AddEditDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _deadlineDateController = TextEditingController();
  final TextEditingController _deadlineTimeController = TextEditingController();
  String _selectedCategory = 'Work';
  bool _isDeadline = false;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    if (widget.todo != null) {
      _titleController.text = widget.todo!.title;
      _descController.text = widget.todo!.description;
      _timeController.text = widget.todo!.dueTime;
      _dateController.text = widget.todo!.dueDate;
      _selectedCategory = widget.todo!.category;
      _isDeadline = widget.todo!.isDeadline;
      _deadlineDateController.text =
          widget.todo!.deadlineDate ?? _getTodayDateString();
      _deadlineTimeController.text =
          widget.todo!.deadlineTime ?? '12:00';
    } else {
      _timeController.text = '12:00';
      _dateController.text = _getTodayDateString();
      _selectedCategory = 'Work';
      _isDeadline = false;
      _deadlineDateController.text = _getTodayDateString();
      _deadlineTimeController.text = '12:00';
    }
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  TimeOfDay _parseTimeOfDay(String value) {
    try {
      final parts = value.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (_) {}
    return const TimeOfDay(hour: 12, minute: 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _timeController.dispose();
    _dateController.dispose();
    _deadlineDateController.dispose();
    _deadlineTimeController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleError = "Judul tugas tidak boleh kosong";
      });
      return;
    }

    Navigator.pop(context, {
      'title': title,
      'description': _descController.text.trim(),
      'dueTime': _isDeadline
          ? ''
          : (_timeController.text.trim().isEmpty
                ? '12:00'
                : _timeController.text.trim()),
      'dueDate': _isDeadline ? '' : _dateController.text.trim(),
      'category': _selectedCategory,
      'isDeadline': _isDeadline ? 'true' : 'false',
      'deadlineDate': _isDeadline ? _deadlineDateController.text.trim() : '',
      'deadlineTime': _isDeadline ? _deadlineTimeController.text.trim() : '',
    });
  }

  Widget _buildCategoryButton(String cat, Color activeColor, IconData icon) {
    final isSelected = _selectedCategory == cat;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = cat;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            border: Border.all(
              color: NeoBrutalismTheme.outline,
              width: isSelected ? 3.0 : 2.0,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    const BoxShadow(
                      color: NeoBrutalismTheme.outline,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: NeoBrutalismTheme.onSurface),
              const SizedBox(height: 4),
              Text(
                cat,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: NeoBrutalismTheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.todo != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 14.0, bottom: 14.0),
          child: NeoBrutalismCard(
            backgroundColor: NeoBrutalismTheme.background,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Text(
                isEditing ? "EDIT TUGAS" : "TAMBAH TUGAS BARU",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              NeoTextField(
                controller: _titleController,
                labelText: "JUDUL TUGAS",
                placeholder: "mis. Analitik Data Boss...",
                errorText: _titleError,
                onChanged: (val) {
                  if (val.trim().isNotEmpty && _titleError != null) {
                    setState(() {
                      _titleError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              NeoTextField(
                controller: _descController,
                labelText: "DESKRIPSI (OPSIONAL)",
                placeholder: "mis. Jangan sampai telat...",
              ),
              const SizedBox(height: 16),

              // Switch/Checkbox "Set as Deadline"
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isDeadline = !_isDeadline;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _isDeadline
                        ? NeoBrutalismTheme.errorContainer
                        : Colors.white, // Pink when active
                    border: Border.all(
                      color: NeoBrutalismTheme.outline,
                      width: 2.5,
                    ),
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
                      // Neo Checkbox
                      NeoCheckbox(
                        value: _isDeadline,
                        onChanged: (val) {
                          setState(() {
                            _isDeadline = val ?? false;
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TUGAS DEADLINE",
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: NeoBrutalismTheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Setting deadline biar ngga DEAD.",
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
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
              ),
              const SizedBox(height: 16),

              // Jam & Tanggal Pelaksanaan (Hanya aktif jika BUKAN deadline)
              Opacity(
                opacity: _isDeadline ? 0.4 : 1.0,
                child: AbsorbPointer(
                  absorbing: _isDeadline,
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: _parseTimeOfDay(_timeController.text),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: NeoBrutalismTheme.primaryContainer, // Yellow
                                      onPrimary: NeoBrutalismTheme.onSurface,
                                      onSurface: NeoBrutalismTheme.onSurface,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedTime != null) {
                              setState(() {
                                _timeController.text =
                                    "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: NeoTextField(
                              controller: _timeController,
                              labelText: "JAM TUGAS",
                              placeholder: "mis. 12:00",
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            DateTime parsed =
                                DateTime.tryParse(_dateController.text) ??
                                DateTime.now();
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: parsed,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: NeoBrutalismTheme
                                          .primaryContainer, // Yellow
                                      onPrimary: NeoBrutalismTheme.onSurface,
                                      onSurface: NeoBrutalismTheme.onSurface,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _dateController.text =
                                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: NeoTextField(
                              controller: _dateController,
                              labelText: "TANGGAL TUGAS",
                              placeholder: "YYYY-MM-DD",
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Input Tanggal & Jam Deadline (Hanya aktif/tampil jika deadline)
              if (_isDeadline) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: _parseTimeOfDay(_deadlineTimeController.text),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: NeoBrutalismTheme.errorContainer, // Pink
                                    onPrimary: NeoBrutalismTheme.onSurface,
                                    onSurface: NeoBrutalismTheme.onSurface,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedTime != null) {
                            setState(() {
                              _deadlineTimeController.text =
                                    "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: NeoTextField(
                            controller: _deadlineTimeController,
                            labelText: "JAM DEADLINE",
                            placeholder: "mis. 12:00",
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          DateTime parsed =
                              DateTime.tryParse(_deadlineDateController.text) ??
                              DateTime.now();
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: parsed,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: NeoBrutalismTheme
                                        .errorContainer, // Pink for deadline
                                    onPrimary: NeoBrutalismTheme.onSurface,
                                    onSurface: NeoBrutalismTheme.onSurface,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _deadlineDateController.text =
                                  "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: NeoTextField(
                            controller: _deadlineDateController,
                            labelText: "TANGGAL DEADLINE",
                            placeholder: "YYYY-MM-DD",
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Text(
                "KATEGORI TUGAS",
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: NeoBrutalismTheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildCategoryButton(
                    'Work',
                    NeoBrutalismTheme.primaryContainer,
                    Icons.work,
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryButton(
                    'Personal',
                    NeoBrutalismTheme.secondaryContainer,
                    Icons.person,
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryButton(
                    'Study',
                    NeoBrutalismTheme.tertiaryContainer,
                    Icons.school,
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
                      backgroundColor:
                          NeoBrutalismTheme.tertiaryContainer, // Lively Green
                      onPressed: _submit,
                      child: Text(
                        isEditing ? "SIMPAN" : "TAMBAH",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w800),
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
  }
}
