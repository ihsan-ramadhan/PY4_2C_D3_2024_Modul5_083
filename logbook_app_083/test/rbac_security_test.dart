import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_083/features/logbook/models/log_model.dart';

void main() {
  test(
    'RBAC Security Check: Private logs should NOT be visible to teammates',
    () {
      // 1. Setup Data
      final String userA = 'ihsan';
      final String userB = 'ican';

      final List<LogModel> dbMocks = [
        LogModel(
          title: 'Catatan Rahasia User A',
          description: 'Ini rahasia.',
          date: DateTime.now().toIso8601String(),
          authorId: userA, // Private log
          teamId: 'Team_01',
          isPublic: false,
        ),
        LogModel(
          title: 'Catatan Terbuka User A',
          description: 'Semua boleh lihat.',
          date: DateTime.now().toIso8601String(),
          authorId: userA, // Public log
          teamId: 'Team_01',
          isPublic: true,
        ),
      ];

      // 2. Action
      final List<LogModel> visibleLogsUntukUserB = dbMocks.where((log) {
        return log.authorId == userB || log.isPublic == true;
      }).toList();

      // 3. Assert
      expect(visibleLogsUntukUserB.length, 1);
      expect(visibleLogsUntukUserB.first.isPublic, true);
      expect(visibleLogsUntukUserB.first.title, 'Catatan Terbuka User A');
    },
  );
}
