import 'dart:ffi';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyAppController {
  static final supabase = Supabase.instance.client;
  bool _ativo = false;

  void _estaAtivo() async {
    if (!_ativo) {
      await Supabase.initialize(
        url: 'https://yombhmzdpmffekqhdtrv.supabase.co',
        anonKey: 'sb_publishable_WnnTd11M1Lv_n5ookD45uQ_ZJYzav3l',
      );
    }
  }

  Future<void> verificaAutenticacao(OAuthProvider provider) {
    _estaAtivo();
    return Supabase.instance.client.auth.signInWithOAuth(
      provider,
      // O redirectTo deve ser o Deep Link configurado no seu app
      // Exemplo: 'com.seunome.infrasantacruz://login-callback/'
      redirectTo: 'io.infrasantacruz://login-callback/',
    );
  }

  void _verificaUsuarioAtual() async {
    _estaAtivo();
    try {
      await supabase.auth.getUser();
    } catch (e) {}
  }

  void fazLogin() async {
    _estaAtivo();
    const webClientId =
        '331259660582-ad7tveftb2oombhg4t6m3dt0jgotmgsf.apps.googleusercontent.com';
    const iosClientId =
        '331259660582-tniqrj7u0s63t1mf1r504ieb9c4lqo6q.apps.googleusercontent.com';
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        clientId: iosClientId,
        serverClientId: webClientId,
      );
      final account = await googleSignIn.authenticate();
      supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: account.authentication.idToken!,
      );
    } catch (e) {}
  }

  Future<List<FileObject>> listaImagens(String postId) async {
    return supabase.storage.from('posts').list(path: postId);
  }

  Future<List<Map<String, dynamic>>> listaPosts() async {
    _estaAtivo();
    return supabase.from('teste').select();
  }

  Future<String> uploadFile(File file) async {
    _estaAtivo();
    final now = DateTime.now().toString();
    final result = await Supabase.instance.client.storage
        .from('posts')
        .upload('teste1/$now', file);
    return result;
  }

  void onAuthChanged(void Function(AuthState) onStateChange) {
    _estaAtivo();
    supabase.auth.onAuthStateChange.listen(onStateChange);
  }
}
