import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/bridge/frb_generated.dart';
import 'src/screens/root_shell.dart';
import 'src/screens/splash_screen.dart';
import 'src/services/db_service.dart';
import 'src/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.cream,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  await RustLib.init();
  await DbService.instance.init();
  runApp(const ProviderScope(child: SlipApp()));
}

class SlipApp extends StatelessWidget {
  const SlipApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = buildAppTheme();
    return MaterialApp(
      title: 'Slip',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: theme,
      home: const _SplashGate(),
    );
  }
}

class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _ready = false;

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return SplashScreen(onDone: () => setState(() => _ready = true));
    }
    return const RootShell();
  }
}
