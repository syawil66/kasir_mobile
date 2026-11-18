import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Menyimpan data user yang sedang login di memori aplikasi
  static UserModel? currentUser;

  // Helper untuk mengecek apakah user saat ini adalah admin
  static bool get isAdmin => currentUser?.role == 'admin';

  /// Mengembalikan null jika berhasil, atau pesan error (String) jika gagal
  Future<String?> login(String email, String password) async {
    try {
      // 1. Proses login ke Firebase Authentication
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        return 'Gagal mendapatkan ID pengguna.';
      }

      // 2. Ambil data profil & role dari koleksi 'users' di Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return 'Data role pengguna tidak ditemukan di database.';
      }

      // 3. Simpan ke state aktif aplikasi
      currentUser = UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
        uid,
      );

      return null; // Login sukses
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
          return 'Email atau password salah.';
        case 'wrong-password':
          return 'Password yang dimasukkan salah.';
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan gagal. Coba lagi nanti.';
        default:
          return 'Terjadi kesalahan login: ${e.message}';
      }
    } catch (e) {
      return 'Terjadi kesalahan sistem: $e';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    currentUser = null;
  }
}