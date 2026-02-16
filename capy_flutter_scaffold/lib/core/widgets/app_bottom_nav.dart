import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentRoute,
  });

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    Future<void> switchTo(String route) async {
      if (route == currentRoute) {
        return;
      }
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, route);
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _NavButton(
                  icon: Icons.assignment,
                  assetPath: 'assets/icons/nav/nav_plan_active.png',
                  isActive: currentRoute == '/planner',
                  color: const Color(0xFFFF8C42),
                  onTap: () => switchTo('/planner'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NavButton(
                  icon: Icons.timer,
                  assetPath: 'assets/icons/nav/nav_timer_active.png',
                  isActive: currentRoute == '/timer',
                  color: const Color(0xFF4ECDC4),
                  onTap: () => switchTo('/timer'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NavButton(
                  icon: Icons.family_restroom,
                  assetPath: 'assets/icons/nav/nav_parent_active.png',
                  isActive: currentRoute == '/parent-dashboard',
                  color: const Color(0xFFA29BFE),
                  onTap: () => switchTo('/parent-dashboard'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NavButton(
                  icon: Icons.insights,
                  assetPath: 'assets/icons/nav/nav_score_active.png',
                  isActive: currentRoute == '/scores',
                  color: const Color(0xFF5C7CFA),
                  onTap: () => switchTo('/scores'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NavButton(
                  icon: Icons.spa,
                  assetPath: 'assets/icons/nav/nav_growth_active.png',
                  isActive: currentRoute == '/growth',
                  color: const Color(0xFFFD79A8),
                  onTap: () => switchTo('/growth'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isActive,
    this.assetPath,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isActive;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 64,
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(0, isActive ? -4 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: isActive ? 58 : 52,
              height: isActive ? 58 : 52,
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.20) : const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isActive ? color.withOpacity(0.42) : const Color(0xFFD0D5DD),
                  width: isActive ? 2 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.30),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: assetPath == null
                  ? Icon(
                      icon,
                      color: color,
                      size: isActive ? 36 : 30,
                    )
                  : ColorFiltered(
                      colorFilter: const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                      child: Image.asset(
                        assetPath!,
                        width: isActive ? 42 : 36,
                        height: isActive ? 42 : 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          icon,
                          color: color,
                          size: isActive ? 36 : 30,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
