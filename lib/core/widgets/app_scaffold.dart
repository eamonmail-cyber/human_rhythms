import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../features/diary/diary_screen.dart';
import '../../features/routines/routine_list_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/summary/weekly_summary_screen.dart';
import '../../features/settings/settings_screen.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBack;
  final int selectedIndex;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBack = false,
    this.selectedIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Center(child: HRLogo(size: 28)),
              ),
        title: Text(title),
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: _HRBottomNav(selectedIndex: selectedIndex),
    );
  }
}

class _HRBottomNav extends StatelessWidget {
  final int selectedIndex;
  const _HRBottomNav({required this.selectedIndex});

  void _navigate(BuildContext context, int index) {
    if (index == selectedIndex) return;
    Widget screen;
    switch (index) {
      case 0: screen = const DiaryScreen(); break;
      case 1: screen = const RoutineListScreen(); break;
      case 2: screen = const LibraryScreen(); break;
      case 3: screen = const WeeklySummaryScreen(); break;
      case 4: screen = const SettingsScreen(); break;
      default: screen = const DiaryScreen();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        boxShadow: [
          BoxShadow(
            color: kTextLight.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(icon: Icons.today_rounded,          label: 'Today',    index: 0, selected: selectedIndex, onTap: () => _navigate(context, 0)),
              _NavItem(icon: Icons.loop_rounded,           label: 'Routines', index: 1, selected: selectedIndex, onTap: () => _navigate(context, 1)),
              _NavItem(icon: Icons.library_books_outlined, label: 'Library',  index: 2, selected: selectedIndex, onTap: () => _navigate(context, 2)),
              _NavItem(icon: Icons.insights_rounded,       label: 'Insights', index: 3, selected: selectedIndex, onTap: () => _navigate(context, 3)),
              _NavItem(icon: Icons.person_outline_rounded, label: 'Profile',  index: 4, selected: selectedIndex, onTap: () => _navigate(context, 4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.index, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selected;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? kPrimary.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 22, color: isSelected ? kPrimary : kTextLight),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? kPrimary : kTextLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
