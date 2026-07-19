import '../../auth/services/auth_service.dart';
import '../models/calendar_entry_model.dart';
import '../services/calendar_service.dart';

class CalendarController {
  final CalendarService _calendarService;
  final AuthService _authService;

  CalendarController({
    CalendarService? calendarService,
    AuthService? authService,
  })  : _calendarService = calendarService ?? CalendarService(),
        _authService = authService ?? AuthService();

  Stream<List<CalendarEntryModel>> watchEntriesForMonth(DateTime monthDate) {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    final start = DateTime(monthDate.year, monthDate.month, 1);
    final end = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);

    return _calendarService.watchEntriesInRange(uid, start, end);
  }

  Future<void> assignOutfitToDate({
    required DateTime date,
    required String outfitId,
    String? note,
  }) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');

    final entry = CalendarEntryModel(
      userId: uid,
      date: DateTime(date.year, date.month, date.day),
      outfitId: outfitId,
      garmentIds: const [],
      note: note,
      createdAt: DateTime.now(),
    );

    await _calendarService.saveEntry(entry);
  }

  Future<void> assignGarmentsToDate({
    required DateTime date,
    required List<String> garmentIds,
    String? note,
  }) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');

    if (garmentIds.isEmpty) {
      throw Exception('Selecciona al menos una prenda');
    }

    final entry = CalendarEntryModel(
      userId: uid,
      date: DateTime(date.year, date.month, date.day),
      outfitId: null,
      garmentIds: garmentIds,
      note: note,
      createdAt: DateTime.now(),
    );

    await _calendarService.saveEntry(entry);
  }

  Future<void> removeEntry(DateTime date) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    await _calendarService.deleteEntry(uid, date);
  }
}