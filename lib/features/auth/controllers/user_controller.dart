import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_controller.dart';

/// Pengelolaan profil & role pengguna (khusus admin).
///
/// Pembuatan akun Firebase Authentication tetap harus lewat Firebase Console
/// atau Admin SDK, karena Firebase Auth sisi klien hanya bisa mendaftarkan
/// akun baru sebagai pengguna yang sedang login.
class UserController {
  static const List<String> roles = ['admin', 'kasir'];

  final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

  /// Stream daftar pengguna untuk halaman kelola pengguna.
  Stream<List<UserModel>> getUsersStream() {
    if (!AuthController.isAdmin) {
      return Stream.value(const <UserModel>[]);
    }

    return _users.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Ubah role pengguna. Admin tidak boleh menurunkan role akunnya sendiri
  /// (dicegah juga oleh firestore.rules).
  Future<String?> updateRole({
    required String uid,
    required String role,
  }) async {
    if (!AuthController.isAdmin) {
      return 'Hanya admin yang dapat mengubah role pengguna.';
    }
    if (!roles.contains(role)) {
      return 'Role "$role" tidak dikenal.';
    }
    if (AuthController.currentUser?.id == uid) {
      return 'Role akun sendiri tidak dapat diubah.';
    }

    try {
      await _users.doc(uid).update({'role': role});
      return null;
    } catch (e) {
      return 'Gagal mengubah role: $e';
    }
  }

  /// Perbarui nama tampilan dan username pengguna.
  Future<String?> updateProfile({
    required String uid,
    required String name,
    required String username,
  }) async {
    if (!AuthController.isAdmin) {
      return 'Hanya admin yang dapat mengubah profil pengguna.';
    }

    final cleanName = name.trim();
    final cleanUsername = username.trim();

    if (cleanName.isEmpty) {
      return 'Nama pengguna wajib diisi.';
    }
    if (cleanName.length > 100) {
      return 'Nama pengguna maksimal 100 karakter.';
    }
    if (cleanUsername.length > 50) {
      return 'Username maksimal 50 karakter.';
    }

    try {
      await _users.doc(uid).update({
        'name': cleanName,
        'username': cleanUsername,
      });
      return null;
    } catch (e) {
      return 'Gagal memperbarui profil: $e';
    }
  }
}
