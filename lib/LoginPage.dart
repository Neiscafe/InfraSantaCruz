import 'package:flutter/material.dart';
import 'package:myapp/PermissaoPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && mounted) {
        setState(() => _isLoading = false);
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => PermissaoPage()));
      }
    });
  }

  void _handleOAuthLogin(OAuthProvider provider) {
    setState(() => _isLoading = true);
    Supabase.instance.client.auth.signInWithOAuth(
      provider,
      // O redirectTo deve ser o Deep Link configurado no seu app
      // Exemplo: 'com.seunome.infrasantacruz://login-callback/'
      redirectTo: 'io.infrasantacruz://login-callback/',
    );
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

              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                // Botão Google via OAuth
                _buildSocialButton(
                  label: "Continuar com Google",
                  icon: Icons.g_mobiledata,
                  color: Colors.white,
                  textColor: Colors.black87,
                  onPressed: () => _handleOAuthLogin(OAuthProvider.google),
                ),

                const SizedBox(height: 16),

                // Botão Apple via OAuth
                _buildSocialButton(
                  label: "Continuar com Apple *Indisponível*",
                  icon: Icons.apple,
                  color: Colors.grey,
                  textColor: Colors.black,
                  onPressed: () => {},
                ),
              ],

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
