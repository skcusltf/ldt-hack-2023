import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lodt_hack/clients/ApiClient.dart';
import 'package:lodt_hack/generated/google/protobuf/timestamp.pb.dart';
import 'package:lodt_hack/models/consultation/Consultation.dart';
import 'package:lodt_hack/models/consultation/ConsultationHolder.dart';
import 'package:lodt_hack/providers/LocalStorageProvider.dart';
import 'package:lodt_hack/screens/create_consultation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:lodt_hack/utils/calendar.dart';
import 'package:table_calendar/table_calendar.dart';

import '../generated/google/protobuf/empty.pb.dart';
import '../models/User.dart';
import '../styles/ColorResources.dart';
import '../utils/parser.dart';
import 'consultation.dart';
import 'package:grpc/grpc.dart';

class Zoom extends StatefulWidget {
  const Zoom({super.key});

  @override
  State<Zoom> createState() => _ZoomState();
}

class _ZoomState extends State<Zoom> {
  List<ConsultationModel> consultations = [];
  User user = User();
  String? token;
  Timer? timer;

  DateTime? from = null;
  DateTime? to = null;

  DateTime? tempFrom = null;
  DateTime? tempTo = null;

  GlobalKey<EventCalendarState> eventCalendarKey = GlobalKey();

  late Widget eventCalendar = EventCalendar(
    key: eventCalendarKey,
    consultations: consultations,
    consultationByDate: getConsultationByDay,
    rangeSelectionEnabled: true,
    onSelect: (f, t) {
      setState(() {
        tempFrom = f;
        tempTo = t;
      });
    },
    rangeStart: from,
    rangeEnd: to,
  );

  void fetchData() {
    storageProvider.getUser().then(
          (value) => setState(
            () {
              user = value!;
            },
          ),
        );
    storageProvider.getToken().then(
          (value) => setState(
            () {
              token = value!;
              fetchConsultations();
            },
          ),
        );

    fetchConsultations();
  }

  @override
  void initState() {
    super.initState();
    fetchData();

    timer = Timer.periodic(
        const Duration(seconds: 1), (Timer t) => fetchConsultations());
  }

