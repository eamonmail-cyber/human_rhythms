import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  const AppScaffold({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [
        IconButton(onPressed: ()=> context.go('/summary'), icon: const Icon(Icons.insights)),
        IconButton(onPressed: ()=> context.go('/routines'), icon: const Icon(Icons.list)),
        IconButton(onPressed: ()=> context.go('/settings'), icon: const Icon(Icons.settings)),
      ]),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () { /* add routine / note */ },
        child: const Icon(Icons.add),
      ),
    );
  }
}
