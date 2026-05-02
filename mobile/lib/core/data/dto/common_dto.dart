DateTime parseDateTime(dynamic value) {
  if (value == null) {
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
  return DateTime.parse(value as String).toUtc();
}

DateTime? parseNullableDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.parse(value as String).toUtc();
}
