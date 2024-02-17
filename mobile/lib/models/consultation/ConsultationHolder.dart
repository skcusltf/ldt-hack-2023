import 'dart:convert';

import 'Consultation.dart';

class ConsultationHolder {
  List<ConsultationModel> consultations = [];

  ConsultationHolder(List<ConsultationModel> consultations);

  ConsultationHolder.fromJson(Map<String, dynamic> json) {
    if (json['consultations'] == null) {
      return;
    }

    List<dynamic> m = jsonDecode(json['consultations']);
    consultations = m.map((e) => ConsultationModel.fromJson(e)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'consultations': jsonEncode(consultations),
    };
  }
}
