import 'package:flutter/material.dart';
import 'package:arena_futsal_app/services/sqlite_service.dart';
import 'screens/login_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbService = SqliteService();
  await dbService.init();

  await initializeDateFormatting('id_ID', null);

  runApp(const ArenaApp());
}

class ArenaApp extends StatelessWidget {
  const ArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arena Booking',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US'), Locale('id', 'ID')],
      home: const LoginScreen(),
    );
  }
}
