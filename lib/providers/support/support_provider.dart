import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/support/support_repository.dart';
import '../../models/support/support_ticket_model.dart';

class SupportTicketsNotifier extends AsyncNotifier<List<SupportTicketModel>> {
  @override
  Future<List<SupportTicketModel>> build() => ref.watch(supportRepositoryProvider).getTickets();

  Future<void> createTicket(String subject) async {
    final ticket = await ref.read(supportRepositoryProvider).createTicket(subject);
    state = AsyncData([...(state.value ?? []), ticket]);
  }
}

final supportTicketsProvider = AsyncNotifierProvider<SupportTicketsNotifier, List<SupportTicketModel>>(
  SupportTicketsNotifier.new,
);
