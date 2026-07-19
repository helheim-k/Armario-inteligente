import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthController {
  final AuthService _authService;
  final UserService _userService;

  AuthController({
    AuthService? authService,
    UserService? userService,
  })  : _authService = authService ?? AuthService(),
        _userService = userService ?? UserService();

  bool get isLoggedIn => _authService.isLoggedIn;
  User? get currentUser => _authService.currentUser;
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _authService.login(email: email, password: password);
  }

  // Ahora orquesta: 1) crea el usuario en Firebase Auth, 2) crea su perfil en Firestore
  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _authService.register(
      email: email,
      password: password,
    );

    try {
      await _userService.createUserProfile(
        uid: credential.user!.uid,
        name: name,
        email: email,
      );
    } catch (e) {
      // El usuario ya se creó en Auth aunque falle Firestore.
      // No lo dejamos a medias: si el perfil no se pudo crear, deshacemos el registro.
      await credential.user?.delete();
      rethrow;
    }

    return credential;
  }

  Future<UserModel?> getUserProfile() {
    final uid = currentUser?.uid;
    if (uid == null) return Future.value(null);
    return _userService.getUserProfile(uid);
  }

  Future<void> logout() {
    return _authService.logout();
  }
}