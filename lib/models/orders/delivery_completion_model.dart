import 'package:equatable/equatable.dart';

class DeliveryCompletionModel extends Equatable {
  const DeliveryCompletionModel({
    required this.riderOrderId,
    required this.deliveredAt,
    required this.earningsPaise,
  });

  final String riderOrderId;
  final DateTime deliveredAt;
  final int? earningsPaise;

  factory DeliveryCompletionModel.fromJson(Map<String, dynamic> json) {
    final deliveredAt = DateTime.tryParse(
      json['deliveredAt']?.toString() ?? '',
    )?.toLocal();
    final earnings = json['earningsPaise'];
    return DeliveryCompletionModel(
      riderOrderId: json['id']?.toString() ?? '',
      deliveredAt: deliveredAt ?? DateTime.now(),
      earningsPaise: earnings is num ? earnings.round() : null,
    );
  }

  @override
  List<Object?> get props => [riderOrderId, deliveredAt, earningsPaise];
}
