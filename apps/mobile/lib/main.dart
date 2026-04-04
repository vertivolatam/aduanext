import 'package:flutter/material.dart';
import 'routing/router.dart';
import 'shared/theme/aduanext_theme.dart';

void main() {
  runApp(const AduaNextApp());
}

class AduaNextApp extends StatelessWidget {
  const AduaNextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AduaNext',
      debugShowCheckedModeBanner: false,
      theme: AduaNextTheme.darkTheme,
      routerConfig: router,
    );
  }
}
