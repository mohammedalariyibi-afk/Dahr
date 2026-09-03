/// Fail closed when PostgREST returns zero rows (typical RLS deny).
List<Map<String, dynamic>> requireMutatedRows(
  dynamic result, {
  String code = 'write_rejected',
}) {
  if (result == null) {
    throw StateError(code);
  }
  if (result is List) {
    if (result.isEmpty) throw StateError(code);
    return [
      for (final row in result) Map<String, dynamic>.from(row as Map),
    ];
  }
  if (result is Map) {
    return [Map<String, dynamic>.from(result)];
  }
  throw StateError(code);
}
