import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/app/app_provider.dart';
import '../features/wallet/wallet_provider.dart';
import '../injection.dart';
import 'routes.dart';
import 'theme.dart';

class NexaApp extends StatelessWidget {
  const NexaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<AppProvider>()..initialize()),
        ChangeNotifierProvider(create: (_) => getIt<WalletProvider>()..initialize()),
      ],
      child: MaterialApp.router(
        title: 'Nexa App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
