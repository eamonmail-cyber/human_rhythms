import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/routine.dart';
import '../../data/repositories/repo_providers.dart' as repos;
import '../../features/auth/auth_controller.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../services/reminder_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _remindersEnabled = false;
  bool _streakReminders = true;
  bool _weeklySummary = true;
  bool _permissionDialogShown = false;

  // Per-routine reminder toggles keyed by routine id
  final Map<String, bool> _routineToggles = {};

  SharedPreferences? _prefs;

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const _kRemindersEnabled = 'reminders_enabled';
  static const _kStreakReminders  = 'streak_reminders';
  static const _kWeeklySummary    = 'weekly_summary';
  static String _routineKey(String id) => 'routine_reminder_$id';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _remindersEnabled = prefs.getBool(_kRemindersEnabled) ?? false;
      _streakReminders  = prefs.getBool(_kStreakReminders)  ?? true;
      _weeklySummary    = prefs.getBool(_kWeeklySummary)    ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final userId = ref.watch(userIdProvider);

    return AppScaffold(
      title: 'Profile',
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
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                        color: kPrimary, shape: BoxShape.circle),
                    child: Center(child: HRLogo(size: 32, light: true)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ??
                              user?.email ??
                              'Human Rhythms User',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Free Plan',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: kPrimary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ── Reminders section ────────────────────────────────────────────
          _SectionHeader('REMINDERS'),
          Card(
            child: Column(
              children: [
                // Master toggle
                SwitchListTile(
                  secondary: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: kCatMind.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.notifications_outlined,
                        color: kCatMind, size: 20),
                  ),
                  title: const Text('Enable reminders',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Personalised nudges for your routines',
                      style: TextStyle(fontSize: 12, color: kTextMid)),
                  value: _remindersEnabled,
                  activeColor: kPrimary,
                  onChanged: (val) async {
                    if (val && !_permissionDialogShown) {
                      _permissionDialogShown = true;
                      final granted = await _showPermissionDialog(context);
                      if (!granted) return;
                    }
                    setState(() => _remindersEnabled = val);
                    _prefs?.setBool(_kRemindersEnabled, val);
                    try {
                      if (!val) await ReminderService.cancelAll();
                      if (val && _weeklySummary) {
                        await ReminderService.scheduleWeeklySummary();
                      }
                    } catch (e) {
                      debugPrint('[Reminders] master toggle error: $e');
                      _showReminderError(e);
                    }
                  },
                ),
                if (_remindersEnabled) ...[
                  const Divider(height: 1, indent: 16),
                  // Per-routine toggles
                  if (userId != null)
                    FutureBuilder<List<Routine>>(
                      future: ref
                          .read(repos.routinesRepoProvider)
                          .byUser(userId),
                      builder: (context, snap) {
                        if (!snap.hasData) return const SizedBox.shrink();
                        return Column(
                          children: [
                            for (var i = 0;
                                i < snap.data!.length;
                                i++) ...[
                              _RoutineReminderTile(
                                routine: snap.data![i],
                                enabled: _routineToggles[snap.data![i].id] ??
                                    (_prefs?.getBool(
                                            _routineKey(snap.data![i].id)) ??
                                        true),
                                onChanged: (val) async {
                                  setState(() =>
                                      _routineToggles[snap.data![i].id] = val);
                                  _prefs?.setBool(
                                      _routineKey(snap.data![i].id), val);
                                  try {
                                    if (val) {
                                      await ReminderService
                                          .scheduleRoutineReminder(
                                              snap.data![i], i);
                                    } else {
                                      await ReminderService
                                          .cancelRoutineReminder(i);
                                    }
                                  } catch (e) {
                                    debugPrint('[Reminders] routine toggle error: $e');
                                    _showReminderError(e);
                                  }
                                },
                              ),
                              const Divider(height: 1, indent: 16),
                            ],
                          ],
                        );
                      },
                    ),
                  // Streak reminders
                  SwitchListTile(
                    title: const Text('Streak reminders',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('8pm nudge if nothing logged today',
                        style: TextStyle(fontSize: 12, color: kTextMid)),
                    value: _streakReminders,
                    activeColor: kPrimary,
                    onChanged: (val) async {
                      setState(() => _streakReminders = val);
                      _prefs?.setBool(_kStreakReminders, val);
                      try {
                        if (val) {
                          await ReminderService.scheduleStreakReminder(0);
                        } else {
                          await ReminderService.cancel(2000);
                        }
                      } catch (e) {
                        debugPrint('[Reminders] streak toggle error: $e');
                        _showReminderError(e);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 16),
                  // Weekly summary
                  SwitchListTile(
                    title: const Text('Weekly summary',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Sunday 7pm insights digest',
                        style: TextStyle(fontSize: 12, color: kTextMid)),
                    value: _weeklySummary,
                    activeColor: kPrimary,
                    onChanged: (val) async {
                      setState(() => _weeklySummary = val);
                      _prefs?.setBool(_kWeeklySummary, val);
                      try {
                        if (val) {
                          await ReminderService.scheduleWeeklySummary();
                        } else {
                          await ReminderService.cancel(2001);
                        }
                      } catch (e) {
                        debugPrint('[Reminders] weekly summary toggle error: $e');
                        _showReminderError(e);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 16),
                  // Test notification button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await ReminderService.sendTestNotification();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Test notification sent'),
                                backgroundColor: kPrimary,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('[Reminders] test notification error: $e');
                          _showReminderError(e);
                        }
                      },
                      icon: const Icon(Icons.notifications_active_outlined,
                          size: 18),
                      label: const Text('Send test notification'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimary,
                        side: const BorderSide(color: kPrimary),
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Privacy section ──────────────────────────────────────────────
          _SectionHeader('PRIVACY'),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  iconColor: kPrimary,
                  title: 'Data Privacy',
                  subtitle: 'Your routines are private by default',
                  trailing:
                      const Icon(Icons.chevron_right_rounded, color: kTextLight),
                  onTap: () => _showPrivacyInfo(context),
                ),
                const Divider(height: 1, indent: 16),
                _SettingsTile(
                  icon: Icons.share_outlined,
                  iconColor: kCatSocial,
                  title: 'Community Sharing',
                  subtitle: 'Browse and share public routines',
                  trailing:
                      const Icon(Icons.chevron_right_rounded, color: kTextLight),
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
                  trailing:
                      const Icon(Icons.chevron_right_rounded, color: kTextLight),
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

  Future<bool> _showPermissionDialog(BuildContext context) async {
    // Check current status first
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    // Permanently denied — can only fix via app settings
    if (status.isPermanentlyDenied) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Notifications Blocked'),
          content: const Text(
            'Notifications are blocked for this app. '
            'Open Settings to enable them.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary, foregroundColor: Colors.white),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return false;
    }

    // Not yet requested — ask
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enable Reminders'),
        content: const Text(
          'Human Rhythms would like to send you personalised reminders '
          'based on your routines and patterns — not generic alerts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context, true);
              await ReminderService.requestPermission();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary, foregroundColor: Colors.white),
            child: const Text('Enable reminders'),
          ),
        ],
      ),
    );
    if (result != true) return false;

    // Check again after user tapped Enable — may still be denied
    final granted = await Permission.notification.status;
    if (!granted.isGranted && mounted) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Permission Denied'),
          content: const Text(
            'Notification permission was not granted. '
            'You can enable it in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary, foregroundColor: Colors.white),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return false;
    }
    return granted.isGranted;
  }

  void _showPrivacyInfo(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Your Privacy'),
              content: const Text(
                'Human Rhythms is private by default.\n\n'
                'Your routines, diary entries, and health data are stored '
                'securely and are only visible to you.\n\n'
                'You can choose to make specific routines public so others '
                'can browse and follow them — but this is always your choice.',
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Got it'))
              ],
            ));
  }

  void _showAbout(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HRLogo(size: 56),
                  const SizedBox(height: 12),
                  const Text('Human Rhythms',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 20)),
                  const SizedBox(height: 6),
                  const Text(
                      'Track your routines.\nDiscover what truly works for you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kTextMid)),
                  const SizedBox(height: 12),
                  const Text('v1.0.0',
                      style: TextStyle(color: kTextLight, fontSize: 12)),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'))
              ],
            ));
  }

  void _showReminderError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder error: $e'),
        backgroundColor: kAccent,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Coming soon!'),
          backgroundColor: kPrimary,
          duration: Duration(seconds: 2)),
    );
  }
}

// ── Routine Reminder Tile ─────────────────────────────────────────────────────

class _RoutineReminderTile extends StatelessWidget {
  final Routine routine;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const _RoutineReminderTile({
    required this.routine,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(routine.title,
          style:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        routine.targetTime != null
            ? 'Reminder at ${routine.targetTime}'
            : 'No time set',
        style: const TextStyle(fontSize: 12, color: kTextMid),
      ),
      value: enabled,
      activeColor: kPrimary,
      onChanged: routine.targetTime != null ? onChanged : null,
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      );
}

// ── Settings Tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.subtitle,
      this.trailing,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: kTextMid)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
