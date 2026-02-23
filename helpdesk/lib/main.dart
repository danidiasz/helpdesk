import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'nav.dart';
import 'data/auth_provider.dart';
import 'data/data_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()..init()),
      ],
      child: MaterialApp.router(
        title: 'HelpDesk AI',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme, // Using same theme for now as requested vibrant colors
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
           Locale('pt', 'BR'),
        ],
      ),
    );
  }
}
