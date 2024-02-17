import 'package:lodt_hack/generated/google/protobuf/timestamp.pb.dart';

Timestamp dateFromString(String text) {
  final splitted = text.split('.').map((e) => int.parse(e)).toList();
  return Timestamp.fromDateTime(
    DateTime(splitted[2], splitted[1], splitted[0]),
  );
}

String stringFromTimestamp(Timestamp ts) {
  final dateTime = ts.toDateTime();

  String day = dateTime.day.toString();
  String month = dateTime.month.toString();

  if (dateTime.day < 10) {
    day = "0$day";
  }

  if (dateTime.month < 10) {
    month = "0$month";
  }

  return "$day.$month.${dateTime.year}";
}

bool isBlank(String? s) {
  return s == null || s.trim().isEmpty;
}

String len1add0(String s) {
  if (s.length == 1) {
    return "0$s";
  }

  return s;
}

String formatTime(Timestamp time) {
  return "${len1add0(time.toDateTime().hour.toString())}:${len1add0(time.toDateTime().minute.toString())}" ;
}

String formatInterval(Timestamp from, Timestamp to) {
  return "${len1add0(from.toDateTime().hour.toString())}:${len1add0(from.toDateTime().minute.toString())} "
      "– ${len1add0(to.toDateTime().hour.toString())}:${len1add0(to.toDateTime().minute.toString())}";
}

String formatDate(String date) {
  final splitted = date.split('.').map((e) => int.parse(e)).toList();
  final dt = DateTime(splitted[2], splitted[1], splitted[0]);

  if (dt.year == DateTime.now().year && dt.month == DateTime.now().month) {
    if (dt.day == DateTime.now().day) {
      return "Сегодня";
    }

    if (dt.day == DateTime.now().day + 1) {
      return "Завтра";
    }

    if (dt.day == DateTime.now().day - 1) {
      return "Вчера";
    }

    if (dt.day == DateTime.now().day + 2) {
      return "Послезавтра";
    }

    if (dt.day == DateTime.now().day - 2) {
      return "Позавчера";
    }
  }

  return "${splitted[0]} ${[
    "Января",
    "Февраля",
    "Марта",
    "Апреля",
    "Мая",
    "Июня",
    "Июля",
    "Августа",
    "Сентября",
    "Октября",
    "Ноября",
    "Декабря"
  ][splitted[1] - 1]}";
}
