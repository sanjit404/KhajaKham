import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> signUpWithEmail(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) return "Please fill in all fields";
    if (!email.contains("@")) return "Enter a valid email";
    if (password.length < 6) return "Password must be at least 6 characters";

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await userCredential.user?.sendEmailVerification();
      return null; 
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Signup failed";
    } catch (_) {
      return "Signup failed";
    }
  }

  Future<String?> loginWithEmail(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) return "Please fill in all fields";

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (!userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
        return "Please verify your email. Verification sent!";
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Login failed";
    } catch (_) {
      return "Login failed";
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return "Google sign-in canceled";

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Google sign-in failed";
    } catch (_) {
      return "Google sign-in failed";
    }
  }

  Future<String?> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn(scopes: ['email']).signOut();
      return null;

    } catch (_) {
      return "Sign out failed";
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    if (email.trim().isEmpty) return "Enter your email";

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Password reset failed";
    } catch (_) {
      return "Password reset failed";
    }
  }

  User? get currentUser => _auth.currentUser;
}
