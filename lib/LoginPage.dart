import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'AuthRepository.dart';

class LoginPage extends StatelessWidget {
  final Stream<AuthState> stream;

  LoginPage({Stream<AuthState>? authStream, super.key})
    : stream = authStream ?? AuthRepository.onAuthStateChange;

  void _handleOAuthLogin(OAuthProvider provider) {
    AuthRepository.signInWithOAuth(provider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sua Logo (conforme configurado nos assets anteriormente)
              Image.asset('assets/icons/logo-icone.png', height: 130),
              const SizedBox(height: 40),

              const Text(
                "InfraSantaCruz",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0056b3), // Azul da paleta solicitada
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Acesse para gerenciar sua infraestrutura",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 50),

              StreamBuilder(
                stream: stream,
                builder: (context, snapshot) {
                  // Loading
                  // ConnectionState.waiting
                  // ConnectionState.active(AuthChangeEvent.initialSession(session: session)
                  // ConnectionState.active(AuthChangeEvent.signedIn(session: session)

                  // Botões
                  // ConnectionState.active(AuthChangeEvent.initialSession(session: null)
                  // ConnectionState.active(AuthChangeEvent.signedOut(session: null)
                  if (snapshot.connectionState != ConnectionState.active ||
                      snapshot.data?.session != null) {
                    return const CircularProgressIndicator();
                  } else {
                    return Column(
                      children: [
                        _buildSocialButton(
                          label: "Continuar com Google",
                          icon: Icons.g_mobiledata,
                          color: Colors.white,
                          textColor: Colors.black87,
                          onPressed: () =>
                              _handleOAuthLogin(OAuthProvider.google),
                        ),
                        const SizedBox(height: 16),
                        _buildSocialButton(
                          label: "Continuar com Apple *Indisponível*",
                          icon: Icons.apple,
                          color: Colors.grey,
                          textColor: Colors.black,
                          onPressed: () => {},
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 50),
              const Text(
                "Acesse utilizando os provedores oficiais",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton.icon(
        iconAlignment: IconAlignment.start,
        icon: Icon(icon, color: textColor, size: 30),
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: color,
          side: const BorderSide(color: Color(0xFFE0E0E0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
