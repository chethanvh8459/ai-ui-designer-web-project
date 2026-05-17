import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/theme_provider.dart';
import 'screens/welcome_screen.dart';
import 'package:ai_ui_designer_app/l10n/app_localizations.dart';
import 'package:stac/stac.dart';
import 'screens/login_screen.dart'; 
import 'screens/home_screen.dart';
// 🔥 ONLY ONE MAIN FUNCTION
void main() async {
  // 1. Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize the Mirai UI parser
  await Stac.initialize();
  // 3. Run the app with the ThemeProvider wrapped around it
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
// ... The rest of your code stays exactly the same from here down ...
  const MyApp({super.key});

  // 🌐 GLOBAL LANGUAGE SWITCH
  static void setLocale(BuildContext context, Locale newLocale) {
    final state =
        context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  // 🔥 ADD THIS (IMPORTANT)
  static _MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MyAppState>();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  // 🔥 expose locale
  Locale get locale => _locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🌐 LANGUAGE
      locale: _locale,

      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('kn'),
      ],

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 🔥 BETTER RESOLUTION HANDLING
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return supportedLocales.first;

        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode ==
              locale.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },

      // 🎨 THEME
     theme: ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF5F3EF),
  primaryColor: const Color(0xFF5A5563),
  cardColor: Colors.white,
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.black87),
  ),
),

darkTheme: ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF1E1E1E),
  primaryColor: const Color(0xFFA3B18A),
  cardColor: const Color(0xFF2A2A2A),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.white),
  ),
),
      themeMode: themeProvider.currentTheme,

     initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),     // Main link -> Get Started
        '/login': (context) => const LoginScreen(),  // /login link -> Login Page
        '/home': (context) => const HomeScreen(),    // /home link -> Dashboard
      },
    );
  }
}