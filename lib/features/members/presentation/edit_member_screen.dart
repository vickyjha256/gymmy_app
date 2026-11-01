
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/member_repository.dart';

class EditMemberScreen extends StatefulWidget {
  final String memberId;
  final Map<String, dynamic> member;

  const EditMemberScreen({
    super.key,
    required this.memberId,
    required this.member,
  });

  @override
  State<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = MemberRepository();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;
  late final TextEditingController _notesController;

  String? _gender;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final member = widget.member;

    _firstNameController =
        TextEditingController(text: member['firstName']?.toString() ?? '');
    _lastNameController =
        TextEditingController(text: member['lastName']?.toString() ?? '');
    _phoneController =
        TextEditingController(text: member['phone']?.toString() ?? '');
    _emailController =
        TextEditingController(text: member['email']?.toString() ?? '');
    _addressController =
        TextEditingController(text: member['address']?.toString() ?? '');
    _heightController =
        TextEditingController(text: member['height']?.toString() ?? '');
    _weightController =
        TextEditingController(text: member['weight']?.toString() ?? '');
    _emergencyNameController = TextEditingController(
      text: member['emergencyContactName']?.toString() ?? '',
    );
    _emergencyPhoneController = TextEditingController(
      text: member['emergencyContactPhone']?.toString() ?? '',
    );
    _notesController =
        TextEditingController(text: member['notes']?.toString() ?? '');

    const genders = ['MALE', 'FEMALE', 'OTHER'];
    final existingGender = member['gender']?.toString().toUpperCase();
    _gender = genders.contains(existingGender) ? existingGender : null;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _optionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  double? _optionalNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    return double.tryParse(trimmed);
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'firstName': _firstNameController.text.trim(),
      'lastName': _optionalText(_lastNameController.text),
      'phone': _phoneController.text.trim(),
      'email': _optionalText(_emailController.text),
      'address': _optionalText(_addressController.text),
      'height': _optionalNumber(_heightController.text),
      'weight': _optionalNumber(_weightController.text),
      'emergencyContactName':
      _optionalText(_emergencyNameController.text),
      'emergencyContactPhone':
      _optionalText(_emergencyPhoneController.text),
      'notes': _optionalText(_notesController.text),
      'gender': _gender,
    };

    // Keep the existing date of birth unchanged.
    if (widget.member['dateOfBirth'] != null) {
      data['dateOfBirth'] = widget.member['dateOfBirth'];
    }


    try {
      await _repository.updateMember(widget.memberId, data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Member updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;

      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message']?.toString()
          : null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message ?? 'Could not update member. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update member: ${e.toString()}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Member',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Keep member information up to date.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle(context, 'Basic information'),
            const SizedBox(height: 12),
            _field(
              controller: _firstNameController,
              label: 'First name',
              icon: Icons.person_outline_rounded,
              required: true,
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Enter at least 2 characters';
                }
                return null;
              },
            ),
            _field(
              controller: _lastNameController,
              label: 'Last name',
              icon: Icons.person_outline_rounded,
            ),
            _field(
              controller: _phoneController,
              label: 'Phone number',
              icon: Icons.phone_outlined,
              required: true,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null ||
                    !RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) {
                  return 'Enter a valid 10-digit mobile number';
                }
                return null;
              },
            ),
            _field(
              controller: _emailController,
              label: 'Email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isNotEmpty &&
                    !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(email)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: _decoration(
                'Gender',
                Icons.wc_rounded,
              ),
              items: const [
                DropdownMenuItem(value: 'MALE', child: Text('Male')),
                DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                DropdownMenuItem(value: 'OTHER', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 24),

            _sectionTitle(context, 'Address & health'),
            const SizedBox(height: 12),
            _field(
              controller: _addressController,
              label: 'Address',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            Row(
              children: [
                Expanded(
                  child: _field(
                    controller: _heightController,
                    label: 'Height (cm)',
                    icon: Icons.height_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateNumber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    controller: _weightController,
                    label: 'Weight (kg)',
                    icon: Icons.monitor_weight_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateNumber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _sectionTitle(context, 'Emergency contact'),
            const SizedBox(height: 12),
            _field(
              controller: _emergencyNameController,
              label: 'Contact name',
              icon: Icons.contact_phone_outlined,
            ),
            _field(
              controller: _emergencyPhoneController,
              label: 'Contact phone',
              icon: Icons.phone_in_talk_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                final phone = value?.trim() ?? '';
                if (phone.isNotEmpty &&
                    !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
                  return 'Enter a valid 10-digit mobile number';
                }
                return null;
              },
            ),
            _field(
              controller: _notesController,
              label: 'Notes',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 28),

            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveMember,
                icon: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  _isSaving ? 'Saving changes...' : 'Save changes',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateNumber(String? value) {
    final number = value?.trim() ?? '';
    if (number.isEmpty) return null;

    final parsed = double.tryParse(number);
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid positive number';
    }
    return null;
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator ??
            (required
                ? (value) => value == null || value.trim().isEmpty
                ? 'This field is required'
                : null
                : null),
        decoration: _decoration(
          required ? '$label *' : label,
          icon,
        ),
      ),
    );
  }
}
