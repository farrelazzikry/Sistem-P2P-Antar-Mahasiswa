import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../widgets/app_background.dart';

class CreateJastipScreen extends StatefulWidget {
  const CreateJastipScreen({super.key});

  @override
  State<CreateJastipScreen> createState() => _CreateJastipScreenState();
}

class _CreateJastipScreenState extends State<CreateJastipScreen> {
  final _itemNameController = TextEditingController();
  final _itemDescController = TextEditingController();
  final _buyLocationController = TextEditingController();
  final _deliveryLocationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _feeController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPhoneFromProfile();
  }

  Future<void> _loadPhoneFromProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      // Parse JSON simple untuk ambil phone
      // (bisa pake jsonDecode kalau mau lebih rapi)
      final phoneMatch = RegExp(r'"phone":"([^"]*)"').firstMatch(userData);
      if (phoneMatch != null && phoneMatch.group(1) != 'null') {
        _whatsappController.text = phoneMatch.group(1) ?? '';
      }
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _submit() async {
    if (_itemNameController.text.trim().isEmpty ||
        _buyLocationController.text.trim().isEmpty ||
        _deliveryLocationController.text.trim().isEmpty ||
        _budgetController.text.trim().isEmpty ||
        _whatsappController.text.trim().isEmpty) {
      _showSnackBar('Semua field wajib diisi', Colors.orange);
      return;
    }

    final budget = double.tryParse(_budgetController.text.trim());
    final fee = double.tryParse(_feeController.text.trim()) ?? 0;

    if (budget == null || budget < 1000) {
      _showSnackBar('Budget minimal Rp 1.000', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.createJastip(
        itemName: _itemNameController.text.trim(),
        itemDescription: _itemDescController.text.trim(),
        buyLocation: _buyLocationController.text.trim(),
        deliveryLocation: _deliveryLocationController.text.trim(),
        budget: budget,
        fee: fee,
        whatsappNumber: _whatsappController.text.trim(),
      );

      if (!mounted) return;
      _showSnackBar('Order jastip berhasil dibuat!', Colors.green);
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          size: 18, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Buat Order',
                        style:
                            TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Buat Order Jastip',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                'Isi detail barang yang mau dititip. Runner akan hubungi kamu via WhatsApp.',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.5),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2846).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Nama Barang', 'Wajib'),
                    _input(_itemNameController, 'Contoh: Nasi Goreng'),
                    const SizedBox(height: 16),

                    _label('Deskripsi', 'Opsional'),
                    _input(_itemDescController, 'Catatan tambahan',
                        maxLines: 3),
                    const SizedBox(height: 16),

                    _label('Lokasi Beli', 'Wajib'),
                    _input(_buyLocationController,
                        'Contoh: Warung Pak Slamet'),
                    const SizedBox(height: 16),

                    _label('Lokasi Antar', 'Wajib'),
                    _input(_deliveryLocationController,
                        'Contoh: Asrama Mahasiswa Lt. 3'),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Budget', 'Wajib'),
                              _input(_budgetController, '25000',
                                  keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Fee Runner', 'Opsional'),
                              _input(_feeController, '5000',
                                  keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _label('Nomor WhatsApp', 'Wajib'),
                    _input(_whatsappController, '08xxxxxxxxxx',
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 8),
                    Text(
                      'Nomor ini akan dipakai Runner untuk menghubungi kamu.',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.black, strokeWidth: 2))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Posting Order',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(width: 8),
                                  Icon(Icons.send, size: 20),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, [String? right]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          if (right != null)
            Text(right,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}