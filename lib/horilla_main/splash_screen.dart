import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../core/routes/app_routes.dart';
import '../res/consts/app_colors.dart';

class SplashScreen extends StatefulWidget {
  final bool isOnboarding;
  
  const SplashScreen({Key? key, this.isOnboarding = false}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();

    // Inicializa el controlador de animación
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    );

    // Solo redirige automáticamente si es onboarding
    if (widget.isOnboarding) {
      Future.delayed(const Duration(seconds: 25), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // PageView para las tres pantallas
          PageView(
            controller: _pageController,
            children: <Widget>[
              _buildPage(
                color: Colors.blue.shade100,
                animationUrl: 'https://lottie.host/46955ea6-063d-4e48-ab38-97040a7f47ea/99zGr5rsOP.json',
              ),
              _buildPage(
                color: lightBlueColor,
                animationUrl: 'https://lottie.host/0da0462e-96e1-4672-92fe-da330a424456/avQfH7GPce.json',
              ),
              _buildPage(
                color: Colors.white,
                animationUrl: 'https://lottie.host/0a14ac85-d7ec-49ca-8871-c493ab6effb7/i4K6AH4MdE.json',
              ),
            ],
          ),
          // Botón "Omitir" en la parte superior derecha
          Positioned(
            right: 20,
            top: 40,
            child: TextButton(
              onPressed: _navigateToLogin,
              child: const Text(
                'Omitir',
                style: TextStyle(color: Colors.indigo),
              ),
            ),
          ),
          // Botón "Siguiente" en la parte inferior derecha
          Positioned(
            right: 20,
            bottom: 20,
            child: TextButton(
              onPressed: () {
                if (_pageController.hasClients) {
                  final currentPage = _pageController.page?.toInt() ?? 0;
                  if (currentPage < 2) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  } else {
                    _navigateToLogin();
                  }
                } else {
                  _navigateToLogin();
                }
              },
              child: const Text(
                'Siguiente',
                style: TextStyle(color: Colors.indigo),
              ),
            ),
          ),
          // Indicador de puntos usando SmoothPageIndicator
          Positioned(
            bottom: 40,
            left: MediaQuery.of(context).size.width / 2 - 30,
            child: SmoothPageIndicator(
              controller: _pageController,
              count: 3,
              effect: const WormEffect(
                activeDotColor: Colors.blue,
                dotColor: Colors.grey,
                dotHeight: 5,
                dotWidth: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({required Color color, required String animationUrl}) {
    return Container(
      color: color,
      child: Center(
        child: Lottie.network(
          animationUrl,
          width: 500,
          height: 500,
          fit: BoxFit.contain,
          controller: _controller,
          onLoaded: (composition) {
            if (mounted) {
              _controller
                ..duration = composition.duration
                ..forward()
                ..repeat();
            }
          },
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'Error al cargar la animación',
              style: TextStyle(color: Colors.red),
            );
          },
          animate: true,
        ),
      ),
    );
  }
}