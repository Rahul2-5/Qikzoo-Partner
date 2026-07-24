import 'package:equatable/equatable.dart';

enum SupportTicketStatus { open, inProgress, resolved }

class SupportTicketModel extends Equatable {
  final String id;
  final String subject;
  final SupportTicketStatus status;
  final DateTime createdAt;

  const SupportTicketModel({
    required this.id,
    required this.subject,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, subject, status, createdAt];
}
