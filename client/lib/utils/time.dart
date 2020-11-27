import 'package:intl/intl.dart';

class TimeUtil {
  static final TimeUtil _singleton = TimeUtil._internal();

  static final DateTime now = DateTime.now();

  String getCurrentTime() {
    return DateFormat('Hms').format(now);
  }

  factory TimeUtil() {
    return _singleton;
  }

  TimeUtil._internal();
}
