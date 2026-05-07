import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Community',
      selectedIndex: 2,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: kTextLight),
            const SizedBox(height: 16),
            Text('Community coming soon.', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
