// Simple in‑memory queue for offline tasks
// Each task is a function that returns a Future<void>
class OfflineQueue {
  OfflineQueue._privateConstructor();
  static final OfflineQueue instance = OfflineQueue._privateConstructor();

  final List<Future<void> Function()> _tasks = [];

  void addTask(Future<void> Function() task) {
    _tasks.add(task);
  }

  Future<void> processAll() async {
    while (_tasks.isNotEmpty) {
      final task = _tasks.removeAt(0);
      try {
        await task();
      } catch (e) {
        // If a task fails, re‑queue it for later retry
        _tasks.add(task);
        break; // exit to avoid tight loop when offline
      }
    }
  }
}
