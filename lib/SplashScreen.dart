import 'package:flutter/material.dart';
import 'package:myapp/AuthRepository.dart';
import 'package:myapp/HomePage.dart';
import 'package:myapp/LoginPage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'PermissaoPage.dart';

class SplashScreen extends StatefulWidget {
  final Stream<AuthState> stream;

  SplashScreen({Stream<AuthState>? stream, super.key})
    : stream = stream ?? AuthRepository.onAuthStateChange;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    AuthRepository.onAuthStateChange.listen((authState) {
      if (authState.session == null) {
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
      verificaPermissoes(context).then((concedidas) {
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
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.stream,
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
    return serviceStatus.isEnabled && location && camera && microphone;
  }
}
