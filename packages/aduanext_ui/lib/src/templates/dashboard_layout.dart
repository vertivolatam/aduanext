import 'package:flutter/material.dart';
import '../organisms/sidebar_rail.dart';
import '../organisms/sidebar_panel.dart';

/// Main layout template: Rail + Panel + Content.
/// Responsive: panel collapses on narrow screens.
class DashboardLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final ValueChanged<String> onNavigate;

  const DashboardLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  int _selectedSection = 0;
  bool _panelExpanded = true;

  int _sectionFromRoute(String route) {
    if (['/exports', '/imports', '/rectifications', '/drafts'].contains(route)) return 0;
    if (['/classify', '/risk', '/exchange'].contains(route)) return 1;
    if (['/agents', '/sourcers'].contains(route)) return 2;
    if (['/audit', '/settings'].contains(route)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final showPanel = width > 768;
    final panelVisible = showPanel && _panelExpanded;

    return Scaffold(
      body: Row(
        children: [
          // Rail (always visible)
          SidebarRail(
            selectedIndex: _selectedSection,
            hasNotification: true,
            onSelected: (index) {
              setState(() {
                if (_selectedSection == index) {
                  _panelExpanded = !_panelExpanded;
                } else {
                  _selectedSection = index;
                  _panelExpanded = true;
                }
              });
            },
          ),
          // Panel (collapsible)
          if (panelVisible)
            SidebarPanel(
              selectedSection: _selectedSection,
              selectedItem: widget.currentRoute,
              onItemSelected: (route) {
                setState(() => _selectedSection = _sectionFromRoute(route));
                widget.onNavigate(route);
              },
            ),
          // Divider
          if (panelVisible)
            const VerticalDivider(width: 1, color: Color(0xFF1A1A2E)),
          // Content
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
