import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/app_background.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'jastip_screen.dart';
import 'tebengan_screen.dart';
import 'my_orders_screen.dart';
import 'riwayat_screen.dart';
import 'notification_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = 'Mahasiswa';
  bool _isAdmin = false; // <-- VARIABEL BARU UNTUK CEK ADMIN
  int _currentIndex = 0;
  final _apiService = ApiService();

  // Key buat refresh tab pas pindah
  Key _ordersKey = UniqueKey();
  Key _profileKey = UniqueKey();
  Key _riwayatKey = UniqueKey();

  // Variabel Notifikasi
  Timer? _notifTimer;
  int _unreadNotif = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();

    // Cek notif pertama kali dibuka
    _checkNotifications();

    // Set Timer: Cek notif setiap 15 detik
    _notifTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkNotifications();
    });
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }

    Future<void> _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // 1. Tampilkan dulu dari cache biar cepet
    setState(() {
      _username = prefs.getString('user') ?? 'Mahasiswa';
      
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        try {
          final userData = jsonDecode(userDataStr);
          _isAdmin = userData['is_admin'] == true || userData['is_admin'] == 1;
        } catch (_) {}
      }
    });

    // 2. Tarik data terbaru dari API
    try {
      final response = await _apiService.getProfile();
      final userData = response.data['user'];
      
      // Simpan data terbaru ke cache
      await prefs.setString('user_data', jsonEncode(userData));
      
      if (mounted) {
        setState(() {
          _username = userData['username'] ?? 'Mahasiswa';
          
          // CEK: Cuma update kalau API ngirim data is_admin
          if (userData['is_admin'] != null) {
            _isAdmin = userData['is_admin'] == true || userData['is_admin'] == 1;
          }
        });
      }
    } catch (e) {
      debugPrint('Gagal load profile: $e');
    }
  }

  Future<void> _checkNotifications() async {
    try {
      final res = await _apiService.getNotifications();
      if (mounted) {
        setState(() {
          _unreadNotif = res.data['unread_count'] ?? 0;
        });
      }
    } catch (_) {
      // Silent error
    }
  }

  Future<void> _logout() async {
    try {
      await _apiService.logout();
    } catch (_) {}
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildBeranda(),
      MyOrdersScreen(key: _ordersKey),
      RiwayatScreen(key: _riwayatKey),
      ProfileScreen(key: _profileKey),
    ];

    // === RESPONSIVE LAYOUT ===
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (i) {
                    setState(() {
                      _currentIndex = i;
                      if (i == 1) _ordersKey = UniqueKey();
                      if (i == 2) _riwayatKey = UniqueKey();
                      if (i == 3) _profileKey = UniqueKey();
                    });
                  },
                  extended: constraints.maxWidth > 1100,
                  backgroundColor: const Color(0xFF0A1128),
                  selectedIconTheme: const IconThemeData(color: Colors.white),
                  unselectedIconTheme: const IconThemeData(
                    color: Colors.white54,
                  ),
                  selectedLabelTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: Colors.white54,
                  ),
                  indicatorColor: Colors.white.withValues(alpha: 0.1),
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Icon(Icons.school, color: Colors.white, size: 36),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Beranda'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long),
                      label: Text('Pesanan'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(Icons.history),
                      label: Text('Riwayat'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profil'),
                    ),
                  ],
                ),
                const VerticalDivider(
                  thickness: 1,
                  width: 1,
                  color: Colors.white12,
                ),
                Expanded(
                  child: AppBackground(
                    imagePath: 'assets/images/bg.jpg',
                    child: IndexedStack(index: _currentIndex, children: pages),
                  ),
                ),
              ],
            ),
          );
        }

        // Tampilan Mobile (HP)
        return Scaffold(
          body: AppBackground(
            imagePath: 'assets/images/bg.jpg',
            child: IndexedStack(index: _currentIndex, children: pages),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A1128).withValues(alpha: 0.95),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) {
                setState(() {
                  _currentIndex = i;
                  if (i == 1) _ordersKey = UniqueKey();
                  if (i == 2) _riwayatKey = UniqueKey();
                  if (i == 3) _profileKey = UniqueKey();
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withValues(alpha: 0.4),
              selectedFontSize: 11,
              unselectedFontSize: 11,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(Icons.receipt_long),
                  label: 'Pesanan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_outlined),
                  activeIcon: Icon(Icons.history),
                  label: 'Riwayat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBeranda() {
    return RefreshIndicator(
      onRefresh: () async {
        await _checkNotifications();
      },
      color: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar: Search + Notif
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cari layanan...',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // BAGIAN NOTIFIKASI (BADGE MERAH)
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        );
                        _checkNotifications();
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          if (_unreadNotif > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$_unreadNotif',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Banner Halo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2846).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo,',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_username! 👋',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aktivitas kampus dan mobilitas harian Politeknik Negeri Batam dalam satu genggaman.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // TOMBOL ADMIN (Hanya muncul kalau _isAdmin == true)
                if (_isAdmin) ...[
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminScreen(),
                        ),
                      );
                      _checkNotifications();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Admin Panel: Verifikasi User',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Layanan Kampus
                const Text(
                  'Layanan Kampus',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _serviceCard(
                          icon: Icons.directions_car_outlined,
                          title: 'Tebengan Mahasiswa',
                          subtitle: 'Ride sharing kampus & rute harian',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TebenganScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _serviceCard(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Jasa Titip (Jastip)',
                          subtitle: 'Antar jemput dokumen, makanan & barang',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const JastipScreen(),
                              ),
                            );
                          },
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
      ),
    );
  }

  Widget _serviceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
