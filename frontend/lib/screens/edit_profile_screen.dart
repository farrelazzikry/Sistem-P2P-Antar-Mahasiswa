import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../widgets/app_background.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _apiService = ApiService();

  PlatformFile? _newPhoto; // buat dikirim ke API
  Uint8List? _newPhotoBytes; // buat preview
  String? _existingPhotoUrl;
  bool _isRunner = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('user_data');
    if (cachedUser != null) {
      final user = jsonDecode(cachedUser);
      setState(() {
        _nameController.text = user['name'] ?? '';
        _phoneController.text = user['phone'] ?? '';
        _isRunner = user['is_runner'] ?? false;
        _vehicleTypeController.text = user['vehicle_type'] ?? '';
        _vehiclePlateController.text = user['vehicle_plate'] ?? '';
        final photoPath = user['profile_photo'];
        _existingPhotoUrl = photoPath != null && photoPath.isNotEmpty
            ? '${ApiService.baseUrl}/storage/$photoPath'
            : null;
      });
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );
      if (file == null) return;

      // Baca bytes-nya SEKARANG (async), simpen di state
      final bytes = await file.readAsBytes();

      setState(() {
        _newPhoto = file;
        _newPhotoBytes = bytes;
      });
    } catch (e) {
      _showSnackBar('Gagal pilih foto: $e', Colors.red);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Nama wajib diisi', Colors.orange);
      return;
    }
    if (_isRunner) {
      if (_vehicleTypeController.text.trim().isEmpty ||
          _vehiclePlateController.text.trim().isEmpty) {
        _showSnackBar(
          'Detail kendaraan wajib diisi untuk Runner',
          Colors.orange,
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        isRunner: _isRunner,
        vehicleType: _vehicleTypeController.text.trim(),
        vehiclePlate: _vehiclePlateController.text.trim(),
        profilePhoto: _newPhoto,
      );

      // Update cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(response.data['user']));

      if (!mounted) return;
      _showSnackBar('Profil berhasil diperbarui', Colors.green);
      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar(e.toString(), Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        imagePath: 'assets/images/bg.jpg',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Edit Profil',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lengkapi data diri & kendaraan supaya pengguna lain bisa mengenali kamu saat bertransaksi.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Form Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2846).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Foto Profile
                    Center(
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                image: _newPhotoBytes != null
                                    ? DecorationImage(
                                        image: MemoryImage(_newPhotoBytes!),
                                        fit: BoxFit.cover,
                                      )
                                    : (_existingPhotoUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                _existingPhotoUrl!,
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null),
                              ),
                              child:
                                  (_newPhotoBytes == null &&
                                      _existingPhotoUrl == null)
                                  ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Tap untuk ganti foto',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nama
                    _buildLabel('Nama Lengkap', 'Wajib'),
                    _buildDarkTextField(
                      controller: _nameController,
                      hint: 'Nama lengkap kamu',
                    ),
                    const SizedBox(height: 16),

                    // Nomor HP
                    _buildLabel('Nomor HP', 'Opsional'),
                    _buildDarkTextField(
                      controller: _phoneController,
                      hint: '08xxxxxxxxxx',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // Runner Toggle
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isRunner
                              ? Colors.greenAccent.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.directions_car,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saya juga ingin jadi Runner',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Untuk menerima orderan tebengan',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isRunner,
                            activeColor: Colors.greenAccent,
                            onChanged: (v) => setState(() => _isRunner = v),
                          ),
                        ],
                      ),
                    ),

                    // Detail Kendaraan (kalau jadi Runner)
                    if (_isRunner) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.greenAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.greenAccent,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Detail Kendaraan',
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildLabel('Jenis Kendaraan', 'Wajib'),
                            _buildDarkTextField(
                              controller: _vehicleTypeController,
                              hint: 'Motor / Mobil / Beat / Vario',
                            ),
                            const SizedBox(height: 16),
                            _buildLabel('Plat Nomor', 'Wajib'),
                            _buildDarkTextField(
                              controller: _vehiclePlateController,
                              hint: 'BP 1234 XYZ',
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Simpan Perubahan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.check, size: 20),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, [String? rightText]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (rightText != null)
            Text(
              rightText,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDarkTextField({
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
