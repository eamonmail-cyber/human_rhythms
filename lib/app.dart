import 'package:flutter/material.dart';
import 'core/router.dart';
import 'core/theme.dart';

class HumanRhythmsApp extends StatelessWidget {
  const HumanRhythmsApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Human Rhythms',
      theme: buildAppTheme(),
      routerConfig: buildRouter(),
    );
  }
}
