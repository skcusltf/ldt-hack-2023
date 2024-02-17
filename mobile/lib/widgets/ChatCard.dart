import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lodt_hack/clients/ApiClient.dart';
import 'package:lodt_hack/generated/app.pb.dart';
import 'package:lodt_hack/models/chat/Message.dart';
import 'package:lodt_hack/screens/chat.dart';
import 'package:grpc/grpc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../styles/ColorResources.dart';

class ChatCard extends StatefulWidget {
  final String token;
  final Message message;
  final void Function(Message) onUpdate;

  const ChatCard({
    super.key,
    required this.token,
    required this.message,
    required this.onUpdate,
  });

  @override
  State<StatefulWidget> createState() => _ChatCardState();
}

class _ChatCardState extends State<ChatCard> {
  Future<void> rate(MessageReaction messageReaction) async {
    try {
      await apiClient.rateChatBot(
        RateChatBotRequest(
          id: null,
          rating: toRating(messageReaction),
        ),
        options: CallOptions(
          metadata: {'Authorization': 'Bearer ${widget.token}'},
        ),
      );
    } on GrpcError catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Ошибка оценки сообщения"),
            content: Text(e.message ?? "Текст ошибки отсутствует"),
            actions: [
              TextButton(
                child: Text("Продолжить"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: widget.message.sentByUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Stack(
              children: [
                Column(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Card(
                        color: widget.message.sentByUser
                            ? ColorResources.accentRed
                            : CupertinoColors.lightBackgroundGray,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              widget.message.sentByUser
                                  ? Text(
                                      widget.message.text,
                                      softWrap: true,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      maxLines: 10,
                                    )
                                  : MarkdownBody(
                                      data: widget.message.text,
                                      onTapLink: (text, url, title) {
                                        if (url != null) {
                                          launchUrl(
                                            Uri.parse(
                                              url,
                                            ),
                                          ); /*For url_launcher 6.1.0 and higher*/
                                        }
                                        // launch(url);  /*For url_launcher 6.0.20 and lower*/
                                      },
                                      softLineBreak: true,
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!widget.message.sentByUser) const SizedBox(height: 20),
                  ],
                ),
                if (!widget.message.sentByUser)
                  Positioned(
                    bottom: -4,
                    left: 8,
                    child: Card(
                      color: CupertinoColors.systemGrey3,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 8.0,
                          right: 8,
                          top: 8,
                          bottom: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(
                                  () {
                                    widget.message.reaction =
                                        widget.message.reaction ==
                                                MessageReaction.like
                                            ? MessageReaction.none
                                            : MessageReaction.like;
                                    rate(widget.message.reaction);
                                    widget.onUpdate(widget.message);
                                  },
                                );
                              },
                              child: Icon(
                                Icons.thumb_up_rounded,
                                color: widget.message.reaction ==
                                        MessageReaction.like
                                    ? ColorResources.accentRed
                                    : CupertinoColors.systemGrey,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                setState(
                                  () {
                                    widget.message.reaction =
                                        widget.message.reaction ==
                                                MessageReaction.dislike
                                            ? MessageReaction.none
                                            : MessageReaction.dislike;
                                    rate(widget.message.reaction);
                                    widget.onUpdate(widget.message);
                                  },
                                );
                              },
                              child: Icon(
                                Icons.thumb_down_rounded,
                                size: 20,
                                color: widget.message.reaction ==
                                        MessageReaction.dislike
                                    ? ColorResources.accentRed
                                    : CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        // ...results.map(
        //   (e) => Padding(
        //     padding: const EdgeInsets.only(top: 4.0, left: 8),
        //     child: Material(
        //       color: ColorResources.accentRed,
        //       shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(16)),
        //       child: Container(
        //         child: Padding(
        //           padding:
        //               const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        //           child: Column(
        //             crossAxisAlignment: CrossAxisAlignment.start,
        //             children: [
        //               Text(
        //                 e,
        //                 style: TextStyle(color: Colors.white),
        //               ),
        //             ],
        //           ),
        //         ),
        //       ),
        //     ),
        //   ),
        // ),
        // (my || results.isEmpty) ? SizedBox() : rateCard(),
        const SizedBox(height: 8),
        if (!widget.message.sentByUser) const SizedBox(height: 8),
      ],
    );
  }
}
