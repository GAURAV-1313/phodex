/// Validates a scanned QR payload as a Phodex backend address: it must be
/// an absolute http/https URL with a host. Anything else (a random QR code
/// in the room, a bare word, a mailto:) is rejected so the app never tries
/// to "connect" to something that isn't a server. Returns the normalized
/// address, or null when the payload isn't one.
String? parsePhodexAddress(String raw) {
  final input = raw.trim();
  if (input.isEmpty) return null;
  final uri = Uri.tryParse(input);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;
  return uri.toString();
}
