import 'package:flutter/material.dart';
import '../../core/theme.dart';

enum BubbleState { planned, done, skipped, partial, unknown }

class Bubble extends StatefulWidget {
  final Color color;
  final double size;
  final BubbleState state;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const Bubble({
    super.key,
    required this.color,
    required this.size,
    required this.state,
    this.label = '',
    this.onTap,
    this.onLongPress,
  });

  @override
  State<Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<Bubble> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onTapDown(_) => _ctrl.forward();
  void _onTapUp(_) { _ctrl.reverse(); widget.onTap?.call(); }
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCircle(),
            if (widget.label.isNotEmpty) ...[
              const SizedBox(height: 5),
              SizedBox(
                width: widget.size + 12,
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: kTextMid, fontWeight: FontWeight.w600, height: 1.2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCircle() {
    Color fill;
    Color border;
    double borderWidth;
    Widget? overlay;

    switch (widget.state) {
      case BubbleState.done:
        fill = widget.color.withOpacity(0.18);
        border = widget.color;
        borderWidth = 2.5;
        overlay = Icon(Icons.check_rounded, size: widget.size * 0.38, color: widget.color);
        break;
      case BubbleState.skipped:
        fill = Colors.transparent;
        border = kTextLight;
        borderWidth = 1.5;
        overlay = Icon(Icons.remove_rounded, size: widget.size * 0.36, color: kTextLight);
        break;
      case BubbleState.partial:
        fill = widget.color.withOpacity(0.08);
        border = widget.color.withOpacity(0.7);
        borderWidth = 2.5;
        overlay = Icon(Icons.timelapse_rounded, size: widget.size * 0.36, color: widget.color.withOpacity(0.8));
        break;
      case BubbleState.planned:
        fill = Colors.transparent;
        border = widget.color.withOpacity(0.45);
        borderWidth = 2;
        break;
      case BubbleState.unknown:
        fill = Colors.transparent;
        border = kDivider;
        borderWidth = 1.5;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: borderWidth),
        boxShadow: widget.state == BubbleState.done
            ? [BoxShadow(blurRadius: 10, spreadRadius: 0, color: widget.color.withOpacity(0.25))]
            : null,
      ),
      child: overlay != null ? Center(child: overlay) : null,
    );
  }
}
