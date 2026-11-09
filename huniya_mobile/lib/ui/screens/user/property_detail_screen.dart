import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/currency_format.dart';
import '../../../data/models/property_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../providers/property_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/facility_chip.dart';
import 'wallet_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final int propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  PropertyModel? _property;
  bool _loading = true;
  int _currentSlide = 0;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final detail = await context.read<PropertyProvider>().getDetail(
          widget.propertyId,
        );
    if (!mounted) return;
    setState(() {
      _property = detail;
      _loading = false;
    });
  }

  Future<void> _openWhatsApp(PropertyModel prop) async {
    final phone = prop.owner?.phone ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor WhatsApp pemilik belum tersedia.')),
      );
      return;
    }

    final encodedText = Uri.encodeComponent(
      'Halo, saya tertarik dengan properti ${prop.title} di Huniya',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$encodedText');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka aplikasi WhatsApp.')),
      );
    }
  }

  Future<void> _openGoogleMapsRoute(PropertyModel prop) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${prop.latitude},${prop.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showRentModal(BuildContext context, PropertyModel prop) {
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
            final totalPrice = prop.priceMonthly * months;
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
                  const Text('Sewa & Bayar Langsung', style: AppStyles.heading2),
                  const SizedBox(height: 6),
                  Text(
                    prop.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  Text(
                    '${CurrencyFormat.toRupiah(prop.priceMonthly)} / bulan',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 24),
                  const Text('Pilih Durasi Sewa:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                              final success = await paymentProv.createRental(prop.id, months);
                              if (!ctx.mounted) return;
                              if (success) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pembayaran berhasil! Masa sewa telah aktif.'),
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

  @override
  Widget build(BuildContext context) {
    final propProvider = context.watch<PropertyProvider>();
    final authProvider = context.watch<AuthProvider>();

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_property == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Properti')),
        body: const Center(child: Text('Data properti tidak ditemukan.')),
      );
    }

    final prop = _property!;
    final isWishlisted = propProvider.isWishlisted(prop.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(prop.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (authProvider.user?.isUser == true)
            IconButton(
              icon: Icon(
                isWishlisted ? Icons.favorite : Icons.favorite_border,
                color: isWishlisted ? Colors.redAccent : Colors.white,
              ),
              onPressed: () async {
                final added = await propProvider.toggleWishlist(prop.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      added
                          ? 'Ditambahkan ke Wishlist'
                          : 'Dihapus dari Wishlist',
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.whatsapp,
                  side: const BorderSide(color: AppColors.whatsapp),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.chat_outlined, size: 20),
                label: const Text('WhatsApp'),
                onPressed: () => _openWhatsApp(prop),
              ),
            ),
            if (authProvider.user?.isUser == true &&
                prop.isAvailable &&
                prop.roomAvailable > 0) ...[
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: CustomButton(
                  label: 'Sewa & Bayar',
                  icon: Icons.account_balance_wallet_outlined,
                  backgroundColor: AppColors.primary,
                  onPressed: () => _showRentModal(context, prop),
                ),
              ),
            ],
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel Slider
            SizedBox(
              height: 250,
              child: prop.images.isNotEmpty
                  ? Stack(
                      children: [
                        PageView.builder(
                          itemCount: prop.images.length,
                          onPageChanged: (idx) =>
                              setState(() => _currentSlide = idx),
                          itemBuilder: (_, idx) {
                            final url = ApiEndpoints.resolveImageUrl(
                              prop.images[idx],
                            );
                            return CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            );
                          },
                        ),
                        Positioned(
                          bottom: 12,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentSlide + 1} / ${prop.images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: AppColors.primaryLight,
                      child: const Center(
                        child: Icon(
                          Icons.home_work_outlined,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          prop.typeLabel,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: prop.isAvailable
                              ? AppColors.success.withOpacity(0.15)
                              : AppColors.danger.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          prop.isAvailable
                              ? 'Tersedia (${prop.roomAvailable} Kamar Kosong)'
                              : 'Kamar Penuh',
                          style: TextStyle(
                            color: prop.isAvailable
                                ? AppColors.success
                                : AppColors.danger,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(prop.title, style: AppStyles.heading1),
                  const SizedBox(height: 6),
                  Text(
                    '${CurrencyFormat.toRupiah(prop.priceMonthly)} / Bulan',
                    style: AppStyles.priceText.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${prop.address}, ${prop.city}',
                          style: AppStyles.body,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('Fasilitas Kos / Kontrakan', style: AppStyles.heading2),
                  const SizedBox(height: 10),
                  if (prop.facilities.isEmpty)
                    const Text('Tidak ada fasilitas tercatat.', style: AppStyles.subtitle)
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: prop.facilities
                          .map((f) => FacilityChip(label: f))
                          .toList(),
                    ),
                  const Divider(height: 32),
                  const Text('Deskripsi & Aturan Hunian', style: AppStyles.heading2),
                  const SizedBox(height: 8),
                  Text(prop.description, style: AppStyles.body),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Lokasi di Peta', style: AppStyles.heading2),
                      TextButton.icon(
                        onPressed: () => _openGoogleMapsRoute(prop),
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Buka di Google Maps'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(prop.latitude, prop.longitude),
                          zoom: 15,
                        ),
                        liteModeEnabled: true,
                        markers: {
                          Marker(
                            markerId: MarkerId('detail_${prop.id}'),
                            position: LatLng(prop.latitude, prop.longitude),
                          ),
                        },
                      ),
                    ),
                  ),
                  if (prop.owner != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: Icon(Icons.person, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prop.owner!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Pemilik Properti • WA: ${prop.owner!.phone}',
                                  style: AppStyles.subtitle.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
