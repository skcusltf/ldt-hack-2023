import 'dart:convert';

import 'package:lodt_hack/utils/parser.dart';

class ConsultationModel {
  String? id;
  String? title;
  String? description;

  // format: 15.04.2023
  String? day;

  // format: 13:00
  String? time;
  String? endTime;

  List<String>? tags;
  bool? cancelled;

  ConsultationModel({
    this.id,
    this.title,
    this.description,
    this.day,
    this.time,
    this.endTime,
    this.tags,
    this.cancelled,
  });

  ConsultationModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    day = json['day'];
    time = json['time'];
    endTime = json['end_time'];
    tags = (jsonDecode(json['tags']) as List<dynamic>)
        .map((e) => e as String)
        .toList();
    cancelled = jsonDecode(json['cancelled']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'day': day,
      'time': time,
      'end_time': endTime,
      'tags': jsonEncode(tags),
      'cancelled': jsonEncode(cancelled),
    };
  }

  DateTime date() {
    return dateFromString(day!).toDateTime(toLocal: true);
  }
}
