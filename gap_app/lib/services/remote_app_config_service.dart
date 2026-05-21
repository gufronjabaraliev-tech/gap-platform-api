import '../models/remote_app_config.dart';
import 'platform_api_service.dart';

/// Admin paneldan keladigan remote config (onboarding, reklama).
class RemoteAppConfigService {
  RemoteAppConfigService._();
  static final RemoteAppConfigService instance = RemoteAppConfigService._();

  RemoteAppConfig? _config;

  RemoteAppConfig? get config => _config;

  List<RemoteOnboardingPage> get onboardingPages =>
      _config?.onboardingPages ?? [];

  bool get hasRemoteOnboarding => onboardingPages.isNotEmpty;

  Future<void> refresh() async {
    final raw = await PlatformApiService.instance.fetchAppConfig();
    if (raw != null) {
      _config = RemoteAppConfig.fromPayload(raw);
    }
  }
}
