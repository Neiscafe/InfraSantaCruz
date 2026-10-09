import 'package:flutter/material.dart';
import 'package:myapp/feature/startup/ConnectivityWrapper.dart';
import 'package:myapp/feature/startup/SplashScreen.dart';

import '../data/repository/AuthRepository.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AuthRepository.navigatorKey,
      title: 'InfraSantaCruz',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      builder: (context, child) {
        return ConnectivityWrapper(child: child ?? const SizedBox.shrink());
      },
      home: SplashScreen(),
    );
  }
}
