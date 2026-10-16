import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _apiService = ApiService();

  List<dynamic> _myRequests = [];
  List<dynamic> _myTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getMyJastips();
      if (!mounted) return;
      setState(() {
        _myRequests = response.data['my_requests'] ?? [];
        _myTasks = response.data['my_tasks'] ?? [];
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

  Future<void> _openWhatsApp(String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }
    final url = Uri.parse('https://wa.me/$cleanPhone');
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal buka WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    try {
      await _apiService.updateJastipStatus(id, status);
      if (!mounted) return;
      final msg = status == 'done'
          ? 'Order selesai! Jangan lupa kasih rating.'
          : status == 'cancelled'
          ? 'Order dibatalkan'
          : 'Order dimulai';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green),
      );
      _loadMyOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2846),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: TextStyle(
                color: confirmColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) onConfirm();
  }

  Future<void> _showRatingDialog(dynamic order, bool isRequest) async {
    int stars = 5;
    final reviewController = TextEditingController();

    final rateeId = isRequest ? order['runner_id'] : order['requester_id'];
    final rateeName = isRequest
        ? (order['runner']?['name'] ?? 'Runner')
        : (order['requester']?['name'] ?? 'Pemesan');

    if (rateeId == null) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1B2846),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(
                Icons.star_rate_rounded,
                color: Colors.amber,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Kasih Rating',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Berapa bintang untuk $rateeName?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setModalState(() => stars = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < stars ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                '$stars bintang',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Review
              TextField(
                controller: reviewController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Review (opsional)',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await _apiService.submitRating(
                        rateableType: 'jastip',
                        rateableId: order['id'],
                        stars: stars,
                        review: reviewController.text.trim().isEmpty
                            ? null
                            : reviewController.text.trim(),
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rating berhasil dikirim!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadMyOrders();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kirim Rating',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sebagai Pemesan'),
                    if (_myRequests.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _buildBadge(_myRequests.length),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sebagai Runner'),
                    if (_myTasks.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _buildBadge(_myTasks.length),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrdersList(_myRequests, isRequest: true),
                    _buildOrdersList(_myTasks, isRequest: false),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$count', style: const TextStyle(fontSize: 10)),
    );
  }

  Widget _buildOrdersList(List<dynamic> orders, {required bool isRequest}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRequest ? Icons.receipt_long_outlined : Icons.work_outline,
              size: 60,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isRequest ? 'Belum Ada Request' : 'Belum Ada Task',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isRequest
                  ? 'Bikin order jastip di halaman Jastip'
                  : 'Ambil order di halaman Jastip',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyOrders,
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: orders.length,
        itemBuilder: (context, i) =>
            _buildOrderCard(orders[i], isRequest: isRequest),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order, {required bool isRequest}) {
    final status = order['status'] ?? 'open';
    final itemName = order['item_name'] ?? '-';
    final budget = (order['budget'] ?? 0).toDouble();
    final fee = (order['fee'] ?? 0).toDouble();

    final otherPerson = isRequest ? order['runner'] : order['requester'];
    final otherName = otherPerson?['name'] ?? '';
    final otherRole = isRequest ? 'Runner' : 'Pemesan';

    // Nomor WA yang dihubungi
    final waNumber = isRequest
        ? (otherPerson?['phone'] ?? '')
        : (order['whatsapp_number'] ?? '');

    // Status rating
    final requesterHasRated = order['requester_has_rated'] == true;
    final runnerHasRated = order['runner_has_rated'] == true;
    final userHasRated = isRequest ? requesterHasRated : runnerHasRated;
    final otherHasRated = isRequest ? runnerHasRated : requesterHasRated;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2846).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _buildStatusBadge(status),
              const Spacer(),
              Text(
                '#${order['id']}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Item
          Text(
            itemName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),

          // Other person
          if (otherName.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  '$otherRole: $otherName',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),

          // Budget & Fee
          Row(
            children: [
              _chip('Budget: Rp ${budget.toStringAsFixed(0)}', Colors.white),
              const SizedBox(width: 8),
              _chip('Fee: Rp ${fee.toStringAsFixed(0)}', Colors.greenAccent),
            ],
          ),

          // Info rating status (kalau done)
          if (status == 'done') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: userHasRated
                    ? Colors.greenAccent.withValues(alpha: 0.1)
                    : Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: userHasRated
                      ? Colors.greenAccent.withValues(alpha: 0.3)
                      : Colors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    userHasRated ? Icons.check_circle : Icons.star_outline,
                    size: 16,
                    color: userHasRated ? Colors.greenAccent : Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      userHasRated
                          ? (otherHasRated
                                ? 'Kamu & $otherRole sudah saling rating'
                                : 'Kamu udah rating. Nunggu $otherRole...')
                          : 'Kasih rating ke $otherRole',
                      style: TextStyle(
                        fontSize: 11,
                        color: userHasRated ? Colors.greenAccent : Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              // Tombol WhatsApp
              if (waNumber.isNotEmpty &&
                  status != 'cancelled' &&
                  status != 'done')
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () => _openWhatsApp(waNumber),
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text(
                        'Chat WhatsApp',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),

              // === REQUESTER BUTTONS ===
              if (isRequest && status == 'on_progress') ...[
                if (waNumber.isNotEmpty) const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmAction(
                        title: 'Selesaikan Order?',
                        message:
                            'Pastikan barang udah kamu terima dengan baik.',
                        confirmText: 'Selesai',
                        confirmColor: Colors.greenAccent,
                        onConfirm: () => _updateStatus(order['id'], 'done'),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text(
                        'Selesai',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // Tombol Kasih Rating (Kalau done & belum rating)
              if (status == 'done' && !userHasRated)
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () => _showRatingDialog(order, isRequest),
                      icon: const Icon(Icons.star, size: 16),
                      label: const Text(
                        'Kasih Rating',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),

              // === RUNNER BUTTONS ===
              if (!isRequest && status == 'taken') ...[
                if (waNumber.isNotEmpty) const SizedBox(width: 8),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(order['id'], 'on_progress'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text(
                      'Mulai',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              // Tombol Cancel (Runner only, status taken/on_progress)
              if (!isRequest &&
                  (status == 'taken' || status == 'on_progress')) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmAction(
                      title: 'Minta Cancel?',
                      message: 'Order bakal dibatalkan. Pastikan kamu udah hubungi Pemesan via WhatsApp.',
                      confirmText: 'Cancel Order',
                      confirmColor: Colors.redAccent,
                      onConfirm: () => _updateStatus(order['id'], 'cancelled'),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 14),
                    label: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'open':
        color = Colors.greenAccent;
        label = 'Tersedia';
        break;
      case 'taken':
        color = Colors.orangeAccent;
        label = 'Diambil';
        break;
      case 'on_progress':
        color = Colors.blueAccent;
        label = 'Diproses';
        break;
      case 'done':
        color = Colors.green;
        label = 'Selesai';
        break;
      case 'cancelled':
        color = Colors.redAccent;
        label = 'Dibatalkan';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
