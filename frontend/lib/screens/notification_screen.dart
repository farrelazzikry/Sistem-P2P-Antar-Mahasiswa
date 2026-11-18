import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_background.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _apiService = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getNotifications();
      setState(() {
        _notifications = response.data['data'];
        _isLoading = false;
      });
      // Tandai sudah dibaca pas dibuka
      await _apiService.markNotificationsAsRead();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} - ${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        imagePath: 'assets/images/bg.jpg',
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('Notifikasi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _notifications.isEmpty
                        ? const Center(child: Text('Belum ada notifikasi', style: TextStyle(color: Colors.white70)))
                        : RefreshIndicator(
                            onRefresh: _loadNotifications,
                            color: Colors.white,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _notifications.length,
                              itemBuilder: (context, i) {
                                final notif = _notifications[i];
                                final data = notif['data'];
                                final isUnread = notif['read_at'] == null;
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isUnread ? const Color(0xFF1B2846) : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isUnread ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data['title'] ?? '', style: TextStyle(color: isUnread ? Colors.greenAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 6),
                                      Text(data['message'] ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, height: 1.4)),
                                      const SizedBox(height: 8),
                                      Text(_formatDate(notif['created_at']), style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}