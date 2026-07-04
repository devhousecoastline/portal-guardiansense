import 'package:intl/intl.dart';

String formatRelativeTime(DateTime? dateTime, {DateTime? now}) {
  if (dateTime == null) return '—';

  final reference = now ?? DateTime.now();
  final diff = reference.difference(dateTime);

  if (diff.isNegative || diff.inSeconds < 10) return 'agora';
  if (diff.inSeconds < 60) return 'há ${diff.inSeconds} segundos';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return 'há $m ${m == 1 ? 'minuto' : 'minutos'}';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return 'há $h ${h == 1 ? 'hora' : 'horas'}';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return 'há $d ${d == 1 ? 'dia' : 'dias'}';
  }

  return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
}
