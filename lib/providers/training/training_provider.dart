import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/training/training_repository.dart';
import '../../models/training/training_module_model.dart';

class TrainingModulesNotifier extends AsyncNotifier<List<TrainingModuleModel>> {
  @override
  Future<List<TrainingModuleModel>> build() => ref.watch(trainingRepositoryProvider).getModules();

  Future<void> markCompleted(String moduleId) async {
    await ref.read(trainingRepositoryProvider).markCompleted(moduleId);
    state = AsyncData([
      for (final module in state.value ?? [])
        if (module.id == moduleId) module.copyWith(isCompleted: true) else module,
    ]);
  }
}

final trainingModulesProvider = AsyncNotifierProvider<TrainingModulesNotifier, List<TrainingModuleModel>>(
  TrainingModulesNotifier.new,
);
