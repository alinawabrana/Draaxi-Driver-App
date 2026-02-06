import 'package:draaxi_driver/src/router/app_routes.dart';
import 'package:draaxi_driver/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'DRAAXI DRIVER',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: ATheme.lightModeThemes,
        darkTheme: ATheme.darkModeThemes,
        routerConfig: AppRoutes.routes,
      ),
    );
  }
}
