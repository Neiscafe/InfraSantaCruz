import 'package:flutter/material.dart';
import 'package:myapp/AuthRepository.dart';
import 'package:myapp/ConnectivityWrapper.dart';
import 'package:myapp/SplashScreen.dart';

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
