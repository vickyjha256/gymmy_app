import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/member_repository.dart';
import '../models/member_model.dart';
import 'edit_member_screen.dart';

class MemberDetailsScreen extends StatefulWidget {
  final String memberId;

  const MemberDetailsScreen({
    super.key,
    required this.memberId,
  });

  @override
  State<MemberDetailsScreen> createState() =>
      _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends State<MemberDetailsScreen> {
  final MemberRepository _repository = MemberRepository();

  MemberModel? _member;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMember();
  }

  Future<void> _loadMember() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result =
      await _repository.getMemberById(widget.memberId);

      if (!mounted) return;

      setState(() {
        _member = result;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.response?.statusCode == 404
            ? 'This member could not be found.'
            : 'Unable to load member details.';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load member details.';
        _isLoading = false;
      });
    }
  }

  String _value(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'Not provided';
    }
    return value.toString();
  }


  Future<void> _openEditMember() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditMemberScreen(
          memberId: widget.memberId,
          member: _member!.toJson(),
        ),
      ),
    );

    if (updated == true && mounted) {
      await _loadMember();
    }
  }




  String _formatDate(dynamic value) {
    if (value == null) return 'Not available';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();

    return '${date.day.toString().padLeft(2, '0')} '
        '${_month(date.month)} ${date.year}';
  }

  String _month(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF16A34A);
      case 'INACTIVE':
      case 'EXPIRED':
        return const Color(0xFFDC2626);
      case 'UPCOMING':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF64748B);
    }
  }

  List<Map<String, dynamic>> _membershipHistory(MemberModel member) {
    return member.membershipHistory;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text(
          'Member Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Edit member',
            onPressed: _member == null || _isLoading
                ? null
                : _openEditMember,
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadMember,
            icon: const Icon(Icons.refresh_rounded),
          ),

          PopupMenuButton<String>(
            tooltip: 'Member actions',
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (action) {
              _handleMemberAction(action);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _member?.isActive == true ? 'deactivate' : 'reactivate',
                child: Row(
                  children: [
                    Icon(_member?.isActive == true ? Icons.person_off_outlined : Icons.person_add_alt_1_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(_member?.isActive == true ? 'Deactivate member' : 'Reactivate member'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Colors.red,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Delete member',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),


          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_search_rounded,
                size: 56,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadMember,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final member = _member!;
    final firstName = member.firstName;
    final fullName = member.fullName;
    final status = member.status;
    final history = _membershipHistory(member);

    return RefreshIndicator(
      onRefresh: _loadMember,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _buildProfileHeader(
            context,
            fullName: fullName,
            firstName: firstName,
            status: status,
            phone: _value(member.phone),
            email: member.email?.toString(),
          ),
          const SizedBox(height: 24),

          _buildSectionHeading(
            context,
            'Personal information',
            'Basic member details',
            Icons.person_outline_rounded,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(context, [
            _InfoItem(
              icon: Icons.phone_rounded,
              label: 'Phone number',
              value: _value(member.phone),
            ),
            _InfoItem(
              icon: Icons.email_outlined,
              label: 'Email address',
              value: _value(member.email),
            ),
            _InfoItem(
              icon: Icons.wc_rounded,
              label: 'Gender',
              value: _value(member.gender),
            ),
            _InfoItem(
              icon: Icons.cake_outlined,
              label: 'Date of birth',
              value: _formatDate(member.dateOfBirth),
            ),
            _InfoItem(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: _value(member.address),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeading(
            context,
            'Health & emergency',
            'Additional information',
            Icons.health_and_safety_outlined,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(context, [
            _InfoItem(
              icon: Icons.height_rounded,
              label: 'Height (cm)',
              value: member.height == null
                  ? 'Not provided'
                  : '${member.height}',
            ),
            _InfoItem(
              icon: Icons.monitor_weight_outlined,
              label: 'Weight (kg)',
              value: member.weight == null
                  ? 'Not provided'
                  : '${member.weight}',
            ),
            _InfoItem(
              icon: Icons.contact_phone_outlined,
              label: 'Emergency contact',
              value: _value(member.emergencyContactName),
            ),
            _InfoItem(
              icon: Icons.phone_in_talk_outlined,
              label: 'Emergency phone',
              value: _value(member.emergencyContactPhone),
            ),
            _InfoItem(
              icon: Icons.notes_rounded,
              label: 'Notes',
              value: _value(member.notes),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeading(
            context,
            'Membership history',
            '${history.length} record${history.length == 1 ? '' : 's'}',
            Icons.card_membership_rounded,
          ),
          const SizedBox(height: 12),

          if (history.isEmpty)
            _buildEmptyMembershipCard(context)
          else
            ...history.map(
                  (membership) =>
                  _buildMembershipCard(context, membership),
            ),
        ],
      ),
    );
  }


  Future<void> _handleMemberAction(String action) async {
    final isDelete = action == 'delete';
    final isReactivate = action == 'reactivate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          isDelete ? Icons.delete_forever_rounded :
          (isReactivate ? Icons.person_add_alt_1_rounded : Icons.person_off_outlined),
          size: 32,
          color: isDelete ? Colors.red : Theme.of(context).colorScheme.primary,
        ),
        title: Text(isDelete ? 'Delete member?' : (isReactivate ? 'Reactivate member?' : 'Deactivate member?')),
        content: Text(
          isDelete
              ? 'This action may permanently remove the member record.'
              : (isReactivate
              ? 'This member will be marked active again.'
              : 'The member will be marked inactive, and their record will remain.'),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            style: isDelete ? FilledButton.styleFrom(backgroundColor: Colors.red) : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isDelete ? 'Delete' : (isReactivate ? 'Reactivate' : 'Deactivate')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      if (isDelete) {
        await _repository.deleteMember(widget.memberId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member deleted successfully')));
        Navigator.pop(context, true);
      } else {
        Map<String, dynamic> payload = {
          "status": isReactivate ? 'ACTIVE' : 'INACTIVE'
        };

        await _repository.updateMember(widget.memberId, payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isReactivate ? 'Member reactivated successfully' : 'Member deactivated successfully')));
        await _loadMember();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: ${error.toString().replaceFirst('Exception: ', '')}')));
    }
  }



  Widget _buildProfileHeader(
      BuildContext context, {
        required String fullName,
        required String firstName,
        required String status,
        required String phone,
        required String? email,
      }) {
    final color = _statusColor(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF312E81),
            Color(0xFF4F46E5),
            Color(0xFF6366F1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.17),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  firstName.isNotEmpty
                      ? firstName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: color == const Color(0xFF16A34A)
                                    ? const Color(0xFF86EFAC)
                                    : Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.22),
          ),
          const SizedBox(height: 16),
          _headerContactRow(
            Icons.phone_rounded,
            phone,
          ),
          if (email != null && email.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _headerContactRow(
              Icons.email_outlined,
              email,
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeading(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      ) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      BuildContext context,
      List<_InfoItem> items,
      ) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colors.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        items[i].icon,
                        size: 19,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i].label,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            items[i].value,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i != items.length - 1)
                Divider(
                  height: 1,
                  color: colors.outlineVariant.withOpacity(0.45),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipCard(
      BuildContext context,
      Map<String, dynamic> membership,
      ) {
    final colors = Theme.of(context).colorScheme;
    final plan = membership['membershipPlan'];
    final planName = plan is Map && plan['name'] != null
        ? plan['name'].toString()
        : 'Membership plan';
    final status = _value(membership['status']);
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: colors.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    planName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _membershipDate(
                  context,
                  'START DATE',
                  _formatDate(membership['startDate']),
                  Icons.play_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _membershipDate(
                  context,
                  'END DATE',
                  _formatDate(membership['endDate']),
                  Icons.event_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _membershipDate(
      BuildContext context,
      String label,
      String date,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.7,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            date,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMembershipCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.card_membership_outlined,
            size: 42,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No membership records yet',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Memberships will appear here once assigned.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }






}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
