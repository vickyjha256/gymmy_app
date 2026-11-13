
import 'package:flutter/material.dart';
import 'package:gymmy_app/features/memberships/presentation/screens/create_membership_screen.dart';
import 'package:gymmy_app/features/memberships/presentation/screens/renew_membership_screen.dart';

import '../../../members/models/member_model.dart';
import '../../../members/presentation/add_member_screen.dart';
import '../../data/membership_repository.dart';
import '../../models/membership_model.dart';
import 'membership_history_screen.dart';

class MembershipsScreen extends StatefulWidget {
  const MembershipsScreen({super.key});

  @override
  State<MembershipsScreen> createState() => _MembershipsScreenState();
}

class _MembershipsScreenState extends State<MembershipsScreen> {
  final MembershipRepository _repository = MembershipRepository();

  List<MembershipModel> _memberships = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Active',
    'Upcoming',
    'Expired',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _loadMemberships();
  }

  Future<void> _loadMemberships() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _repository.getMemberships();
      if (!mounted) return;

      setState(() {
        _memberships = result;
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

  List<MembershipModel> get _distinctMemberships {
    final Map<String, List<MembershipModel>> grouped = {};

    for (final membership in _memberships) {
      grouped.putIfAbsent(membership.memberId, () => []);
      grouped[membership.memberId]!.add(membership);
    }

    final result = <MembershipModel>[];

    for (final records in grouped.values) {
      records.sort((a, b) {
        final priority = {
          'ACTIVE': 4,
          'UPCOMING': 3,
          'EXPIRED': 2,
          'CANCELLED': 1,
        };

        final aPriority = priority[a.status.toUpperCase()] ?? 0;
        final bPriority = priority[b.status.toUpperCase()] ?? 0;

        if (aPriority != bPriority) {
          return bPriority.compareTo(aPriority);
        }

        return b.endDate.compareTo(a.endDate);
      });

      result.add(records.first);
    }

    result.sort((a, b) => b.endDate.compareTo(a.endDate));
    return result;
  }

  List<MembershipModel> get _filteredMemberships {
    if (_selectedFilter == 'All') return _distinctMemberships;

    return _distinctMemberships
        .where(
          (membership) =>
      membership.status.toUpperCase() ==
          _selectedFilter.toUpperCase(),
    )
        .toList();
  }

  int _count(String status) {
    return _distinctMemberships
        .where((m) => m.status.toUpperCase() == status.toUpperCase())
        .length;
  }





  Future<void> _addMembership() async {
    // Members who already have an ACTIVE membership cannot be selected.
    final activeMemberIds = _memberships
        .where((membership) => membership.status.toUpperCase() == 'ACTIVE')
        .map((membership) => membership.memberId)
        .toSet();

    // Step 1: Select an existing eligible member.
    final member = await Navigator.push<MemberModel>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateMembershipScreen(
          activeMemberIds: activeMemberIds,
        ),
      ),
    );

    if (!mounted || member == null) return;

    // Step 2: Assign a membership plan and payment method.
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RenewMembershipScreen(
          memberId: member.id,
          memberName: member.fullName,
          isNewMembership: true,
        ),
      ),
    );

    // Step 3: Refresh only after successful membership creation.
    if (!mounted) return;

    if (created == true) {
      await _loadMemberships();
    }
  }








  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF5F7FB);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _buildError()
                  : RefreshIndicator(
                onRefresh: _loadMemberships,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  children: [
                    _buildOverview(),
                    const SizedBox(height: 28),
                    _buildSectionHeading(),
                    const SizedBox(height: 14),
                    _buildFilters(),
                    const SizedBox(height: 18),
                    if (_filteredMemberships.isEmpty)
                      _buildEmptyState()
                    else
                      ..._filteredMemberships.map(
                            (membership) =>
                            _buildMembershipCard(membership),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.card_membership_rounded,
              color: Color(0xFF536DFE),
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Memberships',
                  style: TextStyle(
                    color: Color(0xFF202B43),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_distinctMemberships.length} members',
                  style: const TextStyle(
                    color: Color(0xFF747F9C),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _addMembership,
            borderRadius: BorderRadius.circular(11),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF536DFE),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.85,
          children: [
            _summaryCard(
              'Total',
              _distinctMemberships.length,
              Icons.groups_rounded,
              const Color(0xFF536DFE),
              const Color(0xFFEEF0FF),
            ),
            _summaryCard(
              'Active',
              _count('ACTIVE'),
              Icons.check_circle_rounded,
              const Color(0xFF16A36A),
              const Color(0xFFE8F8F0),
            ),
            _summaryCard(
              'Upcoming',
              _count('UPCOMING'),
              Icons.schedule_rounded,
              const Color(0xFFDB9220),
              const Color(0xFFFFF5E3),
            ),
            _summaryCard(
              'Expired',
              _count('EXPIRED'),
              Icons.history_rounded,
              const Color(0xFFE05A65),
              const Color(0xFFFFECEE),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(
      String title,
      int count,
      IconData icon,
      Color color,
      Color background,
      ) {
    return Container(
      padding: const EdgeInsets.all(15),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF858B9B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading() {
    return Row(
      children: [
        const Text(
          'All records',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        Text(
          '${_filteredMemberships.length} members',
          style: const TextStyle(
            color: Color(0xFF9298A7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final selected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 9),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF24366B) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF24366B)
                        : const Color(0xFFE8EAF0),
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF697184),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMembershipCard(MembershipModel membership) {
    final name = membership.memberName.trim();
    final initials = name.isEmpty
        ? '?'
        : name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    final status = membership.status.toUpperCase();
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF192B50).withValues(alpha: 0.035),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF536DFE), Color(0xFF8292FF)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Unknown member' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF202B43),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      membership.memberPhone,
                      style: const TextStyle(
                        color: Color(0xFF9298A7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(status, statusColor),
            ],
          ),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFF536DFE),
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MEMBERSHIP PLAN',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 0.8,
                          color: Color(0xFF9298A7),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        membership.planName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF263455),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${membership.amountPaid.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF202B43),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _dateInfo(
                  Icons.calendar_today_rounded,
                  'START DATE',
                  _formatDate(membership.startDate),
                ),
              ),
              Expanded(
                child: _dateInfo(
                  Icons.event_available_rounded,
                  'END DATE',
                  _formatDate(membership.endDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(height: 1, color: Color(0xFFF0F1F5)),
          const SizedBox(height: 12),


          Row(
            children: [
              // TextButton(
              //   onPressed: () => _showMembershipDetails(membership),
              //   child: const Text(
              //     'View details',
              //     style: TextStyle(
              //       color: Color(0xFF536DFE),
              //       fontWeight: FontWeight.w700,
              //     ),
              //   ),
              // ),

              TextButton(
                onPressed: () => _openMembershipHistory(membership),
                child: const Text(
                  'View History',
                  style: TextStyle(
                    color: Color(0xFF536DFE),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),


              const Spacer(),
              if (membership.status.toUpperCase() != 'ACTIVE')
                TextButton(
                  onPressed: () => _openRenewal(membership),
                  child: const Text(
                    'Renew',
                    style: TextStyle(
                      color: Color(0xFF159B67),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

              // const SizedBox(width: 5,),

              if (membership.status.toUpperCase() == 'ACTIVE')
                TextButton(
                  onPressed: () => _cancelMembership(membership),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFFE05A65),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          )

        ],
      ),
    );
  }

  Widget _dateInfo(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF9298A7)),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
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
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          letterSpacing: 0.4,
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
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF0FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_membership_rounded,
              color: Color(0xFF536DFE),
              size: 35,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No memberships found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Membership records will appear here.',
            style: TextStyle(
              color: Color(0xFF9298A7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
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
              'Could not load memberships',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadMemberships,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }




  Future<void> _openMembershipHistory(
      MembershipModel membership,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MembershipHistoryScreen(
          memberId: membership.memberId,
          memberName: membership.memberName,
          memberPhone: membership.memberPhone,
        ),
      ),
    );

    if (!mounted) return;
    await _loadMemberships();
  }





  Future<void> _openRenewal(MembershipModel membership) async {
    final renewed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RenewMembershipScreen(
          memberId: membership.memberId,
          memberName: membership.memberName,
        ),
      ),
    );

    if (renewed == true) {
      await _loadMemberships();
    }
  }

  Future<void> _cancelMembership(MembershipModel membership) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel membership?'),
        content: Text(
          'Are you sure you want to cancel ${membership.memberName}\'s membership?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep membership'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05A65),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel membership'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _repository.cancelMembership(membership.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membership cancelled successfully')),
      );

      await _loadMemberships();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showMembershipDetails(MembershipModel membership) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Membership Details',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                _detailRow('Member', membership.memberName),
                _detailRow('Phone', membership.memberPhone),
                _detailRow('Plan', membership.planName),
                _detailRow(
                  'Amount paid',
                  '₹${membership.amountPaid.toStringAsFixed(0)}',
                ),
                _detailRow('Payment method', membership.paymentMethod),
                _detailRow('Start date', _formatDate(membership.startDate)),
                _detailRow('End date', _formatDate(membership.endDate)),
                _detailRow('Status', membership.status),
                const SizedBox(height: 20),
                if (membership.status.toUpperCase() != 'CANCELLED')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _openRenewal(membership);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF293E79),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Renew Membership'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF9298A7), fontSize: 13),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF263455),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }




}
