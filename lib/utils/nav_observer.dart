import 'package:flutter/material.dart';
import '../services/seo_service.dart';

class SeoNavObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateSeo(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _updateSeo(previousRoute);
    }
  }

  void _updateSeo(Route<dynamic> route) {
    final String? routeName = route.settings.name;
    
    switch (routeName) {
      case '/':
        SeoService.updateMetadata(
          title: 'Developer Portal | PesaCrow',
          description: 'Integrate PesaCrow escrow directly into your applications with our robust API documentation and SDKs.',
          keywords: ['escrow api', 'developer documentation', 'm-pesa integration', 'developer portal'],
        );
        break;
      case '/system-status':
        SeoService.updateMetadata(
          title: 'System Status | PesaCrow',
          description: 'Real-time status and incident monitoring for PesaCrow API and external dependencies.',
          keywords: ['system status', 'api health', 'uptime', 'pesacrow status'],
        );
        break;
    }
  }
}
