import 'package:lodt_hack/generated/google/protobuf/timestamp.pb.dart';

String getLabel(Timestamp from, Timestamp to) {
    final now = Timestamp.fromDateTime(DateTime.now());

    if (now.toDateTime().isBefore(from.toDateTime())) {
      return "";
    }

    if (now.toDateTime().isAfter(to.toDateTime())) {
      return "Есть запись";
    }

    return "Уже началась";
}