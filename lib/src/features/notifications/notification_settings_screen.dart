import 'package:flutter/material.dart';

import '../../core/localization/transalation_extansions.dart';
import '../../core/services/notification_service.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  Future<void> _toggleNotification(BuildContext context, bool value) async {
    final appState = context.appState;
    final settings = appState.settings;
    appState.updateSettings(settings.copyWith(dailyNotification: value));
    if (value) {
      await NotificationService.schedule(
        hour: settings.notificationHour,
        minute: settings.notificationMinute,
      );
    } else {
      await NotificationService.cancel();
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final settings = context.appState.settings;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.notificationHour,
        minute: settings.notificationMinute,
      ),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !context.mounted) return;

    final appState = context.appState;
    appState.updateSettings(
      settings.copyWith(
        notificationHour: picked.hour,
        notificationMinute: picked.minute,
      ),
    );
    if (appState.settings.dailyNotification) {
      await NotificationService.schedule(
        hour: picked.hour,
        minute: picked.minute,
      );
    }
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.appState.settings;
    final enabled = settings.dailyNotification;

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
          // ── Toggle card ─────────────────────────────────────────────────
          _Card(
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
                    enabled
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    color: enabled
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
                        context.t('notification.dailyReminder'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        enabled
                            ? context.t('notification.reminderOn')
                            : context.t('notification.reminderOff'),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: (v) => _toggleNotification(context, v),
                ),
              ],
            ),
          ),

          // ── Time picker ─────────────────────────────────────────────────
          if (enabled) ...[
            const SizedBox(height: 12),
            _Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _pickTime(context),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.appColors.cardSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.access_time_outlined,
                          color: AppColors.brandBlue,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.t('notification.reminderTime'),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.t('notification.reminderTimeHint'),
                              style: TextStyle(
                                fontSize: 12,
                                color: context.appColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatTime(
                          settings.notificationHour,
                          settings.notificationMinute,
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandBlue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: context.appColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Info box ───────────────────────────────────────────────────
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.brandBlue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.brandBlue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.t('notification.infoText', {
                        'time': _formatTime(
                          settings.notificationHour,
                          settings.notificationMinute,
                        ),
                      }),
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.outline),
      ),
      child: child,
    );
  }
}
