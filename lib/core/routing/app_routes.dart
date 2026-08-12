abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const events = '/events';
  static const eventsDetails = '/events-details';
  static const locate = '/locate';
  static const devices = '/devices';
  static const settings = '/settings';
  static const privacy = '/privacy';
  static const about = '/about';
  static const privacyConsent = '/privacy-consent';
  static const account = '/account';
  static const premium = '/premium';

  /// `/events-details/yyyy-MM-dd`
  static String eventsDetailsFor(DateTime day) {
    final local = day.toLocal();
    final d = DateTime(local.year, local.month, local.day);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$eventsDetails/$y-$m-$dd';
  }

  static DateTime? parseEventsDay(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }
}
