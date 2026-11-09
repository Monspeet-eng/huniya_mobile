import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/location_helper.dart';
import '../../../data/models/property_model.dart';
import '../../../providers/owner_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/facility_chip.dart';
import 'map_picker_screen.dart';

class PropertyFormScreen extends StatefulWidget {
  final PropertyModel? existingProperty;

  const PropertyFormScreen({super.key, this.existingProperty});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _roomCtrl = TextEditingController(text: '1');
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  String _selectedType = 'kost_putra';
  double _latitude = LocationHelper.defaultLat;
  double _longitude = LocationHelper.defaultLng;

  final List<String> _availableFacilities = [
    'WiFi',
    'AC',
    'K. Mandi Dalam',
    'Kasur',
    'Lemari',
    'Parkir Motor',
    'Parkir Mobil',
    'Dapur Bersama',
    'CCTV 24 Jam',
  ];

  final Set<String> _selectedFacilities = {'WiFi', 'Kasur'};
  final List<File> _pickedImages = [];

  bool get isEditing => widget.existingProperty != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingProperty;

    if (existing != null) {
      _titleCtrl.text = existing.title;
      _descCtrl.text = existing.description;
      _priceCtrl.text = existing.priceMonthly.toInt().toString();
      _roomCtrl.text = existing.roomAvailable.toString();
      _addressCtrl.text = existing.address;
      _cityCtrl.text = existing.city;
      _selectedType = existing.type;
      _latitude = existing.latitude;
      _longitude = existing.longitude;

      _selectedFacilities
        ..clear()
        ..addAll(existing.facilities);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _roomCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 80);

    if (files.isNotEmpty) {
      setState(() {
        final remaining = 5 - _pickedImages.length;
        _pickedImages.addAll(
          files.take(remaining).map((xfile) => File(xfile.path)),
        );
      });
    }
  }

  Future<void> _openMapPicker() async {
    final picked = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLat: _latitude,
          initialLng: _longitude,
        ),
      ),
    );

    if (picked != null) {
      setState(() {
        _latitude = picked.latitude;
        _longitude = picked.longitude;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final ownerProv = context.read<OwnerProvider>();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final rooms = int.tryParse(_roomCtrl.text.trim()) ?? 1;

    bool success;

    if (isEditing) {
      success = await ownerProv.updateProperty(
        id: widget.existingProperty!.id,
        title: _titleCtrl.text.trim(),
        type: _selectedType,
        description: _descCtrl.text.trim(),
        priceMonthly: price,
        roomAvailable: rooms,
        address: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        facilities: _selectedFacilities.toList(),
        newImageFiles: _pickedImages,
      );
    } else {
      success = await ownerProv.createProperty(
        title: _titleCtrl.text.trim(),
        type: _selectedType,
        description: _descCtrl.text.trim(),
        priceMonthly: price,
        roomAvailable: rooms,
        address: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        facilities: _selectedFacilities.toList(),
        imageFiles: _pickedImages,
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Properti berhasil diperbarui'
                : 'Properti baru berhasil ditambahkan',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (ownerProv.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ownerProv.errorMessage!),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerProv = context.watch<OwnerProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Properti' : 'Tambah Properti Baru'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: AppStyles.inputDecoration(
                  label: 'Nama Kos / Kontrakan',
                  hint: 'Contoh: Kos Melati Indah Residence',
                ),
                validator: (v) =>
                    (v == null || v.isEmpty)
                        ? 'Nama properti wajib diisi'
                        : null,
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: AppStyles.inputDecoration(
                  label: 'Tipe Hunian',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'kost_putra',
                    child: Text('Kos Putra'),
                  ),
                  DropdownMenuItem(
                    value: 'kost_putri',
                    child: Text('Kos Putri'),
                  ),
                  DropdownMenuItem(
                    value: 'kost_campur',
                    child: Text('Kos Campur'),
                  ),
                  DropdownMenuItem(
                    value: 'kontrakan',
                    child: Text('Kontrakan'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedType = val);
                  }
                },
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: AppStyles.inputDecoration(
                        label: 'Harga Sewa / Bulan (Rp)',
                        hint: '1500000',
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty)
                              ? 'Wajib diisi'
                              : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _roomCtrl,
                      keyboardType: TextInputType.number,
                      decoration: AppStyles.inputDecoration(
                        label: 'Sisa Kamar',
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Wajib' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _cityCtrl,
                decoration: AppStyles.inputDecoration(
                  label: 'Kota / Kabupaten',
                  hint: 'Jakarta Selatan',
                ),
                validator: (v) =>
                    (v == null || v.isEmpty)
                        ? 'Kota wajib diisi'
                        : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: AppStyles.inputDecoration(
                  label: 'Alamat Lengkap',
                ),
                validator: (v) =>
                    (v == null || v.isEmpty)
                        ? 'Alamat wajib diisi'
                        : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: AppStyles.inputDecoration(
                  label: 'Deskripsi & Peraturan Kos',
                ),
                validator: (v) =>
                    (v == null || v.isEmpty)
                        ? 'Deskripsi wajib diisi'
                        : null,
              ),
              const SizedBox(height: 18),

              const Text(
                'Pilih Fasilitas Tersedia',
                style: AppStyles.heading2,
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableFacilities.map((fac) {
                  final isSelected = _selectedFacilities.contains(fac);

                  return FacilityChip(
                    label: fac,
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedFacilities.remove(fac);
                        } else {
                          _selectedFacilities.add(fac);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              const Text(
                'Titik Koordinat GPS Properti',
                style: AppStyles.heading2,
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.pin_drop,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Lat: ${_latitude.toStringAsFixed(6)}\n'
                        'Lng: ${_longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _openMapPicker,
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Pilih Titik Peta'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Foto Properti (Maks. 5 Foto)',
                    style: AppStyles.heading2,
                  ),
                  TextButton.icon(
                    onPressed:
                        _pickedImages.length >= 5 ? null : _pickImages,
                    icon: const Icon(
                      Icons.add_a_photo_outlined,
                      size: 18,
                    ),
                    label: const Text('Pilih Foto'),
                  ),
                ],
              ),

              if (_pickedImages.isNotEmpty)
                SizedBox(
                  height: 95,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pickedImages.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 10),
                    itemBuilder: (_, idx) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _pickedImages[idx],
                            width: 95,
                            height: 95,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => setState(
                              () => _pickedImages.removeAt(idx),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 28),

              CustomButton(
                label: isEditing
                    ? 'Simpan Perubahan'
                    : 'Publikasikan Properti',
                isLoading: ownerProv.isLoading,
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}