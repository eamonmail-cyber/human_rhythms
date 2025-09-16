import 'package:flutter/material.dart';

class BadgesSheet extends StatelessWidget {
  const BadgesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(runSpacing: 12, children: [
          const Text("Award yourself a badge", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Wrap(spacing: 8, children: const [
            Chip(label: Text("⭐ Win of the Week")),
            Chip(label: Text("🥇 Consistency")),
            Chip(label: Text("💡 Insight")),
          ]),
          const SizedBox(height: 8),
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text("Close"))
        ]),
      ),
    );
  }
}
