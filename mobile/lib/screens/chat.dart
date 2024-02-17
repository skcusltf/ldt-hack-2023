import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lodt_hack/clients/ApiClient.dart';
import 'package:lodt_hack/providers/LocalStorageProvider.dart';
import 'package:lodt_hack/utils/widgets.dart';
import 'package:lodt_hack/widgets/ChatCard.dart';

import '../generated/app.pb.dart';
import '../models/chat/Chat.dart';
import '../models/chat/Message.dart';
import '../styles/ColorResources.dart';
import '../utils/parser.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grpc/grpc.dart';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'info.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final ScrollController _controller = ScrollController();
  final _inputController = TextEditingController();

  ChatHolder chat = ChatHolder([]);
  String? token;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  /// This has to happen only once per app
  void _initSpeech() async {
    print("speech init");
    await _speechToText.initialize();
    _stopListening();
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    print("speech start");
    await _speechToText.listen(onResult: _onSpeechResult, localeId: "ru-RU");
    setState(() {
      _speechEnabled = true;
    });
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    print("speech stop");
    await _speechToText.stop();
    setState(() {
      _speechEnabled = false;
    });
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _inputController.text = result.recognizedWords;
      print("speech result: " + _lastWords);
    });
  }

  @override
  void initState() {
    super.initState();

    storageProvider.getChat().then(
          (value) => setState(
            () {
              chat = value;
              print(chat.toJson());
              Future.delayed(
                const Duration(milliseconds: 50),
                () {
                  _controller.animateTo(
                    _controller.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.ease,
                  );
                },
              );
            },
          ),
        );
    storageProvider.getToken().then(
          (value) => setState(
            () {
              token = value!;
            },
          ),
        );
    _initSpeech();
  }

  void _scrollDown([int delay = 100]) {
    Future.delayed(Duration(milliseconds: delay), () {
      _controller.animateTo(
        _controller.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  Widget rateCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Card(
              color: ColorResources.accentRed,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 20,
                    onPressed: () {
                      sendMessage(
                        "Спасибо за обратную связь, рад помочь!",
                        false,
                        [],
                      );
                    },
                    icon: const Icon(
                      Icons.thumb_up_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    iconSize: 20,
                    onPressed: () {
                      sendMessage("Вот, что еще удалось найти:", false, [
                        "Список нормативных актов",
                        "Список органов контроля",
                        "Список обязательных требований"
                      ]);
                    },
                    icon: const Icon(
                      Icons.thumb_down_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget chatCard(String text, bool my, List<String> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              my ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Stack(
              children: [
                Column(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Card(
                        color: my
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
                              Text(
                                text,
                                softWrap: true,
                                style: TextStyle(
                                    color: (my ? Colors.white : Colors.black)),
                                maxLines: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!my) const SizedBox(height: 20),
                  ],
                ),
                if (!my)
                  Positioned(
                    bottom: -4,
                    left: 8,
                    child: Card(
                      color: CupertinoColors.systemGrey3,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: const Padding(
                        padding: EdgeInsets.only(
                            left: 8.0, right: 8, top: 8, bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.thumb_up_rounded,
                              color: CupertinoColors.systemGrey,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Icon(
                              Icons.thumb_down_rounded,
                              size: 20,
                              color: CupertinoColors.systemGrey,
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
        // const SizedBox(height: 8),
      ],
    );
  }

  Widget chatInput() {
    return GestureDetector(
      onTap: () => _scrollDown(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        color: CupertinoColors.systemGrey5,
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _speechEnabled ? Icons.mic : Icons.mic_off,
                color: _speechEnabled
                    ? ColorResources.red
                    : ColorResources.darkGrey,
              ),
              onPressed: _speechToText.isNotListening
                  ? _startListening
                  : _stopListening,
            ),
            Expanded(
              child: TextField(
                onChanged: (text) => _scrollDown,
                onTap: _scrollDown,
                controller: _inputController,
                cursorColor: Colors.black,
                onSubmitted: (String text) {
                  sendMessage(text, true, []);
                  _inputController.clear();
                },
                decoration: InputDecoration(
                  hintText: "Введите запрос...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderSide:
                        const BorderSide(width: 0, style: BorderStyle.none),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded,
                  color: ColorResources.darkGrey),
              onPressed: () {
                if (!isBlank(_inputController.text)) {
                  _stopListening();
                  sendMessage(_inputController.text, true, []);
                  _inputController.clear();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void processResponse(String text) async {
    try {
      await apiClient
          .sendChatBotMessage(
            SendChatBotMessageRequest(message: text),
            options: CallOptions(
              metadata: {'Authorization': 'Bearer $token'},
            ),
          )
          .then(
            (p0) => {
              p0.messages
                  .map(
                (e) => Message(
                    text: e,
                    sentByUser: false,
                    results: [],
                    reaction: MessageReaction.none,
                    originMessageText: text),
              )
                  .forEach(
                (element) {
                  chat.messages.add(element);
                },
              ),
              setState(
                () {
                  storageProvider.saveChat(chat);
                  _scrollDown();
                },
              )
            },
          );
    } on GrpcError catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Ошибка отправки сообщения"),
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

  void sendMessage(String text, bool byUser, List<String> results) {
    if (isBlank(text)) {
      return;
    }

    setState(() {
      final message = Message(
          text: text,
          sentByUser: byUser,
          results: results,
          reaction: MessageReaction.none,
          originMessageText: "");

      chat.messages.add(message);
      storageProvider.saveChat(chat);

      if (byUser) {
        processResponse(text);
      } else {
        _scrollDown();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: chatInput(),
      body: CupertinoPageScaffold(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          shrinkWrap: true,
          controller: _controller,
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(
                "Чат",
                style: GoogleFonts.ptSerif(fontWeight: FontWeight.w100),
              ),
              trailing: Material(
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => Info(
                            title: "Поиск по чату",
                            subtitle:
                                "Производите поиск по сообщениям в диалоге с чат-ботом",
                            description: "",
                            externalLink: "https://google.com",
                            buttonLabel: "Найти",
                            customBody: searchBox(),
                          ),
                        ),
                      );
                    });
                  },
                  iconSize: 28,
                  color: CupertinoColors.darkBackgroundGray,
                  icon: const Icon(CupertinoIcons.search),
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  verticalDirection: VerticalDirection.down,
                  children: [
                    if (chat.messages.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Сообщений пока нет",
                                softWrap: true,
                                maxLines: 3,
                                style: GoogleFonts.ptSerif(fontSize: 20),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 300),
                                child: Text(
                                  "Напишите любой вопрос и бот даст на него ответ",
                                  softWrap: true,
                                  maxLines: 3,
                                  style: GoogleFonts.ptSerif(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ...chat.messages.map(
                      (e) => ChatCard(
                        token: token!,
                        message: e,
                        onUpdate: (message) {
                          setState(
                            () {
                              chat.messages[chat.messages.indexWhere(
                                  (element) =>
                                      element.text == message.text)] = message;
                              storageProvider.saveChat(chat);
                              print(chat);
                            },
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
