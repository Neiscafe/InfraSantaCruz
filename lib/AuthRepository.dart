import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  static final Stream<AuthState> onAuthStateChange =
      Supabase.instance.client.auth.onAuthStateChange;
  static final auth = Supabase.instance.client.auth;

  static Session? get session => auth.currentSession;

  static Future<void> signInWithOAuth(OAuthProvider provider) async {
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
  }
}
