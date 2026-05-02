import 'package:flutter/material.dart';

import '../../core/localization/transalation_extansions.dart';
import '../../core/services/notification_service.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  Future<void> _toggleSlot(
    BuildContext context, {
    required int slot,
    required bool value,
  }) async {
    final appState = context.appState;
    final settings = appState.settings;
    final updated = switch (slot) {
      1 => settings.copyWith(reminder1Enabled: value),
      2 => settings.copyWith(reminder2Enabled: value),
      3 => settings.copyWith(reminder3Enabled: value),
      _ => settings,
    };
    appState.updateSettings(updated);
    await NotificationService.scheduleReminders(
      slot1: updated.reminder1Enabled,
      slot2: updated.reminder2Enabled,
      slot3: updated.reminder3Enabled,
    );
  }

  Future<void> _toggleBudgetAlert(BuildContext context, bool value) async {
    context.appState.updateSettings(
      context.appState.settings.copyWith(budgetAlertEnabled: value),
    );
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
          // ── Section: Pengingat Harian ────────────────────────────────────
          _SectionLabel(context.t('notification.dailyReminderSection')),
          const SizedBox(height: 10),

          _Card(
            child: Column(
              children: [
                _ReminderSlotRow(
                  time: '09:00',
                  label: context.t('notification.reminder1Label'),
                  enabled: settings.reminder1Enabled,
                  onChanged: (v) => _toggleSlot(context, slot: 1, value: v),
                ),
                const Divider(height: 1),
                _ReminderSlotRow(
                  time: '15:00',
                  label: context.t('notification.reminder2Label'),
                  enabled: settings.reminder2Enabled,
                  onChanged: (v) => _toggleSlot(context, slot: 2, value: v),
                ),
                const Divider(height: 1),
                _ReminderSlotRow(
                  time: '21:00',
                  label: context.t('notification.reminder3Label'),
                  enabled: settings.reminder3Enabled,
                  onChanged: (v) => _toggleSlot(context, slot: 3, value: v),
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
                  onChanged: (v) => _toggleBudgetAlert(context, v),
                ),
              ],
            ),
          ),

          if (settings.budgetAlertEnabled) ...[
            const SizedBox(height: 16),
            _InfoBox(context.t('notification.budgetAlertInfoText')),
          ],
        ],
      ),
    );
  }
}

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

class _ReminderSlotRow extends StatelessWidget {
  const _ReminderSlotRow({
    required this.time,
    required this.label,
    required this.enabled,
    required this.onChanged,
  });

  final String time;
  final String label;
  final bool enabled;
  final ValueChanged<bool> onChanged;

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
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: enabled ? AppColors.brandBlue : context.appColors.textSecondary,
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
