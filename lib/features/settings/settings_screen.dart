import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text("Reminders"),
            subtitle: const Text("Set preferred times for your routines"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/reminders'),
          ),
          const ListTile(title: Text("Privacy (MVP defaults to private)")),
          const ListTile(title: Text("Export data (CSV/PDF - later)")),
        ],
      ),
    );
  }
}
