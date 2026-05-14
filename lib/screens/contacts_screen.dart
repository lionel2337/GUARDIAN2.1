/// Contacts screen — list of emergency contacts.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/emergency_contact.dart';
import '../providers/auth_provider.dart';
import '../services/local_database_service.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

/// Provider for emergency contacts list.
final contactsProvider = FutureProvider<List<EmergencyContact>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return LocalDatabaseService.instance.getEmergencyContacts(userId);
});

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: contactsAsync.when(
          data: (contacts) {
            if (contacts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline_rounded,
                        size: 64, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    const Text('No Emergency Contacts',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    const Text(
                      'Add contacts who will be notified during emergencies',
                      style: TextStyle(color: AppColors.textHint),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return _ContactCard(contact: contact);
              },
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/contacts/add'),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Contact'),
        backgroundColor: AppColors.accent,
      ),
    );
  }
}

class _ContactCard extends ConsumerWidget {
  final EmergencyContact contact;
  const _ContactCard({required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: Text(
            contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: AppColors.accent, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(contact.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(contact.phone,
            style: const TextStyle(color: AppColors.textSecondary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contact.isSmsEnabled)
              const Icon(Icons.sms_outlined,
                  size: 18, color: AppColors.accent),
            if (contact.isPushEnabled)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.notifications_outlined,
                    size: 18, color: AppColors.accent),
              ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete') {
                  await LocalDatabaseService.instance
                      .deleteEmergencyContact(contact.id);
                  try {
                    await SupabaseService.instance
                        .deleteEmergencyContact(contact.id);
                  } catch (_) {}
                  ref.invalidate(contactsProvider);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
