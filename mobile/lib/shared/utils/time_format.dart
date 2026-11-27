String _two(int v) => v.toString().padLeft(2, '0');

DateTime? _parse(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString())?.toLocal();
}

/// "00:29"
String clockLabel(dynamic raw) {
  final d = _parse(raw);
  if (d == null) return '—';
  return '${_two(d.hour)}:${_two(d.minute)}';
}

/// "27/11 00:29"
String shortDateTimeLabel(dynamic raw) {
  final d = _parse(raw);
  if (d == null) return '—';
  return '${_two(d.day)}/${_two(d.month)} ${_two(d.hour)}:${_two(d.minute)}';
}
