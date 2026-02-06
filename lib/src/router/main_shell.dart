import 'package:draaxi_driver/src/router/router.dart';
import 'package:draaxi_driver/utils/helpers/helper_function.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.contains('/home')) {
      return 0;
    } else if (location.contains('/wallet')) {
      return 1;
    } else if (location.contains('/chat')) {
      return 2;
    } else if (location.contains('/profile')) {
      return 3;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed(ARouter.home);
        break;
      case 1:
        context.goNamed(ARouter.wallet);
        break;
      case 2:
        context.goNamed(ARouter.chat);
        break;
      case 3:
        context.goNamed(ARouter.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = AHelperFunction.isDarkMode(context);
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark
            ? theme.colorScheme.surface
            : Colors.white,
        selectedItemColor: const Color(0xFFFEC400),
        unselectedItemColor: isDark
            ? const Color(0xFFD0D0D0)
            : const Color(0xFF414141),
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

