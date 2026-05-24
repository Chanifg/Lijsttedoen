import 'package:flutter/material.dart';
import 'package:lijsttedoen/theme/neo_brutalism_theme.dart';

class NeoBrutalismCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final double radius;
  final double borderWidth;
  final Offset shadowOffset;
  final Color shadowColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const NeoBrutalismCard({
    super.key,
    required this.child,
    this.backgroundColor = NeoBrutalismTheme.background,
    this.radius = NeoBrutalismTheme.cardRadius,
    this.borderWidth = NeoBrutalismTheme.borderWidth,
    this.shadowOffset = NeoBrutalismTheme.shadowOffset,
    this.shadowColor = NeoBrutalismTheme.outline,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: shadowColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Transform.translate(
        offset: -shadowOffset,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: shadowColor, width: borderWidth),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        ),
      ),
    );
  }
}

class NeoBrutalismButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final double radius;
  final double borderWidth;
  final Offset shadowOffset;
  final EdgeInsetsGeometry padding;

  const NeoBrutalismButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor = NeoBrutalismTheme.primaryContainer,
    this.radius = NeoBrutalismTheme.buttonRadius,
    this.borderWidth = NeoBrutalismTheme.borderWidth,
    this.shadowOffset = NeoBrutalismTheme.shadowOffset,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  State<NeoBrutalismButton> createState() => _NeoBrutalismButtonState();
}

class _NeoBrutalismButtonState extends State<NeoBrutalismButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final translation = _isPressed ? widget.shadowOffset : Offset.zero;

    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onPressed != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.onPressed != null ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: NeoBrutalismTheme.outline,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          transform: Matrix4.translationValues(
            translation.dx - widget.shadowOffset.dx,
            translation.dy - widget.shadowOffset.dy,
            0,
          ),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.onPressed == null ? Colors.grey[300] : widget.backgroundColor,
            border: Border.all(color: NeoBrutalismTheme.outline, width: widget.borderWidth),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.labelLarge!,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class NeoCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const NeoCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: NeoBrutalismTheme.outline,
          borderRadius: BorderRadius.circular(NeoBrutalismTheme.checkboxRadius),
        ),
        child: Transform.translate(
          offset: const Offset(-3, -3),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: value ? NeoBrutalismTheme.primaryContainer : Colors.white,
              border: Border.all(color: NeoBrutalismTheme.outline, width: 3),
              borderRadius: BorderRadius.circular(NeoBrutalismTheme.checkboxRadius),
            ),
            child: value
                ? const Icon(
                    Icons.check,
                    size: 18,
                    color: NeoBrutalismTheme.onSurface,
                    weight: 900,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class NeoProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color fillColor;
  final double height;

  const NeoProgressBar({
    super.key,
    required this.value,
    this.fillColor = NeoBrutalismTheme.primaryContainer,
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    return NeoBrutalismCard(
      radius: 999, // Pill shape
      borderWidth: NeoBrutalismTheme.borderWidth,
      backgroundColor: Colors.white,
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fillWidth = constraints.maxWidth * value.clamp(0.0, 1.0);
          return Container(
            height: height - NeoBrutalismTheme.borderWidth * 2,
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: fillWidth,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.horizontal(
                  left: const Radius.circular(999),
                  right: Radius.circular(value >= 0.98 ? 999 : 0),
                ),
                border: fillWidth > 0
                    ? const Border(
                        right: BorderSide(
                          color: NeoBrutalismTheme.outline,
                          width: NeoBrutalismTheme.borderWidth,
                        ),
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

class NeoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? placeholder;
  final String? errorText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onChanged;

  const NeoTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.placeholder,
    this.errorText,
    this.suffixIcon,
    this.onSuffixTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: NeoBrutalismTheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 6),
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
                controller: controller,
                onChanged: onChanged,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  errorText: errorText,
                  errorStyle: const TextStyle(fontWeight: FontWeight.bold),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: InputBorder.none,
                  suffixIcon: suffixIcon != null
                      ? GestureDetector(
                          onTap: onSuffixTap,
                          child: Icon(suffixIcon, color: NeoBrutalismTheme.outline),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class BrutalGridPainter extends CustomPainter {
  final Color gridColor;
  final double gridSize;

  BrutalGridPainter({
    this.gridColor = const Color(0xFFE4E3DB),
    this.gridSize = 40.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 2.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BrutalGrid extends StatelessWidget {
  final Widget child;

  const BrutalGrid({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BrutalGridPainter(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class BrutalAvatar extends StatelessWidget {
  final String avatarType; // 'initial', 'face', 'pets', 'bunny'
  final String userName;
  final double size;
  final bool isSelected; // Menampilkan centang hijau jika terpilih

  const BrutalAvatar({
    super.key,
    required this.avatarType,
    required this.userName,
    this.size = 64.0,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Widget childWidget;

    final initial = userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : 'P';

    switch (avatarType) {
      case 'face':
        bg = NeoBrutalismTheme.secondaryContainer;
        childWidget = Icon(Icons.face_outlined, size: size * 0.55, color: NeoBrutalismTheme.onSurface);
        break;
      case 'pets':
        bg = NeoBrutalismTheme.tertiaryContainer;
        childWidget = Icon(Icons.pets, size: size * 0.55, color: NeoBrutalismTheme.onSurface);
        break;
      case 'bunny':
        bg = NeoBrutalismTheme.errorContainer;
        childWidget = Icon(Icons.cruelty_free, size: size * 0.55, color: NeoBrutalismTheme.onSurface);
        break;
      case 'initial':
      default:
        bg = NeoBrutalismTheme.primaryContainer;
        childWidget = Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.w900,
            fontFamily: 'Bricolage Grotesque',
            color: NeoBrutalismTheme.onSurface,
          ),
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4, right: 6, bottom: 6),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: NeoBrutalismTheme.outline,
          shape: BoxShape.circle,
        ),
        child: Transform.translate(
          offset: const Offset(-2, -2),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: NeoBrutalismTheme.outline, width: 3.5),
                ),
                child: childWidget,
              ),
              if (isSelected)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: NeoBrutalismTheme.tertiaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: NeoBrutalismTheme.outline, width: 3),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: NeoBrutalismTheme.onSurface,
                      weight: 900,
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

class NeoBrutalismBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NeoBrutalismBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: NeoBrutalismTheme.surface,
        border: Border.all(
          color: NeoBrutalismTheme.outline,
          width: NeoBrutalismTheme.borderWidth,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: const [
          BoxShadow(
            color: NeoBrutalismTheme.outline,
            offset: Offset(0, -4),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.list_alt, "Tasks", const Color(0xFFFFD700)),
            _buildNavItem(1, Icons.calendar_today, "Calendar", const Color(0xFFACEC6B)),
            _buildNavItem(2, Icons.bar_chart, "Stats", const Color(0xFF7CEAFD)),
            _buildNavItem(3, Icons.settings, "Settings", const Color(0xFFFF7CEF)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color highlightColor) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? NeoBrutalismTheme.onSurface : NeoBrutalismTheme.onSurface.withValues(alpha: 0.55),
              size: 28,
            ),
            const SizedBox(height: 4),
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (isSelected)
                  Positioned(
                    bottom: -1,
                    child: Transform.rotate(
                      angle: -0.05, // ~ -2 derajat
                      child: Container(
                        width: label.length * 8.0 + 12,
                        height: 14,
                        decoration: BoxDecoration(
                          color: highlightColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    color: isSelected ? NeoBrutalismTheme.onSurface : NeoBrutalismTheme.onSurface.withValues(alpha: 0.55),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
