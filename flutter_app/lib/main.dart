import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/bridge/frb_generated.dart';
import 'src/screens/root_shell.dart';
import 'src/services/budget_service.dart';
import 'src/services/db_service.dart';
import 'src/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF06060C),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await RustLib.init();
  await DbService.instance.init();
  await BudgetService.instance.init();
  runApp(const ProviderScope(child: ExpenseApp()));
}

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = buildAppTheme();
    return MaterialApp(
      title: 'Lumen — Expense Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: theme,
      theme: theme,
      home: const RootShell(),
    );
  }
}
