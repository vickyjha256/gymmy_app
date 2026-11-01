
import 'package:flutter/material.dart';

import '../data/member_repository.dart';
import '../models/member_model.dart';
import 'add_member_screen.dart';
import 'member_details_screen.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final MemberRepository _repository = MemberRepository();
  final TextEditingController _searchController = TextEditingController();

  List<MemberModel> _members = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final members = await _repository.getMembers(
        search: _searchController.text,
      );

      if (!mounted) return;

      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load members. Please try again.';
        _isLoading = false;
      });
    }
  }


  Future<void> _openAddMember() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddMemberScreen(),
      ),
    );

    if (added == true && mounted) {
      await _loadMembers();
    }
  }





  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Members',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loadMembers,
            tooltip: 'Refresh members',
            icon: const Icon(Icons.refresh),
          ),

          IconButton(
            onPressed: _openAddMember,
            tooltip: 'Add member',
            icon: const Icon(Icons.person_add_alt_1),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _loadMembers(),
                decoration: InputDecoration(
                  hintText: 'Search by name or phone',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      _loadMembers();
                    },
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 44),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadMembers,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_members.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMembers,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.people_outline, size: 56),
            SizedBox(height: 16),
            Center(
              child: Text('No members found'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final member = _members[index];

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MemberDetailsScreen(
                      memberId: member.id,
                    ),
                  ),
                ).then((res) {
                  _loadMembers();
                });
              },

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                child: Text(
                  member.firstName.isNotEmpty
                      ? member.firstName[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Text(
                member.fullName.isEmpty
                    ? 'Unnamed member'
                    : member.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(member.phone),
              ),
              trailing: _buildStatus(member.status),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatus(String status) {
    final isActive = status.toUpperCase() == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toLowerCase() == 'unknown'
            ? 'Unknown'
            : status[0].toUpperCase() + status.substring(1).toLowerCase(),
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
