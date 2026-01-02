import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/logger_provider.dart';
import 'core/config/api_config.dart';
import 'core/services/app_toast.dart';
import 'l10n/l10n.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Log environment configuration
  AppLogger.info('Starting Skillora Family App', context: {
    'environment': ApiConfig.environmentName,
    'apiBaseUrl': ApiConfig.baseUrl,
    'isDevelopment': ApiConfig.isDevelopment.toString(),
  });
  
  runApp(const ProviderScope(child: SkilloraFamilyApp()));
}

class SkilloraFamilyApp extends ConsumerStatefulWidget {
  const SkilloraFamilyApp({super.key});

  @override
  ConsumerState<SkilloraFamilyApp> createState() => _SkilloraFamilyAppState();
}

class _SkilloraFamilyAppState extends ConsumerState<SkilloraFamilyApp> {

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Skillora Family',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      routerConfig: router,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: const [
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
  }
}
