
import 'package:flutter/material.dart';

import '../../../membership_plans/data/membership_plan_repository.dart';
import '../../../membership_plans/models/membership_plan_model.dart';
import '../../data/membership_repository.dart';

class RenewMembershipScreen extends StatefulWidget {
  final String memberId;
  final String memberName;

  const RenewMembershipScreen({
    super.key,
    required this.memberId,
    required this.memberName,
  });

  @override
  State<RenewMembershipScreen> createState() =>
      _RenewMembershipScreenState();
}

class _RenewMembershipScreenState extends State<RenewMembershipScreen> {
  final _planRepository = MembershipPlanRepository();
  final _membershipRepository = MembershipRepository();

  List<MembershipPlanModel> _plans = [];
  MembershipPlanModel? _selectedPlan;

  String _paymentMethod = 'CASH';
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await _planRepository.getMembershipPlans();

      if (!mounted) return;

      setState(() {
        _plans = plans.where((plan) => plan.isActive).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _renew() async {
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a membership plan')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await _membershipRepository.renewMembership(
        memberId: widget.memberId,
        membershipPlanId: _selectedPlan!.id,
        paymentMethod: _paymentMethod,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membership renewed successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Renew Membership',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _plans.isEmpty
          ? const Center(child: Text('No active membership plans found'))
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF1FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF536DFE),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Renewing membership for',
                        style: TextStyle(
                          color: Color(0xFF747F9C),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.memberName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'Select a plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          ..._plans.map((plan) {
            final selected = _selectedPlan?.id == plan.id;

            return GestureDetector(
              onTap: () => setState(() => _selectedPlan = plan),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF536DFE)
                        : const Color(0xFFE8EAF0),
                    width: selected ? 1.8 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: const Color(0xFF536DFE),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${plan.durationDays} days',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${plan.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          const Text(
            'Payment method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 10,
            children: ['CASH', 'UPI', 'CARD'].map((method) {
              final selected = _paymentMethod == method;

              return ChoiceChip(
                label: Text(method),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _paymentMethod = method),
                selectedColor: const Color(0xFFDEE3FF),
                labelStyle: TextStyle(
                  color: selected
                      ? const Color(0xFF344BBA)
                      : const Color(0xFF697184),
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _submitting ? null : _renew,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF293E79),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _submitting
                  ? const CircularProgressIndicator(
                color: Colors.white,
              )
                  : const Text(
                'Confirm Renewal',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
