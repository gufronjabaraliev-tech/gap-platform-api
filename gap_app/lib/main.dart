import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/group_chat_provider.dart';
import 'providers/groups_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'services/gap_notification_service.dart';
import 'services/auth_service.dart';
import 'services/bank_rates_service.dart';
import 'services/contact_photo_service.dart';
import 'services/group_chat_service.dart';
import 'services/group_service.dart';
import 'services/local_db_service.dart';
import 'services/member_link_service.dart';
import 'services/sms_otp_service.dart';
import 'theme/app_theme.dart';
import 'utils/route_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    ui.channelBuffers.resize('flutter/lifecycle', 10);
  }
  await GapNotificationService.instance.init();
  final db = LocalDbService();
  await db.init();

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  final memberLink = MemberLinkService(db);
  final smsOtp = SmsOtpService(db);
  await BankRatesService.instance.ensureLoaded();
  ContactPhotoService.instance.preload();
  runApp(GapApp(
    db: db,
    authService: AuthService(db, memberLink, smsOtp),
    groupService: GroupService(db),
    groupChatService: GroupChatService(db),
    memberLink: memberLink,
    themeProvider: themeProvider,
  ));
}

class GapApp extends StatelessWidget {
  const GapApp({
    super.key,
    required this.db,
    required this.authService,
    required this.groupService,
    required this.groupChatService,
    required this.memberLink,
    required this.themeProvider,
  });

  final LocalDbService db;
  final AuthService authService;
  final GroupService groupService;
  final GroupChatService groupChatService;
  final MemberLinkService memberLink;
  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(
          create: (_) => GroupsProvider(db, groupService, memberLink),
        ),
        ChangeNotifierProvider(
          create: (_) => GroupChatProvider(groupChatService),
        ),
        Provider<GroupChatService>.value(value: groupChatService),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'GAP',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: theme.mode,
            navigatorObservers: [gapRouteObserver],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
