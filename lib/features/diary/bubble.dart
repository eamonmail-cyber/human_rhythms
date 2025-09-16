import 'package:flutter/material.dart';

enum BubbleState { planned, done, skipped, partial, unknown }

class Bubble extends StatelessWidget {
  final Color color;
  final double size;
  final BubbleState state;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const Bubble({super.key, required this.color, required this.size, required this.state, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final border = switch (state) {
      BubbleState.planned => Border.all(color: color.withOpacity(0.6), width: 2),
      BubbleState.done    => Border.all(color: color, width: 3),
      BubbleState.skipped => Border.all(color: Colors.grey, width: 2),
      BubbleState.partial => Border.all(color: color.withOpacity(0.8), width: 3),
      BubbleState.unknown => Border.all(color: Colors.grey, width: 1),
    };

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size, height: size,
        decoration: BoxDecoration(
          color: state == BubbleState.done ? color.withOpacity(.18) : Colors.transparent,
          shape: BoxShape.circle,
          border: border,
          boxShadow: [if (state == BubbleState.done) BoxShadow(blurRadius: 6, spreadRadius: 1, color: color.withOpacity(.15))],
        ),
      ),
    );
  }
}
