import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/currency_format.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../providers/property_provider.dart';
import '../../widgets/facility_chip.dart';
import '../../widgets/property_card.dart';
import '../auth/login_screen.dart';
import 'map_explore_screen.dart';
import 'property_detail_screen.dart';
import 'wallet_screen.dart';
import 'package:intl/intl.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/rental_model.dart';

String _formatRentalDate(DateTime value) =>
    DateFormat('dd MMM yyyy', 'id_ID').format(value.toLocal());

void _openRentalProperty(BuildContext context, int propertyId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PropertyDetailScreen(propertyId: propertyId),
    ),
  );
}

void _showPayRentModal(BuildContext context, RentalModel rental) {
  int months = 1;
  final payment = context.read<PaymentProvider>();
  payment.fetchWallet();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final paymentProv = ctx.watch<PaymentProvider>();
          final totalPrice = rental.monthlyPrice * months;
          final balance = paymentProv.wallet?.balance ?? 0.0;
          final isSufficient = balance >= totalPrice;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bayar / Perpanjang Sewa', style: AppStyles.heading2),
                const SizedBox(height: 6),
                Text(
                  rental.property?.title ?? 'Properti Kos',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                Text(
                  '${CurrencyFormat.toRupiah(rental.monthlyPrice)} / bulan • Jatuh tempo: ${_formatRentalDate(rental.nextDueDate)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const Divider(height: 24),
                const Text('Pilih Jumlah Bulan Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [1, 2, 3, 6, 12].map((m) {
                    final selected = months == m;
                    return ChoiceChip(
                      label: Text('$m Bulan'),
                      selected: selected,
                      selectedColor: AppColors.primaryLight,
                      onSelected: (val) {
                        if (val) setModalState(() => months = m);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pembayaran:'),
                    Text(
                      CurrencyFormat.toRupiah(totalPrice),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Saldo Wallet Anda:'),
                    Text(
                      CurrencyFormat.toRupiah(balance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSufficient ? Colors.green : AppColors.danger,
                      ),
                    ),
                  ],
                ),
                if (!isSufficient) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saldo tidak mencukupi',
                        style: TextStyle(color: AppColors.danger, fontSize: 13),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const WalletScreen()),
                          );
                        },
                        icon: const Icon(Icons.add_card, size: 16),
                        label: const Text('Top Up Saldo'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: (!isSufficient || paymentProv.isLoading)
                        ? null
                        : () async {
                            final success = await paymentProv.payRent(rental.id, months);
                            if (!ctx.mounted) return;
                            if (success) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Pembayaran perpanjangan $months bulan berhasil!',
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    paymentProv.errorMessage ?? 'Gagal memproses pembayaran',
                                  ),
                                ),
                              );
                            }
                          },
                    child: paymentProv.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text('Bayar Sewa ($months Bulan)'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildDueReminder(BuildContext context, RentalModel rental) {
  final overdue = rental.nextDueDate.isBefore(DateTime.now());
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    color: overdue ? Colors.red.shade50 : Colors.orange.shade50,
    child: ListTile(
      onTap: () => _openRentalProperty(context, rental.propertyId),
      leading: Icon(
        overdue ? Icons.warning_amber_rounded : Icons.notifications_active_outlined,
        color: overdue ? AppColors.danger : Colors.orange.shade800,
      ),
      title: Text(overdue ? 'Pembayaran sewa terlambat' : 'Sewa segera jatuh tempo'),
      subtitle: Text(
        '${rental.property?.title ?? 'Properti sewaan'} • Jatuh tempo ${_formatRentalDate(rental.nextDueDate)} • ${CurrencyFormat.toRupiah(rental.monthlyPrice)} / bulan',
      ),
      isThreeLine: true,
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: overdue ? AppColors.danger : AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
        onPressed: () => _showPayRentModal(context, rental),
        child: const Text('Bayar'),
      ),
    ),
  );
}


Widget _buildSponsoredProperty(BuildContext context, PropertyModel property) {
  return SizedBox(
    width: 260,
    child: PropertyCard(
      property: property,
      onTap: () => _openRentalProperty(context, property.id),
    ),
  );
}

Widget _buildPaymentSections(BuildContext context, PaymentProvider payment) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (payment.dueReminders.isNotEmpty) ...[
        const Text('Pengingat Masa Sewa', style: AppStyles.heading2),
        const SizedBox(height: 8),
        ...payment.dueReminders.map((rental) => _buildDueReminder(context, rental)),
        const SizedBox(height: 16),
      ],
      if (payment.recommendedProperties.isNotEmpty) ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Kos Rekomendasi', style: AppStyles.heading2),
            Text(
              'Disponsori',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: payment.recommendedProperties.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) => _buildSponsoredProperty(
              context,
              payment.recommendedProperties[index],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    ],
  );
}


