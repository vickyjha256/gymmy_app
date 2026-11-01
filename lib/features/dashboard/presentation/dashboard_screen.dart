
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../members/presentation/members_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  int _totalMembers = 0;
  int _activeMemberships = 0;
  double _monthlyRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final responses = await Future.wait([
        ApiClient.dio.get('/dashboard/stats'),
        ApiClient.dio.get('/dashboard/revenue'),
      ]);

      final statsBody = Map<String, dynamic>.from(
        responses[0].data as Map,
      );
      final revenueBody = Map<String, dynamic>.from(
        responses[1].data as Map,
      );

      final stats = Map<String, dynamic>.from(
        statsBody['data'] as Map,
      );
      final revenue = Map<String, dynamic>.from(
        revenueBody['data'] as Map,
      );

      if (statsBody['success'] != true ||
          revenueBody['success'] != true) {
        throw Exception('Unable to load dashboard data.');
      }

      if (!mounted) return;

      setState(() {
        _totalMembers = (stats['totalMembers'] as num).toInt();
        _activeMemberships =
            (stats['activeMemberships'] as num).toInt();
        _monthlyRevenue =
            (revenue['totalRevenue'] as num).toDouble();
        _isLoading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.response?.statusCode == 401
            ? 'Your session may have expired. Please sign in again.'
            : 'Could not load dashboard data. Please try again.';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to read dashboard data.';
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text(
          'Gymmy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F46E5),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh dashboard',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Here’s what’s happening at your gym.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 16),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 40,
                          color: Color(0xFF667085),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF667085),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadDashboard,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  )
                else ...[
                    _StatCard(
                      title: 'Total Members',
                      value: _totalMembers.toString(),
                      icon: Icons.people_alt_outlined,
                      color: const Color(0xFF4F46E5),
                    ),
                    const SizedBox(height: 14),
                    _StatCard(
                      title: 'Active Memberships',
                      value: _activeMemberships.toString(),
                      icon: Icons.fitness_center,
                      color: const Color(0xFF059669),
                    ),
                    const SizedBox(height: 14),
                    _StatCard(
                      title: 'Monthly Revenue',
                      value: _formatCurrency(_monthlyRevenue),
                      icon: Icons.currency_rupee,
                      color: const Color(0xFFEA580C),
                    ),
                  ],



                const SizedBox(height: 28),
                const Text(
                  'Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MembersScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE9ECF5),
                      ),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(0xFFEDE9FE),
                          child: Icon(
                            Icons.people_alt_outlined,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Members',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF172033),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'View and search gym members',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF667085),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Color(0xFF667085),
                        ),
                      ],
                    ),
                  ),
                ),





              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9ECF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF667085),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172033),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
