import 'package:flutter/material.dart';

import '../../core/localization/transalation_extansions.dart';
import '../../core/models/app_settings.dart';
import '../../core/services/notification_service.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _hasPermission = true;
  bool _sendingTest = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final ok = await NotificationService.hasPermission();
    if (mounted) setState(() => _hasPermission = ok);
  }

  Future<void> _scheduleWithCurrentSettings(AppSettings s) async {
    await NotificationService.scheduleReminders(
      slot1: s.reminder1Enabled,
      slot2: s.reminder2Enabled,
      slot3: s.reminder3Enabled,
      slot1Hour: s.reminder1Hour,
      slot1Minute: s.reminder1Minute,
      slot2Hour: s.reminder2Hour,
      slot2Minute: s.reminder2Minute,
      slot3Hour: s.reminder3Hour,
      slot3Minute: s.reminder3Minute,
    );
  }

  Future<void> _toggleSlot(int slot, bool value) async {
    final appState = context.appState;
    final updated = switch (slot) {
      1 => appState.settings.copyWith(reminder1Enabled: value),
      2 => appState.settings.copyWith(reminder2Enabled: value),
      3 => appState.settings.copyWith(reminder3Enabled: value),
      _ => appState.settings,
    };
    appState.updateSettings(updated);
    await _scheduleWithCurrentSettings(updated);
  }

  Future<void> _pickTime(int slot) async {
    final appState = context.appState;
    final s = appState.settings;
    final initial = switch (slot) {
      1 => TimeOfDay(hour: s.reminder1Hour, minute: s.reminder1Minute),
      2 => TimeOfDay(hour: s.reminder2Hour, minute: s.reminder2Minute),
      3 => TimeOfDay(hour: s.reminder3Hour, minute: s.reminder3Minute),
      _ => const TimeOfDay(hour: 9, minute: 0),
    };

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;

    final updated = switch (slot) {
      1 => s.copyWith(reminder1Hour: picked.hour, reminder1Minute: picked.minute),
      2 => s.copyWith(reminder2Hour: picked.hour, reminder2Minute: picked.minute),
      3 => s.copyWith(reminder3Hour: picked.hour, reminder3Minute: picked.minute),
      _ => s,
    };
    appState.updateSettings(updated);
    await _scheduleWithCurrentSettings(updated);
  }

  Future<void> _toggleBudgetAlert(bool value) async {
    context.appState.updateSettings(
      context.appState.settings.copyWith(budgetAlertEnabled: value),
    );
  }

  Future<void> _sendTest() async {
    setState(() => _sendingTest = true);
    await NotificationService.sendTestNotification();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _sendingTest = false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.appState.settings;
    final anyReminder =
        settings.reminder1Enabled || settings.reminder2Enabled || settings.reminder3Enabled;

    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('notification.title')),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          // ── Permission warning ───────────────────────────────────────────
          if (!_hasPermission) ...[
            _PermissionBanner(onTap: _checkPermission),
            const SizedBox(height: 16),
          ],

          // ── Section: Pengingat Harian ────────────────────────────────────
          _SectionLabel(context.t('notification.dailyReminderSection')),
          const SizedBox(height: 10),

          _Card(
            child: Column(
              children: [
                _ReminderSlotRow(
                  hour: settings.reminder1Hour,
                  minute: settings.reminder1Minute,
                  label: context.t('notification.reminder1Label'),
                  enabled: settings.reminder1Enabled,
                  onChanged: (v) => _toggleSlot(1, v),
                  onTimeTap: () => _pickTime(1),
                ),
                const Divider(height: 1),
                _ReminderSlotRow(
                  hour: settings.reminder2Hour,
                  minute: settings.reminder2Minute,
                  label: context.t('notification.reminder2Label'),
                  enabled: settings.reminder2Enabled,
                  onChanged: (v) => _toggleSlot(2, v),
                  onTimeTap: () => _pickTime(2),
                ),
                const Divider(height: 1),
                _ReminderSlotRow(
                  hour: settings.reminder3Hour,
                  minute: settings.reminder3Minute,
                  label: context.t('notification.reminder3Label'),
                  enabled: settings.reminder3Enabled,
                  onChanged: (v) => _toggleSlot(3, v),
                  onTimeTap: () => _pickTime(3),
                ),
              ],
            ),
          ),

          if (anyReminder) ...[
            const SizedBox(height: 16),
            _InfoBox(context.t('notification.reminderInfoText')),
          ],

          const SizedBox(height: 24),

          // ── Section: Peringatan Budget ────────────────────────────────────
          _SectionLabel(context.t('notification.budgetAlertSection')),
          const SizedBox(height: 10),

          _Card(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: settings.budgetAlertEnabled
                        ? AppColors.brandBlue.withValues(alpha: 0.12)
                        : context.appColors.cardSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.savings_outlined,
                    color: settings.budgetAlertEnabled
                        ? AppColors.brandBlue
                        : context.appColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('notification.budgetAlertTitle'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.t('notification.budgetAlertSubtitle'),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.budgetAlertEnabled,
                  onChanged: (v) => _toggleBudgetAlert(v),
                ),
              ],
            ),
          ),

          if (settings.budgetAlertEnabled) ...[
            const SizedBox(height: 16),
            _InfoBox(context.t('notification.budgetAlertInfoText')),
          ],

          const SizedBox(height: 32),

          // ── Section: Uji Notifikasi ───────────────────────────────────────
          _SectionLabel('UJI NOTIFIKASI'),
          const SizedBox(height: 10),

          _Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kirim notifikasi percobaan',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Verifikasi bahwa notifikasi muncul dengan benar di perangkatmu.',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendingTest ? null : _sendTest,
                      icon: _sendingTest
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.notifications_active_outlined, size: 18),
                      label: Text(_sendingTest ? 'Mengirim...' : 'Kirim Sekarang'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Permission banner ────────────────────────────────────────────────────────

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifikasi diblokir',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Izinkan notifikasi di pengaturan sistem agar pengingat bisa muncul.',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.refresh_rounded, size: 18, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reminder slot row ────────────────────────────────────────────────────────

class _ReminderSlotRow extends StatelessWidget {
  const _ReminderSlotRow({
    required this.hour,
    required this.minute,
    required this.label,
    required this.enabled,
    required this.onChanged,
    required this.onTimeTap,
  });

  final int hour;
  final int minute;
  final String label;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTimeTap;

  String get _timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.brandBlue.withValues(alpha: 0.12)
                  : context.appColors.cardSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.access_time_outlined,
              size: 20,
              color: enabled ? AppColors.brandBlue : context.appColors.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: enabled ? onTimeTap : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: enabled
                          ? AppColors.brandBlue.withValues(alpha: 0.1)
                          : context.appColors.cardSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _timeLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: enabled
                                ? AppColors.brandBlue
                                : context.appColors.textSecondary,
                          ),
                        ),
                        if (enabled) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit_outlined,
                            size: 12,
                            color: AppColors.brandBlue.withValues(alpha: 0.7),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        fontSize: 11,
        color: context.appColors.textSecondary,
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.brandBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: context.appColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.outline),
      ),
      child: child,
    );
  }
}
