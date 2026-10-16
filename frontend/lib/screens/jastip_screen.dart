import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../widgets/app_background.dart';
import 'create_jastip_screen.dart';

class JastipScreen extends StatefulWidget {
  const JastipScreen({super.key});

  @override
  State<JastipScreen> createState() => _JastipScreenState();
}

class _JastipScreenState extends State<JastipScreen> {
  final _apiService = ApiService();
  List<dynamic> _jastips = [];
  bool _isLoading = true;
  bool _isRunner = false;
  int? _currentUserId;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadJastips();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final response = await _apiService.getProfile();
      final userData = response.data['user'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _isRunner = userData['is_runner'] == true;
        _currentUserId = userData['id'] as int?;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(userData));
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('user_data');
      if (cached != null && mounted) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        setState(() {
          _isRunner = data['is_runner'] == true;
          _currentUserId = data['id'] as int?;
        });
      }
    }
  }

  Future<void> _loadJastips() async {
    setState(() => _isLoading = true);
    try {
      // Cuma tampil order yang status OPEN
      final response = await _apiService.getJastips(status: 'open');
      if (!mounted) return;
      setState(() {
        _jastips = response.data['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _takeOrder(int jastipId) async {
    // Konfirmasi dulu
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2846),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Ambil Order?',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Order bakal masuk ke halaman Pesanan kamu. Lanjut?',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ambil',
                style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.takeJastip(jastipId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order berhasil diambil! Cek di tab Pesanan.'),
          backgroundColor: Colors.green,
        ),
      );
      _loadJastips();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  List<dynamic> get _filteredJastips {
    // Tampilin SEMUA order open (termasuk punya sendiri)
    if (_searchQuery.isEmpty) return _jastips;
    return _jastips.where((j) {
      final itemName = (j['item_name'] ?? '').toString().toLowerCase();
      final buyLoc = (j['buy_location'] ?? '').toString().toLowerCase();
      final delivLoc =
          (j['delivery_location'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return itemName.contains(q) ||
          buyLoc.contains(q) ||
          delivLoc.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        imagePath: 'assets/images/bg.jpg',
        child: SafeArea(
          child: Column(
            children: [
              // Header: Back + Search + Notif
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color:
                                  Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            size: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color:
                                  Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search,
                                color: Colors.white
                                    .withValues(alpha: 0.6),
                                size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) =>
                                    setState(() => _searchQuery = val),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Cari jastip...',
                                  hintStyle: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.5),
                                      fontSize: 14),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: Icon(Icons.close,
                                    color: Colors.white
                                        .withValues(alpha: 0.5),
                                    size: 18),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),

              // Title + Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text('Jasa Titip',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${_filteredJastips.length}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Feed
              Expanded(
                child: _isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Colors.white))
                    : _filteredJastips.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadJastips,
                            color: Colors.white,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  20, 0, 20, 100),
                              itemCount: _filteredJastips.length,
                              itemBuilder: (context, i) =>
                                  _buildJastipCard(_filteredJastips[i]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CreateJastipScreen()),
          );
          if (result == true) _loadJastips();
        },
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Buat Order',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined,
              size: 60, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('Belum Ada Order',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Jadilah yang pertama buat order jastip!',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildJastipCard(dynamic jastip) {
    final requester = jastip['requester'] ?? {};
    final requesterName = requester['name'] ?? 'Mahasiswa';
    final budget = (jastip['budget'] ?? 0).toDouble();
    final fee = (jastip['fee'] ?? 0).toDouble();

    // Cek apakah ini order kita sendiri
    final isMyOrder = jastip['requester_id'] == _currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2846).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMyOrder
              ? Colors.blueAccent.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.15),
          width: isMyOrder ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Requester
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                child: const Icon(Icons.person,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isMyOrder ? 'Kamu' : requesterName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                        if (isMyOrder) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.blueAccent
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Text(
                              'ORDER KAMU',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      isMyOrder ? 'Pemesan (Kamu)' : 'Pemesan',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.4)),
                ),
                child: const Text('Tersedia',
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(jastip['item_name'] ?? '-',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          if (jastip['item_description'] != null &&
              jastip['item_description'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(jastip['item_description'],
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.4)),
          ],
          const SizedBox(height: 12),

          _buildInfoRow(Icons.storefront_outlined, 'Beli di',
              jastip['buy_location'] ?? '-'),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.location_on_outlined, 'Antar ke',
              jastip['delivery_location'] ?? '-'),
          const SizedBox(height: 12),

          // Budget & Fee
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Budget',
                          style: TextStyle(
                              color: Colors.white
                                  .withValues(alpha: 0.5),
                              fontSize: 10)),
                      const SizedBox(height: 2),
                      Text('Rp ${budget.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            Colors.greenAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fee Runner',
                          style: TextStyle(
                              color: Colors.greenAccent
                                  .withValues(alpha: 0.8),
                              fontSize: 10)),
                      const SizedBox(height: 2),
                      Text('Rp ${fee.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action
          if (isMyOrder)
            // Kalau order sendiri, tampilkan info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.blueAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ini order kamu. Cek status di tab Pesanan → Request Gue.',
                      style: TextStyle(
                          color: Colors.blueAccent.withValues(alpha: 0.9),
                          fontSize: 11,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed:
                    _isRunner ? () => _takeOrder(jastip['id']) : null,
                icon: const Icon(Icons.pan_tool_alt, size: 18),
                label:
                    Text(_isRunner ? 'Ambil Order' : 'Jadi Runner Dulu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunner
                      ? Colors.white
                      : Colors.grey.withValues(alpha: 0.3),
                  foregroundColor:
                      _isRunner ? Colors.black : Colors.white54,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            color: Colors.white.withValues(alpha: 0.5), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, height: 1.4),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5)),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}