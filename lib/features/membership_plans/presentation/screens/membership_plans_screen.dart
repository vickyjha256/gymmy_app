import 'package:flutter/material.dart';

import '../../data/membership_plan_repository.dart';
import '../../models/membership_plan_model.dart';
import '../widgets/membership_plan_card.dart';
import 'create_edit_plan_screen.dart';

class MembershipPlansScreen extends StatefulWidget {
  const MembershipPlansScreen({super.key});

  @override
  State<MembershipPlansScreen> createState() => _MembershipPlansScreenState();
}

class _MembershipPlansScreenState extends State<MembershipPlansScreen> {
  final MembershipPlanRepository _repository = MembershipPlanRepository();

  List<MembershipPlanModel> _plans = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final plans = await _repository.getMembershipPlans();

      if (!mounted) return;

      setState(() {
        _plans = plans;
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

  Future<void> _openCreateScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateEditPlanScreen(),
      ),
    );

    if (result == true) {
      _loadPlans();
    }
  }

  Future<void> _openEditScreen(MembershipPlanModel plan) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEditPlanScreen(plan: plan),
      ),
    );

    if (result == true) {
      _loadPlans();
    }
  }

  Future<void> _toggleStatus(MembershipPlanModel plan) async {
    try {
      if (plan.isActive) {
        await _repository.deactivateMembershipPlan(plan.id);
      } else {
        await _repository.activateMembershipPlan(plan.id);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            plan.isActive
                ? 'Membership plan deactivated'
                : 'Membership plan activated',
          ),
        ),
      );

      await _loadPlans();
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    }
  }

  Future<void> _deletePlan(MembershipPlanModel plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete membership plan?'),
        content: Text(
          'Are you sure you want to delete "${plan.name}"? '
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteMembershipPlan(plan.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membership plan deleted')),
      );

      await _loadPlans();
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Plans'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateScreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Plan'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadPlans,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_plans.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPlans,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Icon(Icons.card_membership_outlined, size: 56),
            SizedBox(height: 16),
            Center(child: Text('No membership plans yet')),
            SizedBox(height: 8),
            Center(child: Text('Create your first membership plan')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPlans,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _plans.length,
        itemBuilder: (context, index) {
          final plan = _plans[index];

          return MembershipPlanCard(
            plan: plan,
            onEdit: () => _openEditScreen(plan),
            onToggleStatus: () => _toggleStatus(plan),
            onDelete: () => _deletePlan(plan),
          );
        },
      ),
    );
  }
}