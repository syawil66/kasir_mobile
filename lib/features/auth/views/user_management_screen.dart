import 'package:flutter/material.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/controllers/user_controller.dart';
import '../../auth/models/user_model.dart';

/// Kelola pengguna & role (khusus admin).
///
/// Akun Firebase Authentication tetap dibuat lewat Firebase Console/Admin SDK;
/// layar ini mengelola dokumen `users/{uid}` (nama, username, role).
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  static const Color pastelPink = Color(0xFFFDE1E6);
  static const Color pastelLavender = Color(0xFFE9E5FA);
  static const Color accentPink = Color(0xFFD99AAF);
  static const Color darkMauve = Color(0xFF594455);
  static const Color mutedMauve = Color(0xFF806B80);

  final UserController _controller = UserController();
  late final Stream<List<UserModel>> _usersStream = _controller.getUsersStream();

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? const Color(0xFFB86B80) : const Color(0xFF7C9A7E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Future<void> _editUser(UserModel user) async {
    final result = await showDialog<_UserEditResult>(
      context: context,
      builder: (dialogContext) => _UserEditDialog(user: user),
    );

    if (result == null || !mounted) return;

    // Nama/username dulu, lalu role, supaya error bisa dilaporkan per bagian.
    final profileError = await _controller.updateProfile(
      uid: user.id,
      name: result.name,
      username: result.username,
    );
    if (profileError != null) {
      _showMessage(profileError, isError: true);
      return;
    }

    if (result.role != user.role) {
      final roleError = await _controller.updateRole(
        uid: user.id,
        role: result.role,
      );
      if (roleError != null) {
        _showMessage(roleError, isError: true);
        return;
      }
    }

    _showMessage('Data pengguna "${result.name}" diperbarui.');
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthController.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kelola Pengguna'),
          backgroundColor: pastelPink,
          foregroundColor: darkMauve,
          elevation: 0,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              'Hanya admin yang dapat mengelola pengguna.',
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedMauve),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Kelola Pengguna',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: pastelPink,
        foregroundColor: darkMauve,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [pastelPink, pastelLavender, Colors.white],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: StreamBuilder<List<UserModel>>(
          stream: _usersStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: accentPink),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Gagal memuat pengguna.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: mutedMauve, fontSize: 12),
                  ),
                ),
              );
            }

            final users = snapshot.data ?? const <UserModel>[];

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEADCE8)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: mutedMauve,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Akun login (email & password) dibuat lewat Firebase '
                          'Console. Di sini admin mengatur nama, username, dan '
                          'role pengguna.',
                          style: TextStyle(
                            fontSize: 11,
                            color: mutedMauve,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (users.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'Belum ada data pengguna.',
                        style: TextStyle(color: mutedMauve),
                      ),
                    ),
                  )
                else
                  ...users.map(_buildUserTile),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserTile(UserModel user) {
    final isSelf = AuthController.currentUser?.id == user.id;
    final isAdmin = user.role == 'admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0DCE8)),
      ),
      child: ListTile(
        onTap: () => _editUser(user),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: pastelLavender,
          child: const Icon(Icons.person_outline_rounded, color: darkMauve),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: darkMauve,
                ),
              ),
            ),
            if (isSelf) ...[
              const SizedBox(width: 6),
              const Text(
                '(Anda)',
                style: TextStyle(fontSize: 10, color: mutedMauve),
              ),
            ],
          ],
        ),
        subtitle: Text(
          user.username.isEmpty ? 'Tanpa username' : '@${user.username}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: mutedMauve),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isAdmin
                ? const Color(0xFFF3DCE8)
                : const Color(0xFFE7E0F7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isAdmin ? 'Admin' : 'Kasir',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isAdmin
                  ? const Color(0xFFB76E8B)
                  : const Color(0xFF8063A0),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserEditResult {
  final String name;
  final String username;
  final String role;

  const _UserEditResult({
    required this.name,
    required this.username,
    required this.role,
  });
}

class _UserEditDialog extends StatefulWidget {
  final UserModel user;

  const _UserEditDialog({required this.user});

  @override
  State<_UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<_UserEditDialog> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.user.name);
  late final TextEditingController _usernameController =
      TextEditingController(text: widget.user.username);
  late String _role = widget.user.role == 'admin' ? 'admin' : 'kasir';

  bool get _isSelf => AuthController.currentUser?.id == widget.user.id;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    Navigator.pop(
      context,
      _UserEditResult(
        name: name,
        username: _usernameController.text.trim(),
        role: _role,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Pengguna'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixText: '@',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Role',
                isDense: true,
              ),
              items: UserController.roles
                  .map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(role == 'admin' ? 'Admin' : 'Kasir'),
                    ),
                  )
                  .toList(),
              onChanged: _isSelf
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _role = value);
                      }
                    },
            ),
            if (_isSelf) ...[
              const SizedBox(height: 8),
              const Text(
                'Role akun sendiri tidak dapat diubah.',
                style: TextStyle(fontSize: 11, color: Color(0xFF806B80)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
