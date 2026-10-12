import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../history/bloc/history_bloc.dart';
import '../history/history_view.dart';
import '../settings/bloc/settings_bloc.dart';
import '../settings/settings_view.dart';

/// Top-level navigation shell hosting the app's primary screens.
///
/// The capture/OCR/translation workflow is injected as [translateView]; this
/// task (T-052) wires in the History and Settings screens alongside it.
class HomeShell extends StatefulWidget {
  final HistoryBloc historyBloc;
  final SettingsBloc settingsBloc;
  final Widget translateView;

  const HomeShell({
    super.key,
    required this.historyBloc,
    required this.settingsBloc,
    required this.translateView,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    final destinations = <_Destination>[
      _Destination(
        icon: Icons.translate,
        label: 'Translate',
        view: widget.translateView,
      ),
      _Destination(
        icon: Icons.history,
        label: 'History',
        view: HistoryView(bloc: widget.historyBloc),
      ),
      _Destination(
        icon: Icons.settings,
        label: 'Settings',
        view: SettingsView(bloc: widget.settingsBloc),
      ),
    ];

    if (_isIOS) {
      return Scaffold(
        body: SafeArea(child: destinations[_index].view),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: [
            for (final destination in destinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                label: destination.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (index) => setState(() => _index = index),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final destination in destinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  label: Text(destination.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: destinations[_index].view),
        ],
      ),
    );
  }
}

class _Destination {
  final IconData icon;
  final String label;
  final Widget view;

  const _Destination({
    required this.icon,
    required this.label,
    required this.view,
  });
}
