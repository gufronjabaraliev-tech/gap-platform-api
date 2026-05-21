import 'package:flutter/material.dart';

import '../theme/gap_icons.dart';

class RemoteOnboardingPage {
  const RemoteOnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    this.isLast = false,
  });

  final String title;
  final String description;
  final String icon;
  final bool isLast;

  factory RemoteOnboardingPage.fromJson(Map<String, dynamic> json) {
    return RemoteOnboardingPage(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'groups',
      isLast: json['isLast'] as bool? ?? false,
    );
  }

  IconData get iconData => iconNameToIconData(icon);
}

class RemoteAdPlacement {
  const RemoteAdPlacement({
    this.enabled = false,
    this.title = '',
    this.subtitle = '',
    this.imageUrl = '',
    this.linkUrl = '',
    this.backgroundColor = '#047857',
  });

  final bool enabled;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String linkUrl;
  final String backgroundColor;

  factory RemoteAdPlacement.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RemoteAdPlacement();
    return RemoteAdPlacement(
      enabled: json['enabled'] as bool? ?? false,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      linkUrl: json['linkUrl'] as String? ?? '',
      backgroundColor: json['backgroundColor'] as String? ?? '#047857',
    );
  }

  Color get background => _parseColor(backgroundColor);
}

class RemoteAppConfig {
  const RemoteAppConfig({
    this.onboardingPages = const [],
    this.adsEnabled = false,
    this.myGroupsBanner = const RemoteAdPlacement(),
    this.maintenanceEnabled = false,
    this.maintenanceMessage = '',
  });

  final List<RemoteOnboardingPage> onboardingPages;
  final bool adsEnabled;
  final RemoteAdPlacement myGroupsBanner;
  final bool maintenanceEnabled;
  final String maintenanceMessage;

  factory RemoteAppConfig.fromPayload(Map<String, dynamic> json) {
    final config = json['config'] as Map<String, dynamic>? ?? {};
    final onboarding = config['onboarding'] as Map<String, dynamic>? ?? {};
    final pagesRaw = onboarding['pages'] as List<dynamic>? ?? [];
    final ads = config['ads'] as Map<String, dynamic>? ?? {};
    final placements = ads['placements'] as Map<String, dynamic>? ?? {};
    final maintenance = config['maintenance'] as Map<String, dynamic>? ?? {};

    return RemoteAppConfig(
      onboardingPages: pagesRaw
          .map((e) => RemoteOnboardingPage.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      adsEnabled: ads['enabled'] as bool? ?? false,
      myGroupsBanner: RemoteAdPlacement.fromJson(
        placements['my_groups_banner'] as Map<String, dynamic>?,
      ),
      maintenanceEnabled: maintenance['enabled'] as bool? ?? false,
      maintenanceMessage: maintenance['message'] as String? ?? '',
    );
  }
}

IconData iconNameToIconData(String name) {
  switch (name) {
    case 'visibility':
      return Icons.visibility_rounded;
    case 'people':
      return Icons.people_rounded;
    case 'bar_chart':
      return Icons.bar_chart_rounded;
    case 'savings':
      return GapIcons.brand;
    case 'wallet':
      return GapIcons.payments;
    case 'security':
      return Icons.security_rounded;
    case 'star':
      return Icons.star_rounded;
    case 'groups':
    default:
      return Icons.groups_rounded;
  }
}

Color _parseColor(String hex) {
  var h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  if (v == null) return const Color(0xFF047857);
  return Color(v);
}
