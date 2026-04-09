import 'package:flutter/material.dart';

import '../../../core/localization/transalation_extansions.dart';
import '../../../core/theme/app_colors.dart';

enum HistoryFilter {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  custom,
}

extension HistoryFilterExtension on HistoryFilter {
  String get labelKey {
    switch (this) {
      case HistoryFilter.today:
        return 'history.filter.today';
      case HistoryFilter.yesterday:
        return 'history.filter.yesterday';
      case HistoryFilter.thisWeek:
        return 'history.filter.thisWeek';
      case HistoryFilter.lastWeek:
        return 'history.filter.lastWeek';
      case HistoryFilter.thisMonth:
        return 'history.filter.thisMonth';
      case HistoryFilter.lastMonth:
        return 'history.filter.lastMonth';
      case HistoryFilter.custom:
        return 'history.filter.custom';
    }
  }

  IconData get icon {
    switch (this) {
      case HistoryFilter.today:
        return Icons.today;
      case HistoryFilter.yesterday:
        return Icons.history;
      case HistoryFilter.thisWeek:
        return Icons.date_range;
      case HistoryFilter.lastWeek:
        return Icons.calendar_view_week;
      case HistoryFilter.thisMonth:
        return Icons.calendar_month;
      case HistoryFilter.lastMonth:
        return Icons.event_note;
      case HistoryFilter.custom:
        return Icons.edit_calendar;
    }
  }
}

class HistoryFilterSheet extends StatelessWidget {
  const HistoryFilterSheet({
    super.key,
    required this.selectedFilter,
    required this.onSelect,
  });

  final HistoryFilter selectedFilter;
  final ValueChanged<HistoryFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.t('history.filter.selectPeriod'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          ...HistoryFilter.values.map((filter) {
            final isSelected = filter == selectedFilter;
            
            if (filter == HistoryFilter.custom) {
               return Padding(
                 padding: const EdgeInsets.only(top: 12),
                 child: SizedBox(
                   width: double.infinity,
                   child: ElevatedButton.icon(
                     onPressed: () => onSelect(filter),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.cardSoft,
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(12),
                         side: const BorderSide(color: AppColors.outline),
                       ),
                       elevation: 0,
                     ),
                     icon: const Icon(Icons.calendar_month, color: Colors.white),
                     label: Text(
                       context.t(filter.labelKey),
                       style: const TextStyle(
                         color: Colors.white,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   ),
                 ),
               );
            }

            return InkWell(
              onTap: () => onSelect(filter),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandBlue.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border.all(color: AppColors.brandBlue) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      filter.icon,
                      color: isSelected ? AppColors.brandBlue : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.t(filter.labelKey),
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.brandBlue,
                        size: 20,
                      )
                    else
                      const Icon(
                        Icons.circle_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
