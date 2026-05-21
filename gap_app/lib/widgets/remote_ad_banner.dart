import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/remote_app_config.dart';
import '../services/remote_app_config_service.dart';
import 'gap_sliding_text.dart';

/// Admin paneldan boshqariladigan reklama banneri.
class RemoteAdBanner extends StatelessWidget {
  const RemoteAdBanner({super.key, this.placement = 'my_groups_banner'});

  final String placement;

  @override
  Widget build(BuildContext context) {
    final cfg = RemoteAppConfigService.instance.config;
    if (cfg == null || !cfg.adsEnabled) return const SizedBox.shrink();

    final RemoteAdPlacement ad;
    if (placement == 'my_groups_banner') {
      ad = cfg.myGroupsBanner;
    } else {
      return const SizedBox.shrink();
    }

    if (!ad.enabled || (ad.title.isEmpty && ad.subtitle.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: ad.background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: ad.linkUrl.isEmpty
              ? null
              : () {
                  final uri = Uri.tryParse(ad.linkUrl);
                  if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                if (ad.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      ad.imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 56,
                        height: 56,
                      ),
                    ),
                  ),
                if (ad.imageUrl.isNotEmpty) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ad.title.isNotEmpty)
                        GapSlidingText(
                          text: ad.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      if (ad.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          ad.subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (ad.linkUrl.isNotEmpty)
                  Icon(
                    Icons.open_in_new_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
