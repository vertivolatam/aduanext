import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/router.dart';
import 'shared/theme/aduanext_theme.dart';

void main() {
  // `ProviderScope` is the Riverpod root container — VRTV-59 onboarding
  // providers live inside it, and future features (pre-validation,
  // classification) plug in here too without touching main.
  runApp(const ProviderScope(child: AduaNextApp()));
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
