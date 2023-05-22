import 'dart:io';

import 'package:biyi_app/includes.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:rise_ui/rise_ui.dart' as rise_ui;
import 'package:window_manager/window_manager.dart';

Future<void> _ensureInitialized() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  if (kIsLinux || kIsMacOS || kIsWindows) {
    await windowManager.ensureInitialized();
  }

  if (kIsMacOS || kIsWindows) {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    LaunchAtStartup.instance.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
    );
    await protocolHandler.register('biyiapp');
  }

  await initEnv();
  await initLocalDb();

  if (!kReleaseMode) {
    apiClient.setDebug();
  }
}

void main() async {
  await _ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale(kLanguageEN),
        Locale(kLanguageZH),
      ],
      path: 'assets/translations',
      assetLoader: YamlAssetLoader(),
      fallbackLocale: const Locale(kLanguageEN),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with LocalDbListener {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  Configuration get _configuration => localDb.configuration;

  @override
  void initState() {
    localDb.addListener(this);
    localDb.preferences.addListener(_handleChanged);
    super.initState();
  }

  @override
  void dispose() {
    localDb.removeListener(this);
    localDb.preferences.removeListener(_handleChanged);
    super.dispose();
  }

  void _handleChanged() async {
    Locale oldLocale = context.locale;
    Locale newLocale = languageToLocale(_configuration.appLanguage);
    if (newLocale != oldLocale) {
      await context.setLocale(newLocale);
    }

    await windowManager.setBrightness(
      _configuration.themeMode == ThemeMode.dark
          ? Brightness.dark
          : Brightness.light,
    );

    if (mounted) setState(() {});
  }

  Widget _buildHome(BuildContext context) {
    return const BootstrapPage();
  }

  @override
  Widget build(BuildContext context) {
    final virtualWindowFrameBuilder = VirtualWindowFrameInit();
    final botToastBuilder = BotToastInit();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: lightThemeData,
      darkTheme: darkThemeData,
      themeMode: _configuration.themeMode,
      builder: (context, child) {
        if (kIsLinux || kIsWindows) {
          child = Stack(
            children: [
              virtualWindowFrameBuilder(context, child),
              const DragToMoveArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 34,
                ),
              ),
            ],
          );
        }
        child = botToastBuilder(context, child);
        child = rise_ui.Theme(
          data: rise_ui.ThemeData(
            brightness: _configuration.themeMode == ThemeMode.dark
                ? Brightness.dark
                : Brightness.light,
          ),
          child: child,
        );
        return child;
      },
      navigatorObservers: [BotToastNavigatorObserver()],
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: _buildHome(context),
    );
  }

  @override
  void onUserChanged(User oldUser, User newUser) {
    _handleChanged();
  }
}
