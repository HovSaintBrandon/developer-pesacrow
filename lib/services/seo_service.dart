import 'package:flutter/foundation.dart';
import 'package:meta_seo/meta_seo.dart';
import 'package:web/web.dart' as web;

const String _siteOrigin = 'https://escrow.pesacrow.top';
const String _defaultOgImage = '$_siteOrigin/favicon.png';

class SeoService {
  /// Updates all per-route SEO signals: document title, meta description,
  /// keywords, canonical URL, robots directive, and social share tags.
  ///
  /// [path] must be the route path (e.g. '/system-status') and is used to
  /// build the canonical URL and og:url for that page. Without this, every
  /// route reports the homepage as its canonical, which confuses search
  /// engines about which page ranks for which query.
  static void updateMetadata({
    required String path,
    required String title,
    required String description,
    String? ogTitle,
    String? ogDescription,
    String? ogImage,
    List<String>? keywords,
    bool index = true,
  }) {
    if (!kIsWeb) return;

    final canonicalUrl = path == '/' ? '$_siteOrigin/' : '$_siteOrigin$path';
    final resolvedOgImage = ogImage ?? _defaultOgImage;

    // Document title isn't covered by meta_seo, so it's set directly.
    web.document.title = title;
    _setCanonical(canonicalUrl);

    final meta = MetaSEO();

    meta.author(author: 'PesaCrow');
    meta.description(description: description);

    if (keywords != null && keywords.isNotEmpty) {
      meta.keywords(keywords: keywords.join(', '));
    }

    meta.robots(
      robotsName: RobotsName.robots,
      content: index ? 'index, follow' : 'noindex, nofollow',
    );

    // Open Graph
    meta.ogTitle(ogTitle: ogTitle ?? title);
    meta.ogDescription(ogDescription: ogDescription ?? description);
    meta.ogImage(ogImage: resolvedOgImage);
    meta.propertyContent(property: 'og:type', content: 'website');
    meta.propertyContent(property: 'og:site_name', content: 'PesaCrow Developer Portal');
    meta.propertyContent(property: 'og:url', content: canonicalUrl);

    // Twitter Card
    meta.twitterCard(twitterCard: TwitterCard.summaryLargeImage);
    meta.twitterTitle(twitterTitle: ogTitle ?? title);
    meta.twitterDescription(twitterDescription: ogDescription ?? description);
    meta.twitterImage(twitterImage: resolvedOgImage);
  }

  static void _setCanonical(String url) {
    final existing = web.document.querySelector("link[rel='canonical']");
    if (existing != null) {
      existing.setAttribute('href', url);
      return;
    }
    final link = web.HTMLLinkElement()
      ..rel = 'canonical'
      ..href = url;
    web.document.head?.append(link);
  }

  static void init() {
    if (kIsWeb) {
      MetaSEO().config();
    }
  }
}
