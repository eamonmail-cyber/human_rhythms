import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/sign_in_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    return AppScaffold(
      title: 'Profile',
      selectedIndex: 3,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar / profile card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                    child: Center(child: HRLogo(size: 32, light: true)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? user?.email ?? 'Human Rhythms User',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Free Plan', style: TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Privacy section
          _SectionHeader('PRIVACY'),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  iconColor: kPrimary,
                  title: 'Data Privacy',
                  subtitle: 'Your routines are private by default',
                  trailing: const Icon(Icons.chevron_right_rounded, color: kTextLight),
                  onTap: () => _showPrivacyInfo(context),
                ),
                const Divider(height: 1, indent: 16),
                _SettingsTile(
                  icon: Icons.share_outlined,
                  iconColor: kCatSocial,
                  title: 'Community Sharing',
                  subtitle: 'Browse and share public routines',
                  trailing: const Icon(Icons.chevron_right_rounded, color: kTextLight),
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader('DATA'),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.download_outlined,
                  iconColor: kCatMovement,
                  title: 'Export My Data',
                  subtitle: 'Download all your routines & entries',
                  trailing: const Icon(Icons.chevron_right_rounded, color: kTextLight),
                  onTap: () => _showComingSoon(context),
                ),
                const Divider(height: 1, indent: 16),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  iconColor: kCatMind,
                  title: 'Reminders',
                  subtitle: 'Set daily nudges for your routines',
                  trailing: const Icon(Icons.chevron_right_rounded, color: kTextLight),
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader('ABOUT'),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: kTextMid,
                  title: 'About Human Rhythms',
                  subtitle: 'Version 1.0.0',
                  onTap: () => _showAbout(context),
                ),
                const Divider(height: 1, indent: 16),
                _SettingsTile(
                  icon: Icons.star_outline_rounded,
                  iconColor: kAccent,
                  title: 'Rate the App',
                  subtitle: 'Help us grow the community',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await signOut();
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kAccent,
              side: const BorderSide(color: kAccent),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Your Privacy'),
      content: const Text(
        'Human Rhythms is private by default.\n\n'
        'Your routines, diary entries, and health data are stored securely and are only visible to you.\n\n'
        'You can choose to make specific routines public so others can browse and follow them — but this is always your choice.',
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
    ));
  }

  void _showAbout(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HRLogo(size: 56),
          const SizedBox(height: 12),
          const Text('Human Rhythms', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 6),
          const Text('Track your routines.\nDiscover what truly works for you.',
              textAlign: TextAlign.center, style: TextStyle(color: kTextMid)),
          const SizedBox(height: 12),
          const Text('v1.0.0', style: TextStyle(color: kTextLight, fontSize: 12)),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ));
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon! 🚀'), backgroundColor: kPrimary, duration: Duration(seconds: 2)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile({required this.icon, required this.iconColor, required this.title, required this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: kTextMid)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
