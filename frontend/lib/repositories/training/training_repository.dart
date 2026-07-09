import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/training/training_module_model.dart';

abstract class TrainingRepository {
  Future<List<TrainingModuleModel>> getModules();
  Future<void> markCompleted(String moduleId);
}

class MockTrainingRepository implements TrainingRepository {
  final List<TrainingModuleModel> _modules = const [
    TrainingModuleModel(id: 'm1', title: 'Pickup Process', description: 'How to pick up orders', durationMinutes: 5, isCompleted: false),
    TrainingModuleModel(id: 'm2', title: 'Customer Interaction', description: 'Talking to customers', durationMinutes: 4, isCompleted: false),
    TrainingModuleModel(id: 'm3', title: 'Safety', description: 'Road and delivery safety', durationMinutes: 6, isCompleted: false),
    TrainingModuleModel(id: 'm4', title: 'Cash Orders', description: 'Handling cash payments', durationMinutes: 3, isCompleted: false),
    TrainingModuleModel(id: 'm5', title: 'Emergency Support', description: 'What to do in an emergency', durationMinutes: 4, isCompleted: false),
    TrainingModuleModel(id: 'm6', title: 'Delivery Guidelines', description: 'General delivery guidelines', durationMinutes: 5, isCompleted: false),
  ];

  @override
  Future<List<TrainingModuleModel>> getModules() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return _modules;
  }

  @override
  Future<void> markCompleted(String moduleId) async {
    await Future.delayed(AppConstants.mockNetworkDelay);
  }
}

final trainingRepositoryProvider = Provider<TrainingRepository>((ref) => MockTrainingRepository());
