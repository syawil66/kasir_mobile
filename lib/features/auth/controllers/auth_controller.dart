import '../models/user_model.dart';

class AuthController {
  UserModel? currentUser;

  // Simulasi login sederhana
  bool login(String username, String password) {
    if (username == 'admin' && password == '12345') {
      currentUser = UserModel(
        id: 'USR001',
        username: 'admin',
        name: 'Kasir Admin',
        role: 'Admin Toko',
      );
      return true;
    }
    return false;
  }
}