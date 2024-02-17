import 'dart:convert';

import 'package:lodt_hack/generated/app.pb.dart';

enum MessageReaction { like, dislike, none }

RateChatBotRequest_Rating toRating(MessageReaction reaction) {
  if (reaction == MessageReaction.like) {
    return RateChatBotRequest_Rating.RATING_POSITIVE;
  }

  if (reaction == MessageReaction.dislike) {
    return RateChatBotRequest_Rating.RATING_NEGATIVE;
  }

  return RateChatBotRequest_Rating.RATING_REMOVED;
}

class Message {
  String text = "";
  String originMessageText = "";
  bool sentByUser = true;
  List<String> results = [];
  MessageReaction reaction = MessageReaction.none;

  Message({
    required this.text,
    required this.sentByUser,
    required this.results,
    required this.reaction,
    required this.originMessageText,
  });

  Message.fromJson(Map<String, dynamic> json) {
    text = json['text'];
    sentByUser = jsonDecode(json['sent_by_user']);
    results = (jsonDecode(json['results']) as List<dynamic>)
        .map((e) => e as String)
        .toList();
    reaction = json['reaction'] == null
        ? MessageReaction.none
        : jsonDecode(json['reaction']) == 'like'
            ? MessageReaction.like
            : jsonDecode(json['reaction']) == 'dislike'
                ? MessageReaction.dislike
                : MessageReaction.none;
    originMessageText = json['origin_message_text'] ?? "";
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'sent_by_user': jsonEncode(sentByUser),
      'results': jsonEncode(results),
      'reaction': jsonEncode(reaction.name),
      'origin_message_text': originMessageText,
    };
  }
}
