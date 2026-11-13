
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../members/data/member_repository.dart';
import '../../../members/models/member_model.dart';

class CreateMembershipScreen extends StatefulWidget {
  final Set<String> activeMemberIds;

  const CreateMembershipScreen({
    super.key,
    required this.activeMemberIds,
  });

  @override
  State<CreateMembershipScreen> createState() => _CreateMembershipScreenState();
}

class _CreateMembershipScreenState extends State<CreateMembershipScreen> {
  final MemberRepository _repository = MemberRepository();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  List<MemberModel> _members = [];

  bool _isLoading = true;
  String? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 350),
          () => _loadMembers(search: value.trim()),
    );
  }

  Future<void> _loadMembers({String search = ''}) async {
    final requestId = ++_requestId;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _repository.getMembers(
        page: 1,
        limit: 50,
        search: search,
      );

      if (!mounted || requestId != _requestId) return;

      // Exclude members who already have an ACTIVE membership.
      final eligibleMembers = result
          .where(
            (member) => !widget.activeMemberIds.contains(member.id),
      )
          .toList();

      setState(() {
        _members = eligibleMembers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _error = 'Unable to load members. Please try again.';
        _isLoading = false;
      });
    }
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: Column(
        children: [
          Icon(
            hasSearch
                ? Icons.search_off_rounded
                : Icons.people_outline_rounded,
            size: 42,
            color: const Color(0xFF9298A7),
          ),
          const SizedBox(height: 12),
          Text(
            hasSearch
                ? 'No matching members found'
                : 'No eligible members found',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263455),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Only members without an active membership appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9298A7),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        title: const Text(
          'Select Member',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose a member',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF202B43),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Search for a member to create a membership.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9298A7),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Color(0xFFE4E7EC),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Color(0xFFE4E7EC),
                        ),
                      ),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _loadMembers();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : _error != null
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => _loadMembers(
                        search: _searchController.text.trim(),
                      ),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              )
                  : _members.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: () => _loadMembers(
                  search: _searchController.text.trim(),
                ),
                child: ListView.separated(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    20, 12, 20, 24,
                  ),
                  itemCount: _members.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final member = _members[index];

                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pop(context, member);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                  const Color(0xFFEEF0FF),
                                  borderRadius:
                                  BorderRadius.circular(13),
                                ),
                                child: Text(
                                  member.fullName.isNotEmpty
                                      ? member.fullName[0]
                                      .toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Color(0xFF536DFE),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.fullName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                        FontWeight.w800,
                                        color:
                                        Color(0xFF202B43),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      member.phone,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color:
                                        Color(0xFF9298A7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF9298A7),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
