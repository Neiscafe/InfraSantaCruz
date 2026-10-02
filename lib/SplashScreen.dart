import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myapp/AuthRepository.dart';
import 'package:myapp/HomePage.dart';
import 'package:myapp/LoginPage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'PermissaoPage.dart';

class SplashScreen extends StatefulWidget {
  SplashScreen({Stream<AuthState>? stream, super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late StreamSubscription<AuthState> streamSubscription;

  @override
  void initState() {
    super.initState();
    streamSubscription = AuthRepository.onAuthStateChange.listen((
      authState,
    ) async {
      if (authState.session == null) {
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return LoginPage();
            },
          ),
        );
        return;
      }
      await AuthRepository.sendFirebaseToken();
      if (!context.mounted) return;
      verificaPermissoes(context).then((concedidas) {
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              if (concedidas) {
                return HomePage();
              } else {
                return PermissaoPage();
              }
            },
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthRepository.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                // Logo Centralizada
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/icons/logo-texto.png', width: 200),
                      SizedBox(height: 24),
                      // Indicador de carregamento em Azul (cor da sua logo)
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF0056b3),
                        ),
                      ),
                    ],
                  ),
                ),
                // Texto ou rodapé em Cinza
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 30),
                    child: Text(
                      "InfraSantaCruz © 2026",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Placeholder();
        }
      },
    );
  }

  Future<bool> verificaPermissoes(BuildContext context) async {
    ServiceStatus serviceStatus = await Permission.location.serviceStatus;
    final location = await Permission.location.isGranted;
    final camera = await Permission.camera.isGranted;
    final microphone = await Permission.microphone.isGranted;
    final notification = await Permission.notification.isGranted;
    return serviceStatus.isEnabled &&
        location &&
        camera &&
        microphone &&
        notification;
  }
}
