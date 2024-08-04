import 'dart:async';
import 'package:flutter/material.dart';
import 'package:photo_gallery_app/screens/image_uploader.dart';
import 'package:photo_gallery_app/utils/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  Timer? _loadingTimer;
  int _dotsCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    startSplashScreenTimer();
  }

  @override
  void dispose() {
    _controller.dispose();
    _loadingTimer?.cancel();
    super.dispose();
  }

  void startSplashScreenTimer() {
    Timer(const Duration(seconds: 3), () {
      setState(() {
        startLoadingDotsAnimation();
      });
    });
  }

  void startLoadingDotsAnimation() {
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        _dotsCount = (_dotsCount + 1) % 4;
      });
    });

    Timer(const Duration(seconds: 3), () {
      _loadingTimer?.cancel();
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ImageUploader()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FadeTransition(
              opacity: _fadeInAnimation,
              child: Image.asset(
                'assets/images/logo.png',
                width: 150,
                height: 150,
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _fadeInAnimation,
              child: const Text(
                'Photo Vault',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _dotsCount == 0
                ? FadeTransition(
                    opacity: _fadeInAnimation,
                    child:  Container()
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        _dotsCount,
                        (index) =>
                            const Text('.', style: TextStyle(fontSize: 40))),
                  ),
          ],
        ),
      ),
    );
  }
}