  Future<void> fetchConsultations() async {
    if (token == null || !mounted) {
      return;
    }

    try {
      final response = await apiClient.listConsultationAppointments(
        Empty(),
        options: CallOptions(
          metadata: {'Authorization': 'Bearer ${token!}'},
        ),
      );

      setState(() {
        consultations = response.appointmentInfo
            .where((e) =>
                (to == null ||
                        e.fromTime.toDateTime().isBefore(to!) ||
                        isSameDay(e.fromTime.toDateTime(), to)) &&
                    (from == null || e.toTime.toDateTime().isAfter(from!)) ||
                isSameDay(e.toTime.toDateTime(), from))
            .map(
              (e) => ConsultationModel(
                id: e.id,
                title: e.topic,
                description:
                    "Предприниматель: ${e.businessUser.firstName} ${e.businessUser.lastName}\nИнспектор: ${e.authorityUser.firstName} ${e.authorityUser.lastName}",
                day: stringFromTimestamp(e.fromTime),
                time: formatTime(e.fromTime),
                endTime: formatTime(e.toTime),
                cancelled: e.canceled,
                tags: e.canceled ? ["Отменена"] : e.toTime.toDateTime().isBefore(DateTime.now()) ? ["Есть запись"] : [],
              ),
            )
            .toList();
      });
    } on GrpcError catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Ошибка получения данных"),
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

  List<ConsultationModel> sorted(List<ConsultationModel> c) {
    c.sort((a, b) => dateFromString(a.day!)
        .toDateTime()
        .compareTo(dateFromString(b.day!).toDateTime()));
    return c.reversed.toList();
  }

  Widget filterPanel() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (from != null)
            Chip(
              label: Text(
                "От ${formatDate(stringFromTimestamp(Timestamp.fromDateTime(from!)))}",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: ColorResources.accentRed,
              deleteIcon: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
              onDeleted: () {
                setState(() {
                  from = null;
                });
              },
            ),
          SizedBox(
            width: 8,
          ),
          if (to != null)
            Chip(
              label: Text(
                "До ${formatDate(stringFromTimestamp(Timestamp.fromDateTime(to!)))}",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: ColorResources.accentRed,
              deleteIcon: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
              onDeleted: () {
                setState(() {
                  to = null;
                });
              },
            ),
        ],
      ),
    );
  }

  ConsultationModel? getConsultationByDay(DateTime day) {
    if (consultations
        .where((element) => isSameDay(element.date(), day))
        .isEmpty) {
      return null;
    }

    return consultations
        .firstWhere((element) => isSameDay(element.date(), day));
  }

  void showCalendar() {
    showCupertinoModalBottomSheet(
      context: context,
      builder: (context) => Scaffold(
        persistentFooterAlignment: AlignmentDirectional.center,
        body: Container(
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    Text(
                      "Календарь",
                      style: GoogleFonts.ptSerif(fontSize: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Выберите интервал, в котором будут отображаться консультации",
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),
                    eventCalendar,
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: CupertinoButton(
                        color: ColorResources.accentRed,
                        onPressed: () {
                          setState(() {
                            from = tempFrom;
                            to = tempTo;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Применить",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 48,
                      width: double.infinity,
                      child: CupertinoButton(
                        color: ColorResources.accentPink,
                        onPressed: () {
                          setState(() {
                            eventCalendarKey.currentState?.clear();
                          });
                        },
                        child: const Text(
                          "Сбросить",
                          style: TextStyle(
                            color: ColorResources.accentRed,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CupertinoButton(
                    padding: EdgeInsets.all(0),
                    borderRadius: BorderRadius.circular(64),
                    color: CupertinoColors.systemGrey5,
                    onPressed: () => Navigator.of(context).popUntil(
                      (route) => route.settings.name == '/',
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: CupertinoColors.darkBackgroundGray,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget zoomCard(ConsultationModel consultation) {
    return Material(
      color: CupertinoColors.systemGrey6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        onTap: () => {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => Consultation(
                consultationModel: consultation,
              ),
            ),
          ),
          setState(() {
            fetchData();
          })
        },
        child: Container(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(consultation.title!),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${formatDate(consultation.day!)} с ${consultation.time} до ${consultation.endTime}",
                      style: const TextStyle(
                          color: CupertinoColors.systemGrey, fontSize: 14),
                    ),
                    Text(
                      consultation.tags == null || consultation.tags!.isEmpty
                          ? ""
                          : consultation.tags![0],
                      style: const TextStyle(
                          color: ColorResources.accentRed, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(
              "Консультации",
              style: GoogleFonts.ptSerif(fontWeight: FontWeight.w100),
            ),
            trailing: Material(
              child: IconButton(
                icon: const Icon(CupertinoIcons.calendar),
                onPressed: () {
                  showCalendar();
                },
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                verticalDirection: VerticalDirection.down,
                children: [
                  if (user.isBusiness())
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => CreateConsultation(),
                          ),
                        );

                        setState(
                          () {
                            Future.delayed(const Duration(seconds: 3), () {
                              fetchConsultations();
                            });
                          },
                        );
                      },
                      child: Text("Записаться на консультацию"),
                      style: ButtonStyle(
                        foregroundColor:
                            MaterialStateProperty.all(ColorResources.accentRed),
                        overlayColor: MaterialStateProperty.all(
                          ColorResources.accentRed.withOpacity(0.1),
                        ),
                      ),
                    ),
                  if (user.isBusiness()) SizedBox(height: 16),
                  filterPanel(),
                  if (consultations.isEmpty)
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 300),
                          child: Text(
                            user.isBusiness()
                                ? "Вы пока не записались ни на одну консультацию"
                                : "В данный момент вы не записаны в качестве инспектора на какую-либо консультацию",
                            softWrap: true,
                            maxLines: 3,
                            style: GoogleFonts.ptSerif(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ...sorted(consultations).map(
                    (e) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDate(e.day!),
                          textAlign: TextAlign.left,
                          style: GoogleFonts.ptSerif(fontSize: 24),
                        ),
                        SizedBox(height: 4),
                        zoomCard(e),
                        SizedBox(height: 16),
                      ],
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
