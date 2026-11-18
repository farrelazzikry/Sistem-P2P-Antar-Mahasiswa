import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // Pastiin ini ada
import '../services/api_service.dart';
import '../widgets/app_background.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _apiService = ApiService();
  
  List<dynamic> _pendingUsers = [];
  List<dynamic> _allUsers = [];
  int _unreadNotif = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _loadNotif();
  }

  Future<void> _loadNotif() async {
    try {
      final res = await _apiService.getNotifications();
      if (mounted) {
        setState(() {
          _unreadNotif = res.data['unread_count'] ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final pendingRes = await _apiService.getAdminUsers(status: 'pending');
      final allRes = await _apiService.getAdminUsers(); 
      
      if (!mounted) return;
      setState(() {
        _pendingUsers = pendingRes.data['data'] ?? [];
        _allUsers = allRes.data['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(e.toString(), Colors.red, Icons.error_outline);
    }
  }

  void _showSnackBar(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [Icon(icon, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)))]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // === FUNGSI LIHAT KTM (POPUP GAMBAR / BUKA BROWSER) ===
  Future<void> _viewKtm(String? ktmPath) async {
    if (ktmPath == null || ktmPath.isEmpty) {
      _showSnackBar('KTM tidak diupload', Colors.orange, Icons.warning);
      return;
    }

    final isPdf = ktmPath.toLowerCase().endsWith('.pdf');
    final url = '${ApiService.baseUrl}/storage/$ktmPath';

    if (isPdf) {
      // Kalau PDF, buka di browser
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Gagal membuka file PDF', Colors.red, Icons.error_outline);
      }
    } else {
      // Kalau Gambar, buka popup full screen
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.black87,
                      child: const Text('Gagal memuat gambar KTM', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20, right: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // === FUNGSI BUKA NOTIFIKASI ===
  Future<void> _showNotifications() async {
    try {
      final res = await _apiService.getNotifications();
      final notifs = res.data['data'] ?? [];
      await _apiService.markNotificationsAsRead(); 
      _loadNotif(); 

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Color(0xFF1B2846),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 16, bottom: 16),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                ),
                const Text('Notifikasi Admin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: notifs.isEmpty
                    ? const Center(child: Text('Tidak ada notifikasi', style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: notifs.length,
                        itemBuilder: (context, i) {
                          final data = notifs[i]['data'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 6),
                                Text(data['message'] ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.4)),
                              ],
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      _showSnackBar(e.toString(), Colors.red, Icons.error_outline);
    }
  }

  Future<void> _actionUser(int id, String action) async {
    try {
      if (action == 'approve') {
        await _apiService.approveUser(id);
        _showSnackBar('User berhasil di-approve', Colors.green, Icons.check_circle);
      } else {
        await _apiService.rejectUser(id);
        _showSnackBar('User berhasil di-reject', Colors.orange, Icons.cancel);
      }
      _loadData();
    } catch (e) {
      _showSnackBar(e.toString(), Colors.red, Icons.error_outline);
    }
  }

  Future<void> _showResetPasswordDialog(dynamic user) async {
    final passController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2846),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset Password\n${user['name']}', style: const TextStyle(color: Colors.white, fontSize: 18)),
        content: TextField(
          controller: passController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Masukkan password baru (min 8)',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () async {
              if (passController.text.length < 8) {
                _showSnackBar('Password minimal 8 karakter', Colors.orange, Icons.warning);
                return;
              }
              Navigator.pop(context);
              try {
                await _apiService.adminResetPassword(user['id'], passController.text);
                _showSnackBar('Password berhasil direset!', Colors.green, Icons.check_circle);
              } catch (e) {
                _showSnackBar(e.toString(), Colors.red, Icons.error_outline);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await _apiService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        imagePath: 'assets/images/bg.jpg',
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Admin Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    GestureDetector(
                      onTap: _showNotifications,
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.notifications, color: Colors.white),
                          ),
                          if (_unreadNotif > 0)
                            Positioned(
                              right: 0, top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: Text('$_unreadNotif', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      onPressed: _logout,
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08), 
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.white70,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Verifikasi User'),
                          Tab(text: 'Kelola User'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // List Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildUserList(_pendingUsers, isPending: true),
                          _buildUserList(_allUsers, isPending: false),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(List<dynamic> users, {required bool isPending}) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isPending ? Icons.verified_user_outlined : Icons.people_outline, size: 60, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(isPending ? 'Tidak ada user pending' : 'Belum ada user terdaftar', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16)),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: users.length,
          itemBuilder: (context, i) => _buildUserCard(users[i], isPending: isPending),
        ),
      ),
    );
  }

  Widget _buildUserCard(dynamic user, {required bool isPending}) {
    final status = user['status'] ?? 'pending';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2846).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  user['name'] ?? '-', 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'approved' ? Colors.greenAccent.withValues(alpha: 0.2) : status == 'rejected' ? Colors.redAccent.withValues(alpha: 0.2) : Colors.orangeAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status.toUpperCase(), 
                  style: TextStyle(color: status == 'approved' ? Colors.greenAccent : status == 'rejected' ? Colors.redAccent : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('NIM: ${user['nim'] ?? '-'}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
          Text('Email: ${user['email'] ?? '-'}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
          
          const SizedBox(height: 12),
          
          // === TOMBOL LIHAT KTM (PENGGANTI GAMBAR BESAR) ===
          GestureDetector(
            onTap: () => _viewKtm(user['ktm_path']),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.document_scanner, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 12),
                  const Text('Lihat Dokumen KTM', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, color: Colors.blueAccent.withValues(alpha: 0.5), size: 14),
                ],
              ),
            ),
          ),
            
          const SizedBox(height: 16),
          
          if (isPending) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _actionUser(user['id'], 'reject'), 
                    icon: const Icon(Icons.close, size: 18), 
                    label: const Text('Tolak'), 
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent, 
                      side: const BorderSide(color: Colors.redAccent), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
                      padding: const EdgeInsets.symmetric(vertical: 12)
                    )
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _actionUser(user['id'], 'approve'), 
                    icon: const Icon(Icons.check, size: 18), 
                    label: const Text('Setujui'), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent, 
                      foregroundColor: Colors.black, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
                      padding: const EdgeInsets.symmetric(vertical: 12)
                    )
                  )
                ),
              ],
            )
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showResetPasswordDialog(user),
                icon: const Icon(Icons.password, size: 18),
                label: const Text('Reset Password'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent, 
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
                  padding: const EdgeInsets.symmetric(vertical: 12)
                ),
              ),
            )
          ]
        ],
      ),
    );
  }
}