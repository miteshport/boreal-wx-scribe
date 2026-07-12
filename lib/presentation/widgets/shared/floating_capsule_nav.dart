/// floating_capsule_nav.dart
///
/// Floating Frosted-Glass Capsule Navigation Bar
/// ─────────────────────────────────────────────────────────────────────────
/// A pill-shaped, BackdropFilter-blurred navigation widget that floats
/// above the dashboard content at the bottom of the screen.
/// Contains a slide-toggle between "DAILY SURVIVAL" and "WEEKEND ESCAPE".
library floating_capsule_nav;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';

enum DashboardTab { dailySurvival, weekendEscape }

class FloatingCapsuleNav extends StatefulWidget {
  final DashboardTab activeTab;
  final ValueChanged<DashboardTab> onTabChanged;

  const FloatingCapsuleNav({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  State<FloatingCapsuleNav> createState() => _FloatingCapsuleNavState();
}

class _FloatingCapsuleNavState extends State<FloatingCapsuleNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCubic,
    );
    if (widget.activeTab == DashboardTab.weekendEscape) {
      _slideController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(FloatingCapsuleNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeTab != oldWidget.activeTab) {
      if (widget.activeTab == DashboardTab.weekendEscape) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(60),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(60),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1,
            ),
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            return Stack(
              children: [
                // ── SLIDING ACTIVE INDICATOR ────────────────────────────
                AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, _) {
                    return Positioned.fill(
                      child: Align(
                        alignment: Alignment.lerp(
                          Alignment.centerLeft,
                          Alignment.centerRight,
                          _slideAnimation.value,
                        )!,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.pureWhite,
                              borderRadius: BorderRadius.circular(56),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // ── TAB BUTTONS ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _NavTab(
                        label: '🛡️  DAILY',
                        isActive: widget.activeTab == DashboardTab.dailySurvival,
                        onTap: () => widget.onTabChanged(DashboardTab.dailySurvival),
                      ),
                    ),
                    Expanded(
                      child: _NavTab(
                        label: '⛺  ESCAPE',
                        isActive: widget.activeTab == DashboardTab.weekendEscape,
                        onTap: () => widget.onTabChanged(DashboardTab.weekendEscape),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: AppTypography.labelMedium.copyWith(
          color: isActive ? AppColors.voidBlack : AppColors.pureWhite.withOpacity(0.55),
          fontSize: 13,
          letterSpacing: 1.5,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Center(child: Text(label)),
        ),
      ),
    );
  }
}
