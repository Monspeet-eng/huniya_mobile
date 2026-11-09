import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/owner_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../core/utils/currency_format.dart';
import '../../widgets/property_card.dart';
import '../auth/login_screen.dart';
import '../user/property_detail_screen.dart';
import '../user/wallet_screen.dart';
import 'property_form_screen.dart';

void _showBoostDialog(BuildContext context, int propertyId) {
  int selectedMonths = 1;
  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        final payment = ctx.watch<PaymentProvider>();
        final price = 50000.0 * selectedMonths;

        return AlertDialog(
          title: const Text('Boost Iklan Properti'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Properti Anda akan tampil di bagian "Kos Rekomendasi" pengguna.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text('Pilih Durasi Boost:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<int>(
                isExpanded: true,
                value: selectedMonths,
                items: [1, 2, 3, 6, 12].map((m) {
                  return DropdownMenuItem(value: m, child: Text('$m Bulan'));
                }).toList(),
                onChanged: (val) => setModalState(() => selectedMonths = val!),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Biaya:'),
                  Text(
                    CurrencyFormat.toRupiah(price),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              if (payment.wallet != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Saldo Wallet:'),
                    Text(
                      CurrencyFormat.toRupiah(payment.wallet!.balance),
                      style: TextStyle(
                        fontSize: 12,
                        color: payment.wallet!.balance < price ? AppColors.danger : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: payment.isLoading || (payment.wallet != null && payment.wallet!.balance < price)
                  ? null
                  : () async {
                      final ok = await payment.purchaseBoost(propertyId, selectedMonths);
                      if (!ctx.mounted) return;
                      if (ok) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Iklan berhasil di-boost!')),
                        );
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(payment.errorMessage ?? 'Gagal memproses boost')),
                        );
                      }
                    },
              child: const Text('Bayar & Aktifkan'),
            ),
          ],
        );
      },
    ),
  );
}

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerProvider>().fetchOwnerProperties();
      context.read<PaymentProvider>().fetchWallet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ownerProv = context.watch<OwnerProvider>();
    final authProv = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard Pemilik Kos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Wallet / Saldo',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () async {
              await authProv.logout();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_home_work_outlined),
        label: const Text('Tambah Properti'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PropertyFormScreen()),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: () => ownerProv.fetchOwnerProperties(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Halo, ${authProv.user?.name ?? "Owner"}!',
              style: AppStyles.heading2,
            ),
            const SizedBox(height: 12),
            // Statistik Ringkas sesuai Bagian 7.1 PRD
            Row(
              children: [
                _buildStatCard(
                  label: 'Total Properti',
                  value: ownerProv.totalProperties.toString(),
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  label: 'Tersedia',
                  value: ownerProv.availablePropertiesCount.toString(),
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  label: 'Kamar Penuh',
                  value: ownerProv.fullPropertiesCount.toString(),
                  color: AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text('Daftar Properti Saya', style: AppStyles.heading2),
            const SizedBox(height: 12),
            if (ownerProv.isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (ownerProv.myProperties.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.add_business_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Anda belum memiliki listing kos atau kontrakan. Tekan tombol "Tambah Properti" di bawah untuk mulai menyewakan.',
                      textAlign: TextAlign.center,
                      style: AppStyles.subtitle,
                    ),
                  ],
                ),
              )
            else
              ...ownerProv.myProperties.map(
                (prop) => Column(
                  children: [
                    PropertyCard(
                      property: prop,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PropertyDetailScreen(propertyId: prop.id),
                          ),
                        );
                      },
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceAround,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                ownerProv.toggleAvailability(prop),
                            icon: Icon(
                              prop.isAvailable
                                  ? Icons.toggle_on
                                  : Icons.toggle_off,
                              color: prop.isAvailable
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                            label: Text(
                              prop.isAvailable ? 'Set Penuh' : 'Set Tersedia',
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PropertyFormScreen(
                                    existingProperty: prop,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                          ),
                          TextButton.icon(
                            onPressed: () => _showBoostDialog(context, prop.id),
                            icon: const Icon(Icons.campaign_outlined, size: 18),
                            label: const Text('Boost Iklan'),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus Properti?'),
                                  content: Text(
                                    'Apakah Anda yakin ingin menghapus "${prop.title}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Hapus',
                                        style: TextStyle(
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ownerProv.deleteProperty(prop.id);
                              }
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.danger,
                            ),
                            label: const Text(
                              'Hapus',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
