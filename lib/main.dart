import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'screens/splash_screen.dart';
import 'widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://xsyereeisjxeviajvyqo.supabase.co',
    anonKey: 'sb_publishable_FTy0BFus7buCVLZpZHIyeg_l3PvtNHk',
  );

  runApp(const HaaahApp());
}

class HaaahApp extends StatelessWidget {
  const HaaahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HAAAH Sports',
      debugShowCheckedModeBanner: false,
      theme: HaaahTheme.darkTheme,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              child!,
              const Positioned(top: 0, left: 0, right: 0, child: OfflineBanner()),
            ],
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}
