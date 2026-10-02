import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/LoginPage.dart';
import 'package:myapp/Usuario.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final Stream<AuthState> onAuthStateChange =
      Supabase.instance.client.auth.onAuthStateChange;
  static final auth = Supabase.instance.client.auth;

  static StreamSubscription<String>? _fcmTokenSubscription;
  static StreamSubscription<AuthState>? _sessionListenerSubscription;
  static bool _isShowingLoginRedirect = false;

  static Session? get session => auth.currentSession;

  static bool get isAuthenticated => session != null && !session!.isExpired;

  static Usuario? _usuarioAtual;

  static Usuario get usuarioAtual {
    return _usuarioAtual ?? _getUsuarioAtual();
  }

  static Usuario _getUsuarioAtual() {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception("Nenhum usuário autenticado encontrado.");
    }
    final usuario = Usuario.fromUser(user);
    _usuarioAtual = usuario;
    return usuario;
  }

  static void startSessionListener() {
    _sessionListenerSubscription?.cancel();
    _sessionListenerSubscription = onAuthStateChange.listen((authState) {
      final event = authState.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        if (session != null && !session!.isExpired) {
          sendFirebaseToken();
        }
      } else if (event == AuthChangeEvent.signedOut ||
          (event == AuthChangeEvent.tokenRefreshed &&
              authState.session == null)) {
        handleSessionExpired();
      }
    });
  }

  static Future<void> handleSessionExpired([BuildContext? context]) async {
    if (_isShowingLoginRedirect) return;
    _isShowingLoginRedirect = true;

    final navContext = context ?? navigatorKey.currentContext;
    if (navContext != null && navContext.mounted) {
      ScaffoldMessenger.of(navContext).showSnackBar(
        const SnackBar(
          content: Text(
            "Sua sessão expirou. Faça login novamente para continuar.",
          ),
          duration: Duration(seconds: 3),
        ),
      );

      await Navigator.of(navContext).push(
        MaterialPageRoute(
          builder: (context) => const LoginPage(isRedirect: true),
        ),
      );
    }
    _isShowingLoginRedirect = false;
  }

  static Future<void> initFirebaseMessaging() async {
    try {
      _fcmTokenSubscription?.cancel();
      _fcmTokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((
        newToken,
      ) async {
        if (session != null && !session!.isExpired) {
          await sendFirebaseToken(newToken);
        }
      });

      if (session != null && !session!.isExpired) {
        await sendFirebaseToken();
      }
    } catch (e) {
      debugPrint(
        "Erro ao inicializar Firebase Messaging no AuthRepository: $e",
      );
    }
  }

  static Future<void> signInWithOAuth(OAuthProvider provider) async {
    try {
      const webClientId =
          '331259660582-rm2737abqodpus6cukjokpegi585j66t.apps.googleusercontent.com';
      const iosClientId =
          '331259660582-p9gbvr7ptdes9okve2m7vk2ont170379.apps.googleusercontent.com';

      final scopes = ['email', 'profile'];
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        clientId: iosClientId,
        serverClientId: webClientId,
      );

      final googleUser =
          await googleSignIn.attemptLightweightAuthentication() ??
              await googleSignIn.authenticate();

      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(scopes) ??
              await googleUser.authorizationClient.authorizeScopes(scopes);

      final idToken = googleUser.authentication.idToken;

      if (idToken == null) {
        return;
      }

      await auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );

      await sendFirebaseToken();
    } on Exception catch(e, trace){
      debugPrint(trace.toString());
      debugPrint(e.toString());
      throw e;
    }
  }

  static Future<void> logout() async {
    try {
      final user = auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from("users")
            .update({"fcm_token": null})
            .eq("usuario_id", user.id);
      }
    } catch (_) {}

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}

    _fcmTokenSubscription?.cancel();
    _fcmTokenSubscription = null;
    _usuarioAtual = null;

    await auth.signOut();
  }

  static Future<void> sendFirebaseToken([String? explicitToken]) async {
    try {
      final user = auth.currentUser;
      if (user == null) return;
      final token =
          explicitToken ?? await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      try {
        await Supabase.instance.client.rpc(
          'link_fcm_token',
          params: {'p_user_id': user.id, 'p_fcm_token': token},
        );
      } catch (_) {
        await Supabase.instance.client
            .from("users")
            .update({"fcm_token": token})
            .eq("usuario_id", user.id);
      }
    } catch (e) {
      debugPrint("Erro ao enviar Firebase token: $e");
    }
  }
}
