import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '586392715477-bm6fenq8thefq3umgoe11895qkt2cku2.apps.googleusercontent.com',
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
    ],
  );

  Future<User?> signInWithGoogleFirebase() async {
  final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  if (googleUser == null) return null;

  final googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  UserCredential result = await _auth.signInWithCredential(credential);
  return result.user;
}

  Future<GoogleSignInAccount?> signInWithGoogleAccount() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    return googleUser;
  }

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
