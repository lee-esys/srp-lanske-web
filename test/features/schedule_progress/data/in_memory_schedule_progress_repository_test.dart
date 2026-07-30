import 'package:srp_lanske/features/schedule_progress/data/in_memory_schedule_progress_repository.dart';

import '../application/schedule_progress_repository_contract.dart';

void main() {
  runScheduleProgressRepositoryContractTests(
    name: 'InMemoryScheduleProgressRepository',
    createRepository: InMemoryScheduleProgressRepository.new,
  );
}
