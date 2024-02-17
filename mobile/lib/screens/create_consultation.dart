import 'dart:async';
import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lodt_hack/generated/app.pb.dart';
import 'package:lodt_hack/generated/google/protobuf/timestamp.pb.dart';
import 'package:lodt_hack/main.dart';
import 'package:lodt_hack/models/consultation/Consultation.dart';
import 'package:lodt_hack/styles/ColorResources.dart';
import 'package:google_fonts/google_fonts.dart';

import '../clients/ApiClient.dart';
import '../generated/google/protobuf/empty.pb.dart';
import '../models/consultation/ConsultationHolder.dart';
import '../providers/LocalStorageProvider.dart';
import '../utils/parser.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:grpc/grpc.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class CreateConsultation extends StatefulWidget {
  const CreateConsultation({super.key});

  @override
  State<CreateConsultation> createState() => _CreateConsultationState();
}

class _CreateConsultationState extends State<CreateConsultation> {
  ConsultationHolder consultations = ConsultationHolder([]);
  ConsultationModel consultation = ConsultationModel();

  final createConsultationFormKey = GlobalKey<FormState>();
  String? token;

  List<ListConsultationTopicsResponse_AuthorityTopics> authorityTopics = [];
  List<String> authorityNames = [];

  List<ListConsultationTopicsResponse_AuthorityTopic> consultationTopics = [];
  List<String> consultationNames = [];

  List<Timestamp> availableDates = [];
  List<String> dateNames = [];

  List<ListAvailableConsultationSlotsResponse_ConsultationSlot> availableSlots =
      [];
  List<String> availableSlotNames = [];

  String selectedAuthority = "";
  String consultationTheme = "";
  String selectedDateName = "";
  String selectedSlotName = "";

