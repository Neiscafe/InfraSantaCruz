import 'package:flutter/material.dart';
import 'package:myapp/MyAppController.dart';
import 'package:myapp/PermissaoPage.dart';
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
      switch (data.event) {
        case AuthChangeEvent.signedIn:
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => PermissaoPage()),
            );
          }
          break;
        default:
      }
    });
  }

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  void _handleOAuthLogin(OAuthProvider provider) {
    setState(() => _isLoading = true);
    controller.verificaAutenticacao(provider);
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
