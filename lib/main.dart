import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'theme/app_theme.dart';
import 'pages/api_page.dart';
import 'pages/system_status_page.dart';
import 'services/seo_service.dart';
import 'utils/nav_observer.dart';

void main() {
  // Enable Path URL strategy (removes # from URLs)
  usePathUrlStrategy();
  
  // Initialize SEO Service
  SeoService.init();
  
  runApp(const PesaCrowApp());
}

class PesaCrowApp extends StatelessWidget {
  const PesaCrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PesaCrow Developer Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // APIPage is now the entry point for this developer-only app
      initialRoute: '/',
      routes: {
        '/': (context) => const APIPage(),
        '/system-status': (context) => const SystemStatusPage(),
      },
      navigatorObservers: [
        SeoNavObserver(),
      ],
    );
  }
}