  void fetchData() {
    storageProvider.getConsultations().then(
          (value) => setState(
            () {
              consultations = value;
              print(consultations.toJson());
            },
          ),
        );

    storageProvider.getToken().then(
          (value) => setState(
            () {
              token = value!;
              getConsultationTopics();
            },
          ),
        );
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void getAvailableDates() async {
    try {
      final response = await apiClient.listAvailableConsultationDates(
        ListAvailableConsultationDatesRequest(
          authorityId: authorityTopics
              .where((element) => element.authorityName == selectedAuthority)
              .first
              .authorityId,
          fromDate: dateFromString("31.08.2002"),
          toDate: dateFromString("31.08.2024"),
        ),
        options: CallOptions(
          metadata: {'Authorization': 'Bearer $token'},
        ),
      );

      print(response.availableDates);

      setState(() {
        availableDates = response.availableDates;
        dateNames = availableDates
            .map((e) => formatDate(stringFromTimestamp(e)))
            .toList();
        selectedDateName = dateNames.isNotEmpty ? dateNames.first : "";

        getAvailableSlots();
      });
    } on GrpcError catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Ошибка получения данных"),
            content: Text(e.message ?? "Текст ошибки отсутствует"),
            actions: [
              TextButton(
                child: const Text("Продолжить"),
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

  void getAvailableSlots() async {
    try {
      final response = await apiClient.listAvailableConsultationSlots(
        ListAvailableConsultationSlotsRequest(
            authorityId: authorityTopics
                .where((element) => element.authorityName == selectedAuthority)
                .first
                .authorityId,
            date: availableDates[dateNames.indexOf(selectedDateName)]),
        options: CallOptions(
          metadata: {'Authorization': 'Bearer $token'},
        ),
      );

      print(response.consultationSlots);

      setState(() {
        availableSlots = response.consultationSlots;
        availableSlotNames = availableSlots
            .map((e) => formatInterval(e.fromTime, e.toTime))
            .toList();

        if (!availableSlotNames.contains(selectedSlotName)) {
          selectedSlotName = availableSlotNames.first;
        }
      });
    } on GrpcError catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Ошибка получения данных"),
            content: Text(e.message ?? "Текст ошибки отсутствует"),
            actions: [
              TextButton(
                child: const Text("Продолжить"),
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

  void createConsultation() async {
    try {
      final response = await apiClient.createConsultationAppointment(
        CreateConsultationAppointmentRequest(
          topicId: consultationTopics
              .where((element) => element.topicName == consultationTheme)
              .first
              .topicId,
          slotId:
              availableSlots[availableSlotNames.indexOf(selectedSlotName)].id,
        ),
        options: CallOptions(
          metadata: {'Authorization': 'Bearer $token'},
        ),
      );

      setState(() {
        Navigator.pop(context);
      });
    } on GrpcError catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Ошибка получения данных"),
            content: Text(e.message ?? "Текст ошибки отсутствует"),
            actions: [
              TextButton(
                child: const Text("Продолжить"),
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

  void getConsultationTopics() async {
    try {
      final response = await apiClient.listConsultationTopics(
        Empty(),
        options: CallOptions(
          metadata: {'Authorization': 'Bearer $token'},
        ),
      );

      setState(() {
        authorityTopics = response.authorityTopics;
        authorityNames = response.authorityTopics
            .map((e) => e.authorityName)
            .toSet()
            .toList();

        selectedAuthority = authorityNames.first;

        consultationTopics = authorityTopics.first.topics;
        consultationNames = consultationTopics.map((e) => e.topicName).toList();

        consultationTheme = consultationTopics.first.topicName;

        getAvailableDates();
      });
    } on GrpcError catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Ошибка получения данных"),
            content: Text(e.message ?? "Текст ошибки отсутствует"),
            actions: [
              TextButton(
                child: const Text("Продолжить"),
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

  Widget textField(String label, String? Function(String?)? validator,
      Function(String)? onChanged, TextInputFormatter? inputFormatter) {
    return TextFormField(
      cursorColor: Colors.black,
      onChanged: onChanged,
      validator: validator,
      inputFormatters: inputFormatter == null ? [] : [inputFormatter],
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.grey),
        fillColor: CupertinoColors.extraLightBackgroundGray,
        filled: true,
        border: OutlineInputBorder(
          borderSide: const BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  Widget authorityDropdownList() {
    return DropdownButton2(
      isExpanded: true,
      hint: const Text('Контрольно-надзорный орган'),
      items: authorityNames
          .map(
            (e) => DropdownMenuItem(
              value: e,
              onTap: () {
                return;
              },
              child: Text(
                e,
                overflow: TextOverflow.fade,
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        setState(() {
          selectedAuthority = v as String;

          consultationTopics = authorityTopics
              .where((element) => element.authorityName == selectedAuthority)
              .first
              .topics;

          consultationNames =
              consultationTopics.map((e) => e.topicName).toList();
          consultationTheme = consultationTopics.first.topicName;

          getAvailableDates();
        });
      },
      value: selectedAuthority,
      buttonStyleData: const ButtonStyleData(
        height: 80,
        width: 400,
      ),
      menuItemStyleData: const MenuItemStyleData(
        height: 100,
      ),
      dropdownStyleData: DropdownStyleData(
        width: 350,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
      ),
    );
  }

  Widget consultationDropdownList() {
    return DropdownButton2(
      isExpanded: true,
      hint: const Text('Тема консультации КНО'),
      items: consultationNames
          .map(
            (e) => DropdownMenuItem(
              onTap: () {},
              value: e,
              child: Text(
                e,
                overflow: TextOverflow.fade,
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        setState(() {
          consultationTheme = v as String;
        });
      },
      value: consultationTheme,
      buttonStyleData: const ButtonStyleData(
        height: 80,
        width: 400,
      ),
      menuItemStyleData: const MenuItemStyleData(
        height: 120,
      ),
      dropdownStyleData: DropdownStyleData(
        width: 350,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
      ),
    );
  }

  Widget datesDropdownList() {
    return DropdownButton2(
      isExpanded: true,
      hint: const Text('Даты записи'),
      items: dateNames
          .map(
            (e) => DropdownMenuItem(
              onTap: () {},
              value: e,
              child: Text(
                e,
                overflow: TextOverflow.visible,
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        setState(() {
          selectedDateName = v as String;
          getAvailableSlots();
          print(selectedDateName);
        });
      },
      value: selectedDateName,
      buttonStyleData: const ButtonStyleData(
        height: 80,
        width: 400,
      ),
      menuItemStyleData: const MenuItemStyleData(
        height: 48,
      ),
      dropdownStyleData: DropdownStyleData(
        width: 350,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
      ),
    );
  }

  Widget slotsDropdownList() {
    return DropdownButton2(
      isExpanded: true,
      hint: const Text('Временные интервалы записи'),
      items: availableSlotNames
          .map(
            (e) => DropdownMenuItem(
              onTap: () {},
              value: e,
              child: Text(
                e,
                overflow: TextOverflow.visible,
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        setState(() {
          selectedSlotName = v as String;
        });
      },
      value: selectedSlotName,
      buttonStyleData: const ButtonStyleData(
        height: 80,
        width: 400,
      ),
      menuItemStyleData: const MenuItemStyleData(
        height: 48,
      ),
      dropdownStyleData: DropdownStyleData(
        width: 350,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
      ),
    );
  }

  void cancelConsultationCreation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
              "Вы уверены, что хотите отменить создание консультации?"),
          content: const Text("В этом случае ее данные будут утеряны"),
          actions: [
            TextButton(
              child:
                  const Text("Продолжить", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Timer(
                  const Duration(milliseconds: 200),
                  () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                );
              },
            ),
            TextButton(
              child: const Text("Отмена"),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemBackground,
      body: CupertinoPageScaffold(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(
                "Запись",
                style: GoogleFonts.ptSerif(fontWeight: FontWeight.w100),
              ),
            ),
            SliverFillRemaining(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: createConsultationFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      verticalDirection: VerticalDirection.down,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          "Запишитесь на консультацию с инспектором в удобное время, а перед ее началом вам придет уведомление",
                          style: TextStyle(
                              fontWeight: FontWeight.w300, fontSize: 16),
                        ),
                        const SizedBox(height: 32),
                        authorityDropdownList(),
                        const SizedBox(height: 32),
                        consultationDropdownList(),
                        const SizedBox(height: 32),
                        datesDropdownList(),
                        const SizedBox(height: 32),
                        slotsDropdownList(),
                        const SizedBox(height: 32),
                        Container(
                          height: 48,
                          width: double.infinity,
                          child: CupertinoButton(
                            color: ColorResources.accentRed,
                            onPressed: () {
                              createConsultation();

                              // if (createConsultationFormKey.currentState!
                              //     .validate()) {
                              //
                              //
                              //   consultation.tags = ["Есть запись"];
                              //   consultations.consultations.add(consultation);
                              //   storageProvider
                              //       .saveConsultations(consultations);
                              //
                              // }
                            },
                            child: const Text(
                              "Записаться на консультацию",
                              style: TextStyle(
                                color: ColorResources.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 48,
                          width: double.infinity,
                          child: CupertinoButton(
                            color: ColorResources.accentPink,
                            onPressed: () {
                              cancelConsultationCreation();
                            },
                            child: const Text(
                              "Отменить создание записи",
                              style: TextStyle(
                                color: ColorResources.accentRed,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
