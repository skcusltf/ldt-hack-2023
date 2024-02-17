import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lodt_hack/generated/app.pb.dart';
import 'package:lodt_hack/styles/ColorResources.dart';
import 'package:google_fonts/google_fonts.dart';

import '../clients/ApiClient.dart';
import '../models/consultation/Consultation.dart';
import '../providers/LocalStorageProvider.dart';
import 'call.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:grpc/grpc.dart';

class Consultation extends StatefulWidget {
  const Consultation({super.key, required this.consultationModel});

  final ConsultationModel consultationModel;

  @override
  State<Consultation> createState() => _ConsultationState();
}

class _ConsultationState extends State<Consultation> {
  late VideoPlayerController _controller;
  String? token;

  void fetchData() {
    storageProvider.getToken().then(
          (value) => setState(
            () {
              token = value!;
            },
          ),
        );
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    _controller = VideoPlayerController.network(
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Widget consultationCard(String type, String? text) {
    return Material(
      color: CupertinoColors.systemGrey6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                text ?? "—",
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget recordingVideo() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            SizedBox(
              width: 350,
              child: AspectRatio(
                aspectRatio: 16.0 / 9.0,
                child: Stack(
                  children: [
                    Container(color: ColorResources.black),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                        child: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withAlpha(128)),
                          height: 8,
                          width: 300,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () {
                            launchUrl(
                              Uri.parse(
                                'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                              ),
                            );
                          },
                          child: Icon(
                            Icons.open_in_new_rounded,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
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

    return _controller.value.isInitialized
        ? ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: Stack(
                    children: [
                      VideoPlayer(_controller),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _controller.value.isPlaying
                                  ? _controller.pause()
                                  : _controller.play();
                            });
                          },
                          child: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : const Material(
            child: Text(
              "Запись обрабатывается и скоро будет доступна",
              style: TextStyle(fontSize: 14),
            ),
          );
  }

  Future<void> cancelConsultation(String id) async {
    print("cancelling consultation with id = $id");
    try {
      await apiClient.cancelConsultationAppointment(
        CancelConsultationAppointmentRequest(id: id),
        options: CallOptions(
          metadata: {'Authorization': 'Bearer ${token!}'},
        ),
      );
    } on GrpcError catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Ошибка отмены консультации"),
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

  void showCancelConsultationDialog(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Вы уверены, что хотите отменить консультацию?"),
          content: const Text("Операцию невозможно будет отменить"),
          actions: [
            TextButton(
              child:
                  const Text("Продолжить", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await cancelConsultation(id).then(
                  (value) => Timer(
                    const Duration(milliseconds: 200),
                    () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
            TextButton(
              child: const Text("Отмена"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(
              "Консультация",
              style: GoogleFonts.ptSerif(fontWeight: FontWeight.w100),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                verticalDirection: VerticalDirection.down,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: Text("Редактировать данные"),
                    style: ButtonStyle(
                      foregroundColor:
                          MaterialStateProperty.all(ColorResources.accentRed),
                      overlayColor: MaterialStateProperty.all(
                        ColorResources.accentRed.withOpacity(0.1),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  consultationCard(
                    "Тема",
                    widget.consultationModel.title,
                  ),
                  SizedBox(height: 8),
                  consultationCard(
                    "Описание",
                    widget.consultationModel.description,
                  ),
                  SizedBox(height: 8),
                  consultationCard(
                    "Дата начала",
                    widget.consultationModel.day,
                  ),
                  SizedBox(height: 8),
                  consultationCard(
                    "Время",
                    "${widget.consultationModel.time ?? ""} – ${widget.consultationModel.endTime ?? ""}",
                  ),
                  SizedBox(height: 32),
                  if (widget.consultationModel.cancelled == null ||
                      widget.consultationModel.cancelled == false)
                    (widget.consultationModel.tags != null &&
                            widget.consultationModel.tags!.isNotEmpty)
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Material(
                                  child: Text(
                                    "Видеозапись",
                                    style: GoogleFonts.ptSerif(fontSize: 24),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                recordingVideo(),
                                const SizedBox(height: 32),
                              ])
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 32),
                              Container(
                                height: 48,
                                width: double.infinity,
                                child: CupertinoButton(
                                  color: ColorResources.accentRed,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) => Call(
                                          consultationModel:
                                              widget.consultationModel,
                                          channel:
                                              widget.consultationModel.id ??
                                                  "default",
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text("Подключиться"),
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                height: 48,
                                width: double.infinity,
                                child: CupertinoButton(
                                  color: ColorResources.accentPink,
                                  onPressed: () {
                                    showCancelConsultationDialog(
                                        widget.consultationModel.id!);
                                  },
                                  child: const Text(
                                    "Отменить консультацию",
                                    style: TextStyle(
                                      color: ColorResources.accentRed,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                  if (widget.consultationModel.cancelled != null &&
                      widget.consultationModel.cancelled!)
                    const Material(
                      child: Padding(
                        padding: EdgeInsets.only(top: 32.0),
                        child: Center(
                          child: Text(
                            "Консультация была отменена",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
