
import 'package:flutter/material.dart';

import '../../data/membership_repository.dart';
import '../../models/membership_model.dart';

class MembershipHistoryScreen extends StatefulWidget {
  final String memberId;
  final String memberName;
  final String memberPhone;

  const MembershipHistoryScreen({
    super.key,
    required this.memberId,
    required this.memberName,
    required this.memberPhone,
  });

  @override
  State<MembershipHistoryScreen> createState() =>
      _MembershipHistoryScreenState();
}

class _MembershipHistoryScreenState
    extends State<MembershipHistoryScreen> {
  final MembershipRepository _repository = MembershipRepository();

  List<MembershipModel> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final memberships = await _repository.getMemberships();

      final history = memberships
          .where((m) => m.memberId == widget.memberId)
          .toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));

      if (!mounted) return;

      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text(
          'Membership History',
          style: TextStyle(
            color: Color(0xFF202B43),
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF202B43),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildError()
            : RefreshIndicator(
          onRefresh: _loadHistory,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildMemberHeader(),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    'All memberships',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_history.length} records',
                    style: const TextStyle(
                      color: Color(0xFF9298A7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_history.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 70),
                  child: Center(
                    child: Text('No membership history found'),
                  ),
                )
              else
                ..._history.map(_buildHistoryCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberHeader() {
    final name = widget.memberName.trim();
    final initials = name.isEmpty
        ? '?'
        : name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF536DFE),
                  Color(0xFF8292FF),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.memberName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF202B43),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.memberPhone,
                  style: const TextStyle(
                    color: Color(0xFF747F9C),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(MembershipModel membership) {
    final status = membership.status.toUpperCase();
    final color = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  membership.planName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF263455),
                  ),
                ),
              ),
              _statusBadge(status, color),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _dateInfo(
                  'START DATE',
                  _formatDate(membership.startDate),
                ),
              ),
              Expanded(
                child: _dateInfo(
                  'END DATE',
                  _formatDate(membership.endDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0F1F5)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 17,
                color: Color(0xFF9298A7),
              ),
              const SizedBox(width: 7),
              Text(
                '₹${membership.amountPaid.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF202B43),
                ),
              ),
              const Spacer(),
              Text(
                membership.paymentMethod,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF858B9B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9298A7),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF34405A),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return const Color(0xFF159B67);
      case 'UPCOMING':
        return const Color(0xFFD38B1F);
      case 'EXPIRED':
        return const Color(0xFFE05A65);
      case 'CANCELLED':
        return const Color(0xFF858B9B);
      default:
        return const Color(0xFF536DFE);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFE05A65),
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load membership history',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHistory,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
