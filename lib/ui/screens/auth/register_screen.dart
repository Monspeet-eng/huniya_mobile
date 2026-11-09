import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../owner/owner_dashboard_screen.dart';
import '../user/user_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Pilihan Role RBAC sesuai Bagian 2 & 7.1 PRD
  String _selectedRole = 'user';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      phone: _phoneCtrl.text.trim(),
      role: _selectedRole,
    );

    if (!mounted) return;
    if (success && auth.user != null) {
      if (auth.user!.isOwner) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()),
          (_) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const UserHomeScreen()),
          (_) => false,
        );
      }
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buat Akun Huniya'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Peran Akun (Role)', style: AppStyles.heading2),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      value: 'user',
                      title: 'Pencari Kos',
                      subtitle: 'Cari kos via GPS',
                      icon: Icons.person_pin_circle_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleCard(
                      value: 'owner',
                      title: 'Pemilik Kos',
                      subtitle: 'Kelola properti',
                      icon: Icons.real_estate_agent_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _nameCtrl,
                decoration: AppStyles.inputDecoration(
                  label: 'Nama Lengkap',
                  prefixIcon: Icons.person_outline,
                ),
                validator: (v) =>
                    (v == null || v.length < 2) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: AppStyles.inputDecoration(
                  label: 'Email',
                  prefixIcon: Icons.email_outlined,
                ),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: AppStyles.inputDecoration(
                  label: 'Nomor WhatsApp Aktif',
                  hint: '6281234567890',
                  prefixIcon: Icons.phone_android_outlined,
                ),
                validator: (v) => (v == null || v.length < 9)
                    ? 'Masukkan nomor WhatsApp aktif'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: AppStyles.inputDecoration(
                  label: 'Password (Min. 6 karakter)',
                  prefixIcon: Icons.lock_outline,
                ),
                validator: (v) => (v == null || v.length < 6)
                    ? 'Password minimal 6 karakter'
                    : null,
              ),
              const SizedBox(height: 26),
              CustomButton(
                label: 'Daftar Sekarang',
                isLoading: auth.isLoading,
                onPressed: _submitRegister,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == value;
    return InkWell(
      onTap: () => setState(() => _selectedRole = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 30,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
