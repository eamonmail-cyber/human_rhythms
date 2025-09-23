import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _Baseline(),
  ));
}

class _Baseline extends StatefulWidget {
  const _Baseline({super.key});
   @override
  State<_Baseline> createState() => _BaselineState();
}

class _BaselineState extends State<_Baseline> {
  final _events = <String>['App started'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => setState(() => _events.add('UI mounted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Human Rhythms — Baseline')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('If you see this, rendering is OK.'),
          const SizedBox(height: 12),
          for (final e in _events.reversed) Text('• $e'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => setState(() => _events.add('Tapped @ ${DateTime.now()}')),
            child: const Text('Tap test'),
          ),
        ],
      ),
    );
  }
}
