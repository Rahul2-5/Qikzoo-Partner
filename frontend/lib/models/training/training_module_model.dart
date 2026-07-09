import 'package:equatable/equatable.dart';

class TrainingModuleModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final bool isCompleted;

  const TrainingModuleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.isCompleted,
  });

  TrainingModuleModel copyWith({bool? isCompleted}) => TrainingModuleModel(
        id: id,
        title: title,
        description: description,
        durationMinutes: durationMinutes,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  @override
  List<Object?> get props => [id, title, description, durationMinutes, isCompleted];
}
