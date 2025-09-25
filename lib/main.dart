import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _Baseline(),
  ));
}

class _Baseline extends StatelessWidget {
  const _Baseline({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Human Rhythms — Baseline')),
      body: Center(
        child: FilledButton(
          onPressed: () {},
          child: const Text('It builds 🎉'),
        ),
      ),
    );
  }
}
