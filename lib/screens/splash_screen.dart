import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // Branding Colors
  static const neonGreen = Color(0xFF00FF85);
  static const bgBlack = Color(0xFF0A0A0A);

  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200), 
      vsync: this,
    );

    _scaleAnim = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final authService = AuthService();

    // Navigate and clear the splash from the stack
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => authService.isLoggedIn ? const HomeScreen() : const LoginScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      body: Center(
        child: FadeTransition(
          opacity: _opacityAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Minimalist Branding matching HAAAH SPORTS header
                const Text(
                  "HAAAH",
                  style: TextStyle(
                    color: neonGreen,
                    fontSize: 52, 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8, // Exaggerated spacing for elite look
                  ),
                ),
                const Text(
                  "SPORTS",
                  style: TextStyle(
                    color: Colors.white, // High contrast white
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
