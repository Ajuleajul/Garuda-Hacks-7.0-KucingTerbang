import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/curamind_theme.dart';

class NavDestination {
  const NavDestination({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class CuramindAppHeader extends StatelessWidget implements PreferredSizeWidget {
  const CuramindAppHeader({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.userLabel,
  });

  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String? userLabel;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CuramindColors.white.withValues(alpha: 0.92),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: CuramindColors.mistBlue),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Curamind',
                style: GoogleFonts.fraunces(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: CuramindColors.ink,
                  letterSpacing: -0.4,
                ),
              ),
              if (userLabel != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CuramindColors.mistBlue,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    userLabel!,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CuramindColors.ocean,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 16),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(destinations.length, (i) {
                        final dest = destinations[i];
                        final selected = i == selectedIndex;
                        return Padding(
                          padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                          child: _NavChip(
                            label: dest.label,
                            icon: dest.icon,
                            selected: selected,
                            onTap: () => onDestinationSelected(i),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? CuramindColors.sageDeep
          : CuramindColors.mist.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? CuramindColors.white
                    : CuramindColors.inkMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? CuramindColors.white
                      : CuramindColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
