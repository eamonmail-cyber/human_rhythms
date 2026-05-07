import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Stories',
      selectedIndex: 2,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_outlined, size: 64, color: kTextLight),
            const SizedBox(height: 16),
            Text('Stories coming soon.', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
