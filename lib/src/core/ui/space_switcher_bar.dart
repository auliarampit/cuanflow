import 'package:flutter/material.dart';

import '../models/space_model.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_dynamic_colors.dart';

/// Tab switcher Ruang — hanya tampil jika user punya lebih dari 1 Ruang aktif.
class SpaceSwitcherBar extends StatelessWidget {
  const SpaceSwitcherBar({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final spaces = appState.spaces;

    if (spaces.length <= 1) return const SizedBox.shrink();

    return Container(
      color: context.appColors.card,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: spaces.map((space) {
                final isActive = space.id == appState.activeSpaceId;
                return Expanded(
                  child: _SpaceTab(
                    space: space,
                    isActive: isActive,
                    onTap: () => appState.switchSpace(space.id),
                  ),
                );
              }).toList(),
            ),
          ),
          Divider(height: 1, color: context.appColors.outline),
        ],
      ),
    );
  }
}

class _SpaceTab extends StatelessWidget {
  const _SpaceTab({
    required this.space,
    required this.isActive,
    required this.onTap,
  });

  final SpaceModel space;
  final bool isActive;
  final VoidCallback onTap;

  Color _accentColor(SpaceType type) => switch (type) {
        SpaceType.personal => AppColors.brandBlue,
        SpaceType.store => AppColors.positive,
        SpaceType.production => Colors.deepPurple,
      };

  String _emoji(SpaceType type) => switch (type) {
        SpaceType.personal => '💰',
        SpaceType.store => '🏪',
        SpaceType.production => '🏭',
      };

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(space.type);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isActive) ...[
              Text(_emoji(space.type), style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
            ],
            Text(
              space.type.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? accent : context.appColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
