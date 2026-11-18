import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Menyimpan data user yang sedang login di memori aplikasi
  static UserModel? currentUser;

  // Helper untuk mengecek role user saat ini
  static bool get isAdmin => currentUser?.role == 'admin';
  static bool get isKasir => currentUser?.role == 'kasir';

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
      final error = await _loadUserProfile(uid);
      if (error != null) {
        await _auth.signOut();
        return error;
      }

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

  /// Dipanggil saat aplikasi dibuka. Memulihkan sesi Firebase yang masih aktif
  /// dengan membaca ulang profil/role pengguna dari Firestore.
  /// Mengembalikan true jika sesi berhasil dipulihkan.
  Future<bool> restoreSession() async {
    if (currentUser != null) return true;

    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return false;

    try {
      final error = await _loadUserProfile(firebaseUser.uid);
      if (error != null) {
        await _auth.signOut();
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Membaca dokumen users/{uid} lalu menyimpannya ke state aktif aplikasi.
  /// Mengembalikan null jika berhasil, atau pesan error jika gagal.
  Future<String?> _loadUserProfile(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      return 'Data role pengguna tidak ditemukan di database.';
    }

    final data = userDoc.data();
    if (data == null) {
      return 'Data pengguna kosong di database.';
    }

    currentUser = UserModel.fromMap(data, uid);
    return null;
  }

  Future<void> logout() async {
    await _auth.signOut();
    currentUser = null;
  }
}
