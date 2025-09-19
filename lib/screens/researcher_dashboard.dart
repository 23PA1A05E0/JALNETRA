import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Researcher Dashboard - Clean minimal version
class ResearcherDashboard extends ConsumerStatefulWidget {
  const ResearcherDashboard({super.key});

  @override
  ConsumerState<ResearcherDashboard> createState() => _ResearcherDashboardState();
}

class _ResearcherDashboardState extends ConsumerState<ResearcherDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Researcher Dashboard'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: GoRouter.of(context).canPop()
          ? IconButton(
              icon: Icon(
                Theme.of(context).platform == TargetPlatform.iOS
                  ? Icons.arrow_back_ios
                  : Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () {
                context.pop();
              },
              tooltip: 'Back',
            )
          : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Researcher Dashboard',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
