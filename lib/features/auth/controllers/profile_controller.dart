import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class ProfileController {
  final UserService _userService;
  final AuthService _authService;

  ProfileController({
    UserService? userService,
    AuthService? authService,
  })  : _userService = userService ?? UserService(),
        _authService = authService ?? AuthService();

  String? get currentEmail => _authService.currentUser?.email;

  Stream<UserModel?> watchProfile() {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _userService.watchUserProfile(uid);
  }

  Future<void> updateName(String name) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');
    await _userService.updateUserProfile(uid: uid, name: name);
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}