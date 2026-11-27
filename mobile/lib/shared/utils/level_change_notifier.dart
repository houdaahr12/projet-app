import 'package:flutter/material.dart';

import 'package:mobile/models/patient.dart';

/// Detects patients whose level got WORSE since the last check
/// (Normal -> Surveillance, Surveillance -> Alerte, ...), at most once per
/// patient every [cooldown]. Everything else should only update the bell badge.
///
/// Keep ONE instance alive for the whole session (use [instance]).
class LevelChangeNotifier {
  LevelChangeNotifier._();
  static final LevelChangeNotifier instance = LevelChangeNotifier._();

  static const Duration cooldown = Duration(minutes: 3);
  static const _rank = {'normal': 0, 'surveillance': 1, 'alerte': 2};

  final Map<int, String> _lastLevel = {};
  final Map<int, DateTime> _lastNotified = {};

  /// Call this each time you get a fresh patient list.
  /// The first time a patient is seen it is only recorded, never notified.
  List<PatientRecord> detectEscalations(List<PatientRecord> patients) {
    final escalated = <PatientRecord>[];
    final now = DateTime.now();
    for (final p in patients) {
      final current = p.levelKey;
      final currentRank = _rank[current];
      if (currentRank == null) continue; // unknown / pending

      final previous = _lastLevel[p.id];
      _lastLevel[p.id] = current;
      if (previous == null) continue;

      final previousRank = _rank[previous] ?? 0;
      if (currentRank <= previousRank) continue;

      final last = _lastNotified[p.id];
      if (last != null && now.difference(last) < cooldown) continue;

      _lastNotified[p.id] = now;
      escalated.add(p);
    }
    // Most severe first
    escalated.sort(
      (a, b) => (_rank[b.levelKey] ?? 0).compareTo(_rank[a.levelKey] ?? 0),
    );
    return escalated;
  }
}

/// Floating snackbar that does not cover the content.
void showEscalationSnackBar(
  BuildContext context,
  List<PatientRecord> escalated, {
  required void Function(PatientRecord patient) onView,
}) {
  if (escalated.isEmpty) return;
  final first = escalated.first;
  final text = escalated.length == 1
      ? 'Lit ${first.bed ?? '—'} · passage en ${first.levelLabel}'
      : 'Lit ${first.bed ?? '—'} · passage en ${first.levelLabel} (+${escalated.length - 1} autre${escalated.length > 2 ? 's' : ''})';

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 5),
      content: Text(text),
      action: SnackBarAction(label: 'Voir', onPressed: () => onView(first)),
    ),
  );
}
