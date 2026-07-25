import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'views/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: MaterialApp(
        title: 'Bileto',
        debugShowCheckedModeBanner: false,

        // Türkçe Yerelleştirme
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('tr', 'TR'),
        ],

        // Ferah & Aydınlık Biletix Teması
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF4F6F9),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0066FF),
            primary: const Color(0xFF0066FF),
            surface: Colors.white,
            background: const Color(0xFFF4F6F9),
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0066FF),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
          ),
        ),

        home: const RootWidget(),
      ),
    );
  }
}

class RootWidget extends StatelessWidget {
  const RootWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.confirmation_number_rounded, size: 70, color: Color(0xFF0066FF)),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Color(0xFF0066FF)),
            ],
          ),
        ),
      );
    }

    return const MainNavigationScreen();
  }
}
