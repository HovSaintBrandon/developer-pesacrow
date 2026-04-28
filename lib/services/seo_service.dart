import 'package:flutter/foundation.dart';
import 'package:meta_seo/meta_seo.dart';

class SeoService {
  static void updateMetadata({
    required String title,
    required String description,
    String? ogTitle,
    String? ogDescription,
    String? ogImage,
    List<String>? keywords,
  }) {
    if (kIsWeb) {
      final meta = MetaSEO();
      
      // Update Title
      meta.author(author: 'PesaCrow');
      
      // Dynamic Description
      meta.description(description: description);
      
      if (keywords != null && keywords.isNotEmpty) {
        meta.keywords(keywords: keywords.join(', '));
      }

      // Open Graph Tags for Social Sharing
      meta.ogTitle(ogTitle: ogTitle ?? title);
      meta.ogDescription(ogDescription: ogDescription ?? description);
      meta.ogImage(ogImage: ogImage ?? 'https://escrow.pesacrow.top/favicon.png');
      
      // Property Content for OG tags not explicitly in methods
      meta.propertyContent(property: 'og:type', content: 'website');
      meta.propertyContent(property: 'og:url', content: 'https://escrow.pesacrow.top/');
      
      // Twitter Card
      meta.twitterCard(twitterCard: TwitterCard.summaryLargeImage);
      meta.twitterTitle(twitterTitle: ogTitle ?? title);
      meta.twitterDescription(twitterDescription: ogDescription ?? description);
      meta.twitterImage(twitterImage: ogImage ?? 'https://escrow.pesacrow.top/favicon.png');
    }
  }

  static void init() {
    if (kIsWeb) {
      MetaSEO().config();
    }
  }
}
