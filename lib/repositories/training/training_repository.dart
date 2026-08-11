import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/training/training_module_model.dart';

abstract class TrainingRepository {
  Future<List<TrainingModuleModel>> getModules();
  Future<void> markCompleted(String moduleId);
}

/// No training-content backend exists yet — returns an empty list rather
/// than fabricated modules, so the screen shows its real (empty) state.
class NoTrainingContentRepository implements TrainingRepository {
  @override
  Future<List<TrainingModuleModel>> getModules() async => const [];

  @override
  Future<void> markCompleted(String moduleId) async {}
}

final trainingRepositoryProvider =
    Provider<TrainingRepository>((ref) => NoTrainingContentRepository());
