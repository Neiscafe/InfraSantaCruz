import 'package:flutter/material.dart';
import 'package:myapp/MyAppController.dart';
import 'package:myapp/HomePage.dart';
import 'package:myapp/PermissaoPage.dart';
import 'package:myapp/SplashScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final controller = MyAppController();

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  void checkAuth() {
    controller.onAuthChanged((data) {
      final session = data.session;
      if (session != null) {
        // Usuário logado -> Vai para Home
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => PermissaoPage()));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  /// --- LOGIN OAUTH (Navegador) ---
  Future<void> _handleOAuthLogin(OAuthProvider provider) async {
    setState(() => _isLoading = true);
    try {
      await controller.verificaAutenticacao(provider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao entrar com ${provider.name}: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
            Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => PermissaoPage()));
    }
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
                  label: "Continuar com Apple",
                  icon: Icons.apple,
                  color: Colors.black,
                  textColor: Colors.white,
                  onPressed: () => _handleOAuthLogin(OAuthProvider.apple),
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
        icon: Icon(icon, color: textColor, size: 30),
        label: Text(
          label,
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

// final supabase = Supabase.instance.client;

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   void _initAuth() {
//     _verificaUsuarioAtual();
//     supabase.auth.onAuthStateChange.listen((data) {
//       final event = data.event;
//       if (event == AuthChangeEvent.signedIn) {
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(builder: (context) => MyHomePage()),
//         );
//       }
//     });
//   }

//   void _verificaUsuarioAtual() async {
//     try {
//       final userResponse = await supabase.auth.getUser();
//       print(userResponse.user);
//       Navigator.of(
//         context,
//       ).pushReplacement(MaterialPageRoute(builder: (context) => MyHomePage()));
//     } catch (e) {}
//   }

//   void _fazLogin() async {
//     const webClientId =
//         '331259660582-ad7tveftb2oombhg4t6m3dt0jgotmgsf.apps.googleusercontent.com';
//     const iosClientId =
//         '331259660582-tniqrj7u0s63t1mf1r504ieb9c4lqo6q.apps.googleusercontent.com';
//     try {
//       final googleSignIn = GoogleSignIn.instance;
//       await googleSignIn.initialize(
//         clientId: iosClientId,
//         serverClientId: webClientId,
//       );
//       final account = await googleSignIn.authenticate();
//       supabase.auth.signInWithIdToken(
//         provider: OAuthProvider.google,
//         idToken: account.authentication.idToken!,
//       );
//     } catch (e) {}
//   }

//   @override
//   void initState() {
//     super.initState();
//     _initAuth();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           children: [
//             ElevatedButton(
//               onPressed: () {
//                 _fazLogin();
//               },
//               child: Text("Fazer login"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