class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().initUserLocationAndLoad();
      final payment = context.read<PaymentProvider>();
      payment.fetchRemindersAndRentals();
      payment.fetchRecommendations();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openFilterSheet(PropertyProvider provider) {
    double tempRadius = provider.selectedRadius;
    final minCtrl = TextEditingController(
      text: provider.minPrice?.toInt().toString() ?? '',
    );
    final maxCtrl = TextEditingController(
      text: provider.maxPrice?.toInt().toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter Pencarian & Radius GPS', style: AppStyles.heading2),
                  const SizedBox(height: 16),
                  Text(
                    'Radius Pencarian Terdekat: ${tempRadius.toStringAsFixed(0)} KM',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: tempRadius,
                    min: 1,
                    max: 25,
                    divisions: 24,
                    activeColor: AppColors.primary,
                    label: '${tempRadius.toStringAsFixed(0)} KM',
                    onChanged: (val) => setModalState(() => tempRadius = val),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minCtrl,
                          keyboardType: TextInputType.number,
                          decoration: AppStyles.inputDecoration(
                            label: 'Harga Min (Rp)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxCtrl,
                          keyboardType: TextInputType.number,
                          decoration: AppStyles.inputDecoration(
                            label: 'Harga Max (Rp)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        provider.applyFilters(
                          radius: tempRadius,
                          minPrice: double.tryParse(minCtrl.text),
                          maxPrice: double.tryParse(maxCtrl.text),
                        );
                      },
                      child: const Text('Terapkan Filter'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showWishlistSheet(PropertyProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final items = provider.wishlists;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Favorit Saya (Wishlist)', style: AppStyles.heading2),
              const SizedBox(height: 12),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text('Belum ada properti yang disimpan ke favorit.'),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (ctx, i) => PropertyCard(
                          property: items[i],
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PropertyDetailScreen(
                                  propertyId: items[i].id,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PropertyProvider>();
    final payment = context.watch<PaymentProvider>();
    final auth = context.watch<AuthProvider>();

    final types = [
      {'key': 'all', 'label': 'Semua'},
      {'key': 'kost_putra', 'label': 'Kos Putra'},
      {'key': 'kost_putri', 'label': 'Kos Putri'},
      {'key': 'kost_campur', 'label': 'Kos Campur'},
      {'key': 'kontrakan', 'label': 'Kontrakan'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lokasi GPS Kamu Saat Ini',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
            Row(
              children: [
                const Icon(Icons.my_location, size: 14, color: AppColors.accent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    provider.currentAddressLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Wallet',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Wishlist Favorit',
            icon: const Icon(Icons.favorite_border),
            onPressed: () => _showWishlistSheet(provider),
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
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
        icon: const Icon(Icons.map_outlined),
        label: const Text('Eksplor Peta GPS'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MapExploreScreen()),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.initUserLocationAndLoad(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPaymentSections(context, payment),
            // Search & Filter Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (val) => provider.applyFilters(search: val),
                    decoration: AppStyles.inputDecoration(
                      label: 'Cari nama kos, kota, atau alamat...',
                      prefixIcon: Icons.search,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => _openFilterSheet(provider),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Filter Chip Tipe Hunian
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: types.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FacilityChip(
                      label: t['label']!,
                      selected: provider.selectedType == t['key'],
                      onTap: () => provider.applyFilters(type: t['key']),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Terdekat dari Kamu (Radius ${provider.selectedRadius.toInt()} KM)',
                  style: AppStyles.heading2,
                ),
                TextButton.icon(
                  onPressed: () => provider.initUserLocationAndLoad(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Perbarui GPS'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.nearbyProperties.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Belum ada kos tersedia dalam radius GPS ini. Coba perbesar radius KM di menu Filter.',
                  style: AppStyles.subtitle,
                ),
              )
            else
              ...provider.nearbyProperties.map(
                (prop) => PropertyCard(
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
              ),
            const SizedBox(height: 20),
            const Text('Semua Rekomendasi Properti', style: AppStyles.heading2),
            const SizedBox(height: 10),
            ...provider.allProperties.map(
              (prop) => PropertyCard(
                property: prop,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PropertyDetailScreen(propertyId: prop.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }
}
