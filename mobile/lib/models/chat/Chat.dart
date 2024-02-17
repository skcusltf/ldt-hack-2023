import 'dart:convert';

import 'Message.dart';

class ChatHolder {
  List<Message> messages = [];

  ChatHolder(List<Message> messages);

  ChatHolder.fromJson(Map<String, dynamic> json) {
    if (json['messages'] == null) {
      return;
    }

    List<dynamic> m = jsonDecode(json['messages']);
    messages = m.map((e) => Message.fromJson(e)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'messages': jsonEncode(messages.map((e) => e.toJson()).toList()),
    };
  }
}
