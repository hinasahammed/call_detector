import 'dart:async';

import 'package:call_detector/view/home/home_view.dart';
import 'package:call_detector/view/login/login_view.dart';
import 'package:call_detector/viewmodel/splash/splash_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  @override
  void initState() {
    nextScreen();
    super.initState();
  }

  void nextScreen() {
    final viewmodel = ref.read(splashViewmodelProvider.notifier);
    final isLogedin = viewmodel.isLogedIn();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              isLogedin ? const HomeView() : const LoginView(),
        ),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
