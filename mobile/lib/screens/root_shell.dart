import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import 'classes_screen.dart';
import 'dashboard_screen.dart';
import 'fiche_form_screen.dart';
import 'history_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  void goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            DashboardScreen(onGoToTab: goToTab),
            ClassesScreen(onGoToTab: goToTab),
            HistoryScreen(onGoToTab: goToTab),
            const FicheFormScreen(embedded: true),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: _index, onTap: goToTab),
    );
  }
}
