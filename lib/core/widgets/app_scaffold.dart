import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../../features/assistant/assistant_sheet.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../providers/global.dart';

class AppScaffold extends ConsumerWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBack;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(userIdProvider);
    final path = GoRouterState.of(context).uri.toString();
    int selectedIndex = 0;
    if (path.startsWith('/routines'))   selectedIndex = 1;
    if (path.startsWith('/groups'))     selectedIndex = 2;
    if (path.startsWith('/challenges')) selectedIndex = 3;
    if (path.startsWith('/expert'))     selectedIndex = 4;
    if (path.startsWith('/summary'))    selectedIndex = 5;
    if (path.startsWith('/stories'))    selectedIndex = 6;
    if (path.startsWith('/settings'))   selectedIndex = 7;

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop())
            : Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Center(child: HRLogo(size: 28)),
              ),
        title: Text(title),
        actions: actions,
      ),
      body: Stack(
        children: [
          body,
          Positioned(
            bottom: 80,
            right: 16,
            child: _AssistantButton(userId: userId),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: _HRBottomNav(selectedIndex: selectedIndex),
    );
  }
}

// ── Assistant floating button ─────────────────────────────────────────────────

class _AssistantButton extends StatelessWidget {
  final String? userId;
  const _AssistantButton({required this.userId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AssistantSheet(userId: userId),
      ),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: kPrimary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: HRLogo(size: 28, light: true)),
      ),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────

class _HRBottomNav extends StatelessWidget {
  final int selectedIndex;
  const _HRBottomNav({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        boxShadow: [
          BoxShadow(
              color: kTextLight.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              _NavItem(icon: Icons.today_rounded,          index: 0, selected: selectedIndex, route: '/'),
              _NavItem(icon: Icons.loop_rounded,           index: 1, selected: selectedIndex, route: '/routines'),
              _NavItem(icon: Icons.group_outlined,         index: 2, selected: selectedIndex, route: '/groups'),
              _NavItem(icon: Icons.emoji_events_outlined,  index: 3, selected: selectedIndex, route: '/challenges'),
              _NavItem(icon: Icons.verified_outlined,      index: 4, selected: selectedIndex, route: '/expert'),
              _NavItem(icon: Icons.insights_rounded,       index: 5, selected: selectedIndex, route: '/summary'),
              _NavItem(icon: Icons.auto_stories_outlined,  index: 6, selected: selectedIndex, route: '/stories'),
              _NavItem(icon: Icons.person_outline_rounded, index: 7, selected: selectedIndex, route: '/settings'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final int index;
  final int selected;
  final String route;
  const _NavItem({
    required this.icon,
    required this.index,
    required this.selected,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () { if (!isSelected) context.go(route); },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? kPrimary.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 22,
                color: isSelected ? kPrimary : kTextLight),
          ),
        ),
      ),
    );
  }
}
