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
      // Jangan pernah memakai role lama saat proses login akun baru.
      currentUser = null;

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
        currentUser = null;
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

  /// Kirim email reset password. Mengembalikan null jika berhasil.
  Future<String?> sendPasswordReset(String email) async {
    final target = email.trim();
    if (target.isEmpty) {
      return 'Masukkan email akun terlebih dahulu.';
    }

    try {
      await _auth.sendPasswordResetEmail(email: target);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'user-not-found':
          return 'Tidak ada akun dengan email tersebut.';
        case 'too-many-requests':
          return 'Terlalu banyak permintaan. Coba lagi nanti.';
        default:
          return 'Gagal mengirim email reset: ${e.message}';
      }
    } catch (e) {
      return 'Gagal mengirim email reset: $e';
    }
  }

  /// Baca ulang profil/role dari Firestore tanpa mengubah sesi Firebase.
  /// Dipakai saat aplikasi dibuka kembali agar perubahan role oleh admin
  /// langsung terpakai. Gagal membaca tidak memaksa logout.
  Future<bool> refreshProfile() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      currentUser = null;
      return false;
    }

    try {
      final error = await _loadUserProfile(firebaseUser.uid);
      return error == null;
    } catch (_) {
      return false;
    }
  }

  /// Dipanggil saat aplikasi dibuka. Memulihkan sesi Firebase yang masih aktif
  /// dengan membaca ulang profil/role pengguna dari Firestore.
  /// Mengembalikan true jika sesi berhasil dipulihkan.
  Future<bool> restoreSession() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      // Tidak ada sesi Firebase yang tersisa.
      currentUser = null;
      return false;
    }

    // Profil di memori hanya valid jika berasal dari akun Firebase yang sama.
    if (currentUser?.id == firebaseUser.uid) return true;

    try {
      final error = await _loadUserProfile(firebaseUser.uid);
      if (error != null) {
        await _auth.signOut();
        currentUser = null;
        return false;
      }
      return true;
    } catch (_) {
      currentUser = null;
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
    try {
      await _auth.signOut();
    } finally {
      // Selalu bersihkan state di memori agar UI tidak memakai role lama.
      currentUser = null;
    }
  }
}
