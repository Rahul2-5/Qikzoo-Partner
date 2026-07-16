import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/support/support_ticket_model.dart';

abstract class SupportRepository {
  Future<List<SupportTicketModel>> getTickets();
  Future<SupportTicketModel> createTicket(String subject);
}

class MockSupportRepository implements SupportRepository {
  final List<SupportTicketModel> _tickets = [];

  @override
  Future<List<SupportTicketModel>> getTickets() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return List.unmodifiable(_tickets);
  }

  @override
  Future<SupportTicketModel> createTicket(String subject) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    final ticket = SupportTicketModel(
      id: 'ticket_${_tickets.length + 1}',
      subject: subject,
      status: SupportTicketStatus.open,
      createdAt: DateTime.now(),
    );
    _tickets.add(ticket);
    return ticket;
  }
}

final supportRepositoryProvider =
    Provider<SupportRepository>((ref) => MockSupportRepository());
