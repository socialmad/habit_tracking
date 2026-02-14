import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_tracker/core/services/motivation_service.dart';
import 'package:habit_tracker/features/habit/presentation/widgets/motivational_overlay.dart';
import '../../injection_container.dart' as di;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/habit/presentation/bloc/habit_bloc.dart';

class MainWrapper extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainWrapper({required this.navigationShell, super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showMotivationalOverlay();
    });
  }

  void _showMotivationalOverlay() {
    final motivationService = di.sl<MotivationService>();
    final quote = motivationService.getRandomQuote();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Motivational Overlay",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: MotivationalOverlay(
            quote: quote,
            onDismiss: () => Navigator.of(context).pop(),
          ),
        );
      },
    );
  }

  void _goBranch(int index) {
    if (index == 0) {
      context.read<HabitBloc>().add(
        const LoadHabits(categoryId: null, updateCategory: true),
      );
    }

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        destinations: const [
          NavigationDestination(
            label: 'Habits',
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
          ),
          NavigationDestination(
            label: 'Stats',
            icon: Icon(Icons.bar_chart),
            selectedIcon: Icon(Icons.bar_chart),
          ),
          NavigationDestination(
            label: 'Categories',
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
          ),
        ],
        onDestinationSelected: _goBranch,
      ),
    );
  }
}
