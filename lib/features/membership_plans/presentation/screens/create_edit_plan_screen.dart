import 'package:flutter/material.dart';

import '../../data/membership_plan_repository.dart';
import '../../models/membership_plan_model.dart';

class CreateEditPlanScreen extends StatefulWidget {
  final MembershipPlanModel? plan;

  const CreateEditPlanScreen({
    super.key,
    this.plan,
  });

  @override
  State<CreateEditPlanScreen> createState() => _CreateEditPlanScreenState();
}

class _CreateEditPlanScreenState extends State<CreateEditPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = MembershipPlanRepository();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  bool _isSaving = false;

  bool get _isEditing => widget.plan != null;

  @override
  void initState() {
    super.initState();

    final plan = widget.plan;

    if (plan != null) {
      _nameController.text = plan.name;
      _descriptionController.text = plan.description ?? '';
      _priceController.text = plan.price.toStringAsFixed(2);
      _durationController.text = plan.durationDays.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'durationDays': int.parse(_durationController.text.trim()),
    };

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await _repository.updateMembershipPlan(widget.plan!.id, data);
      } else {
        await _repository.createMembershipPlan(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Membership plan updated'
                : 'Membership plan created',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Plan' : 'Create Plan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Plan Name',
                  hintText: 'e.g. Monthly Plan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.card_membership),
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';

                  if (name.isEmpty) return 'Enter plan name';
                  if (name.length < 2) {
                    return 'Plan name must contain at least 2 characters';
                  }
                  if (name.length > 50) {
                    return 'Plan name cannot exceed 50 characters';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Describe what this plan includes',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final price = double.tryParse(value?.trim() ?? '');

                  if (price == null || !price.isFinite || price <= 0) {
                    return 'Enter a valid price greater than zero';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  suffixText: 'days',
                  hintText: 'e.g. 30, 90, 365',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final days = int.tryParse(value?.trim() ?? '');

                  if (days == null || days <= 0) {
                    return 'Enter a valid duration';
                  }

                  if (days > 3650) {
                    return 'Duration cannot exceed 3650 days';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePlan,
                  child: _isSaving
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(_isEditing ? 'Update Plan' : 'Create Plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}