/// Add contact screen — form to add a new emergency contact.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../models/emergency_contact.dart';
import '../providers/auth_provider.dart';
import '../screens/contacts_screen.dart';
import '../services/local_database_service.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

class AddContactScreen extends ConsumerStatefulWidget {
  const AddContactScreen({super.key});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _smsEnabled = true;
  bool _pushEnabled = true;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Emergency Contact'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.person_add, size: 36, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.textHint),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+237 ...',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textHint),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Phone is required' : null,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textHint),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 32),

                // Notification preferences
                const Text('Notification Settings',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                _toggleTile(
                  Icons.sms_outlined,
                  'SMS Notifications',
                  'Send SMS during emergencies',
                  _smsEnabled,
                  (v) => setState(() => _smsEnabled = v),
                ),
                _toggleTile(
                  Icons.notifications_outlined,
                  'Push Notifications',
                  'Send push notifications during emergencies',
                  _pushEnabled,
                  (v) => setState(() => _pushEnabled = v),
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveContact,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Contact'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleTile(IconData icon, String title, String subtitle,
      bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.accent),
        title: Text(title),
        subtitle: Text(subtitle,
            style: const TextStyle(
                color: AppColors.textHint, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.accent,
      ),
    );
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final userId = ref.read(currentUserIdProvider) ?? 'local';
    final contact = EmergencyContact(
      id: const Uuid().v4(),
      userId: userId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      isSmsEnabled: _smsEnabled,
      isPushEnabled: _pushEnabled,
    );

    // Save locally.
    await LocalDatabaseService.instance.upsertEmergencyContact(contact);

    // Sync to Supabase.
    try {
      await SupabaseService.instance.addEmergencyContact(contact);
    } catch (_) {
      // Will sync later.
    }

    ref.invalidate(contactsProvider);

    if (mounted) {
      setState(() => _isSaving = false);
      context.pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
