import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lodt_hack/screens/zoom.dart';
import 'package:lodt_hack/utils/calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:table_calendar/table_calendar.dart';

import '../clients/ApiClient.dart';
import 'package:grpc/grpc.dart';
import '../generated/google/protobuf/empty.pb.dart';
import '../models/User.dart';
import '../models/consultation/Consultation.dart';
import '../models/consultation/ConsultationHolder.dart';
import '../providers/LocalStorageProvider.dart';
import '../styles/ColorResources.dart';
import '../utils/parser.dart';
import 'consultation.dart';
import 'info.dart';
import 'package:intl/intl.dart';

class Dashboard extends StatefulWidget {
  const Dashboard(
      {super.key, required this.onSearch, required this.onOpenZoom});

  final Function onSearch;
  final Function onOpenZoom;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<DateTime?> _singleDatePickerValueWithDefaultValue = [
    DateTime.now(),
  ];
  ConsultationHolder consultations = ConsultationHolder([]);
  User user = User();
  String? token;

  Future<void> fetchConsultations() async {
    try {
      final response = await apiClient.listConsultationAppointments(
        Empty(),
        options: CallOptions(
          metadata: {'Authorization': 'Bearer ${token!}'},
        ),
      );

      setState(() {
        consultations.consultations = response.appointmentInfo
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
                tags: e.canceled
                    ? ["Отменена"]
                    : e.toTime.toDateTime().isBefore(DateTime.now())
                        ? ["Есть запись"]
                        : [],
              ),
            ).where((element) => element.tags == null || element.tags!.isEmpty)
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
  }

  @override
  void initState() {
    super.initState();
    fetchData();
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
          fetchData(),
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
                      "${formatDate(consultation.day!)} в ${consultation.time}",
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

  int abs(int v) {
    if (v < 0) {
      return -v;
    }

    return v;
  }

  List<ConsultationModel> sorted(List<ConsultationModel> c) {
    c.sort((a, b) => abs(
            dateFromString(a.day!).toDateTime().day - DateTime.now().day)
        .compareTo(
            abs(dateFromString(b.day!).toDateTime().day - DateTime.now().day)));
    return c.toList();
  }

  Widget dashboardCard(
    String title,
    String description,
    String subtitle,
    String externalLink,
  ) {
    return Material(
      color: CupertinoColors.systemGrey6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: () => Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => Info(
              title: title,
              description: description,
              externalLink: externalLink,
              subtitle: subtitle,
              buttonLabel: "Перейти на сайт",
              customBody: null,
            ),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 320),
                      child: Text(
                        subtitle,
                        style: GoogleFonts.inter(fontSize: 16),
                        softWrap: true,
                        maxLines: 5,
                      ),
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

  ConsultationModel? getConsultationByDay(DateTime day) {
    if (consultations.consultations
        .where((element) => isSameDay(element.date(), day))
        .isEmpty) {
      return null;
    }

    return consultations.consultations
        .firstWhere((element) => isSameDay(element.date(), day));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(
              "Главная",
              style: GoogleFonts.ptSerif(fontWeight: FontWeight.w100),
            ),
            trailing: Material(
              child: IconButton(
                onPressed: () {
                  widget.onSearch();
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
              padding: const EdgeInsets.only(left: 16.0, right: 16, bottom: 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  verticalDirection: VerticalDirection.down,
                  children: [
                    SizedBox(height: 32),
                    ExpandablePanel(
                      header: Text(
                        "Календарь",
                        style: GoogleFonts.ptSerif(fontSize: 24),
                      ),
                      collapsed: Text(
                        "Расписание консультаций",
                        style: GoogleFonts.ptSerif(fontSize: 16),
                      ),
                      expanded: EventCalendar(
                        consultations: consultations.consultations,
                        consultationByDate: getConsultationByDay,
                        rangeSelectionEnabled: false,
                        onSelect: (from, to) {},
                        rangeStart: null,
                        rangeEnd: null,
                      ),
                      theme: const ExpandableThemeData(
                          tapHeaderToExpand: true, hasIcon: true),
                    ),
                    SizedBox(height: 48),
                    ExpandablePanel(
                      header: Text(
                        "Ближайшие консультации",
                        style: GoogleFonts.ptSerif(fontSize: 24),
                      ),
                      collapsed: Text(
                        "Управляйте встречами прямо с главного экрана",
                        style: GoogleFonts.ptSerif(fontSize: 16),
                      ),
                      expanded: Column(
                        children: [
                          SizedBox(height: 16),
                          if (consultations.consultations.isEmpty)
                            Center(
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
                          ...sorted(consultations.consultations).take(3).map(
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
                          SizedBox(height: 8),
                          SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: CupertinoButton(
                              color: CupertinoColors.systemGrey5,
                              onPressed: () {
                                widget.onOpenZoom();
                              },
                              child: const Text(
                                "Все консультации",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                      theme: const ExpandableThemeData(
                          tapHeaderToExpand: true, hasIcon: true),
                    ),
                    SizedBox(height: 48),
                    ExpandablePanel(
                      header: Text(
                        "Нормативные акты",
                        style: GoogleFonts.ptSerif(fontSize: 24),
                      ),
                      collapsed: Text(
                        "Подобранные на основании вашей активности",
                        style: GoogleFonts.ptSerif(fontSize: 16),
                      ),
                      expanded: Column(
                        children: [
                          SizedBox(height: 8),
                          dashboardCard(
                              "Нормативный акт",
                              """
                                В целях реализации Федерального закона от 31 июля 2020 г. N 248-ФЗ "О государственном контроле (надзоре) и муниципальном контроле в Российской Федерации" Правительство Москвы
постановляет:
1. Утвердить Положение о региональном государственном надзоре в области технического состояния и
эксплуатации самоходных машин и других видов техники, аттракционов в городе Москве (приложение).
(Пункт в редакции, введенной в действие с 1 января 2023 года постановлением Правительства Москвы от
20 декабря 2022 года N 2911-ПП. - См. предыдущую редакцию)
2. Признать утратившим силу постановление Правительства Москвы от 2 марта 2021 г. N 241-ПП "Об осуществлении регионального государственного надзора в области технического состояния и эксплуатации самоходных машин и других видов техники, аттракционов в городе Москве".
3. Контроль за выполнением настоящего постановления возложить на министра Правительства Москвы, начальника Главного контрольного управления города Москвы Данчикова Е.А.
                              """,
                              'Об утверждении Положения о региональном государственном контроле (надзоре) в области технического состояния и эксплуатации самоходных машин и других видов техники в городе Москве',
                              'https://knd.mos.ru/api/files/60bdbd64-559a-4cdf-94e0-458f017b4635?disposition=inline'),
                          SizedBox(height: 8),
                          dashboardCard(
                              "Нормативный акт",
                              """
В соответствии с частью 2.4 статьи 19 Федерального закона от 30 декабря 2004 г. N 214-ФЗ "Об участии в долевом строительстве многоквартирных домов и иных объектов недвижимости и о внесении изменений в некоторые законодательные акты Российской Федерации" (Собрание законодательства Российской Федерации, 2005, N 1, ст. 40; 2016, N 27, ст. 4237) и подпунктом 5.2.101(15) Положения о Министерстве строительства и жилищно-коммунального хозяйства Российской Федерации, утвержденного постановлением Правительства Российской Федерации от 18 ноября 2013 г. N 1038 (Собрание законодательства Российской Федерации, 2013, N 47, ст. 6117; 2017, N 1, ст. 185), приказываю:
1. Утвердить форму проектной декларации согласно приложению к настоящему приказу.
2. Признать утратившими силу приказы Министерства строительства и жилищно-коммунального хозяйства Российской Федерации:
от 20 декабря 2016 г. N 996/пр "Об утверждении формы проектной декларации" (зарегистрирован Министерством юстиции Российской Федерации 30 декабря 2016 г., регистрационный N 45091);
от 21 декабря 2017 г. N 1694/пр "О внесении изменений в форму проектной декларации, утвержденную приказом Министерства строительства и жилищно-коммунального хозяйства Российской Федерации от 20 декабря 2016 г. N 996/пр" (зарегистрирован Министерством юстиции Российской Федерации 19 января 2018 г., регистрационный N 49692);
от 3 мая 2018 г. N 259/пр "О внесении изменений в форму проектной декларации, утвержденную приказом Министерства строительства и жилищно-коммунального хозяйства Российской Федерации от 20 декабря 2016 г. N 996/пр" (зарегистрирован Министерством юстиции Российской Федерации 30 мая 2018 г., регистрационный N 51231);
от 31 августа 2018 г. N 552/пр "О внесении изменений в форму проектной декларации, утвержденную приказом Министерства строительства и жилищно-коммунального хозяйства Российской Федерации от 20 декабря 2016 г. N 996/пр" (зарегистрирован Министерством юстиции Российской Федерации 20 сентября 2018 г., регистрационный N 52197);
от 8 августа 2019 г. N 453/пр "О внесении изменений в форму проектной декларации, утвержденную приказом Министерства строительства и жилищно-коммунального хозяйства Российской Федерации от 20 декабря 2016 г. N 996/пр" (зарегистрирован Министерством юстиции
  
 Российской Федерации 4 сентября 2019 г., регистрационный N 55810);
от 15 октября 2020 г. N 631/пр "О внесении изменения в приказ Министерства строительства и жилищно-коммунального хозяйства Российской Федерации от 20 декабря 2016 г. N 996/пр "Об утверждении формы проектной декларации" (зарегистрирован Министерством юстиции Российской Федерации 1 декабря 2020 г., регистрационный N 61181);
от 22 марта 2021 г. N 167/пр "О внесении изменений в форму проектной декларации, утвержденную приказом Министерства строительства и жилищно-коммунального хозяйства Российской Федерации от 20 декабря 2016 г. N 996/пр" (зарегистрирован Министерством юстиции Российской Федерации 17 июня 2021 г., регистрационный N 63905).
""",
                              'ОБ УТВЕРЖДЕНИИ ФОРМЫ ПРОЕКТНОЙ ДЕКЛАРАЦИИ.',
                              'https://knd.mos.ru/api/files/b3fb7efb-337d-4abb-a51a-1c0403c794cc?disposition=inline'),
                          SizedBox(height: 8),
                          dashboardCard(
                              "Нормативный акт",
                              """
В целях реализации положений Федерального закона от 31.07.2020 N 248-ФЗ "О государственном контроле (надзоре) и муниципальном контроле в Российской Федерации" и постановления Правительства Российской Федерации от 31.12.2020 N 2428 "О порядке формирования плана проведения плановых контрольных (надзорных) мероприятий на очередной календарный год, его согласования с органами прокуратуры, включения в него и исключения из него контрольных (надзорных) мероприятий в течение года", руководствуясь пунктом 1 статьи 17 Федерального закона от 17.01.1992 N 2202-1 "О прокуратуре Российской Федерации", приказываю:
1. Утвердить и ввести в действие с 01.07.2021 прилагаемые:
порядок направления прокурорами требований о проведении контрольных (надзорных) мероприятий;
порядок рассмотрения органами прокуратуры Российской Федерации проектов ежегодных планов контрольных (надзорных) мероприятий и определения органа прокуратуры для их согласования;
порядок согласования контрольным (надзорным) органом с прокурором проведения внепланового контрольного (надзорного) мероприятия и типовые формы заявления о согласовании с прокурором проведения внепланового контрольного (надзорного) мероприятия и решения прокурора о результатах его рассмотрения.
2. Заместителю Генерального прокурора Российской Федерации - Главному военному прокурору определить порядок рассмотрения военными прокурорами проектов ежегодных планов контрольных (надзорных) мероприятий и определения органа прокуратуры для согласования указанных планов в соответствии с установленной компетенцией и закрепленными предметами ведения, а также порядок направления требований о проведении контрольных (надзорных) мероприятий в органах военной прокуратуры.
3. Начальникам Главного управления по надзору за исполнением федерального законодательства, управления по надзору за исполнением законов на транспорте и в таможенной сфере, главного управления и управлений Генеральной прокуратуры Российской Федерации по федеральным округам, Главной военной прокуратуре, прокурорам субъектов Российской Федерации, приравненным к ним военным и иным специализированным прокурорам, прокурору комплекса "Байконур", прокурорам городов, районов, другим территориальным и приравненным к ним специализированным прокурорам обеспечить надлежащее рассмотрение проектов ежегодных планов контрольных (надзорных) мероприятий и согласование внеплановых контрольных (надзорных) мероприятий с использованием информационной системы государственного контроля (надзора), муниципального контроля "Единый реестр контрольных (надзорных) мероприятий" (ЕРКНМ).
4. Начальнику Главного управления правовой статистики и информационных технологий обеспечить доступ перечисленных в пункте 3 настоящего приказа подразделений Генеральной прокуратуры Российской Федерации и органов прокуратуры к ЕРКНМ и бесперебойное функционирование данной информационной системы с 01.07.2021.
5. Начальникам главного управления и управлений Генеральной прокуратуры Российской Федерации по федеральным округам, прокурорам субъектов Российской Федерации, приравненным к ним военным и иным специализированным прокурорам, прокурору комплекса "Байконур"
""",
                              'О РЕАЛИЗАЦИИ ФЕДЕРАЛЬНОГО ЗАКОНА ОТ 31.07.2020 N 248-ФЗ "О ГОСУДАРСТВЕННОМ КОНТРОЛЕ (НАДЗОРЕ) И МУНИЦИПАЛЬНОМ КОНТРОЛЕ В РОССИЙСКОЙ ФЕДЕРАЦИИ".',
                              'https://knd.mos.ru/api/files/f23783c6-fee2-481d-8a67-c911e31cf700?disposition=inline'),
                          SizedBox(height: 8),
                          SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: CupertinoButton(
                              color: CupertinoColors.systemGrey5,
                              onPressed: () {
                                launchUrl(Uri.parse(
                                    'https://knd.mos.ru/requirements/public#anchor_20a69a9e-3d06-41ec-956b-0f9f710ecddf'));
                              },
                              child: const Text(
                                "Все нормативные акты",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                      theme: const ExpandableThemeData(
                          tapHeaderToExpand: true, hasIcon: true),
                    ),
                    SizedBox(height: 48),
                    ExpandablePanel(
                      header: Text(
                        "Органы контроля",
                        style: GoogleFonts.ptSerif(fontSize: 24),
                      ),
                      collapsed: Text(
                        "Наиболее релевантные для вас органы контроля",
                        style: GoogleFonts.ptSerif(fontSize: 16),
                      ),
                      expanded: Column(
                        children: [
                          SizedBox(height: 8),
                          dashboardCard(
                            "Орган контроля",
                            'Главное архивное управление города Москвы (Главархив) реализует государственную политику в сфере архивного дела, а также охраны и использования историко-документального наследия.',
                            'ГЛАВНОЕ АРХИВНОЕ УПРАВЛЕНИЕ ГОРОДА МОСКВЫ',
                            'https://knd.mos.ru/kno/details/bb1327a6-0a4f-40fa-a058-2a2f7c29980c?esc=%2Fkno',
                          ),
                          SizedBox(height: 8),
                          dashboardCard(
                            "Орган контроля",
                            'Государственная инспекция по контролю за использованием объектов недвижимости города Москвы (Госинспекция по недвижимости) осуществляет региональный государственный контроль за использованием объектов нежилого фонда на территории города Москвы и за ее пределами, находящихся в собственности города Москвы, в том числе являющихся объектами культурного наследия, мероприятия по определению вида фактического использования зданий (строений, сооружений) и нежилых помещений для целей налогообложения, контроль за соблюдением требований к размещению сезонных (летних) кафе при стационарных предприятиях общественного питания, муниципальный земельный контроль за использованием земель на территории города Москвы, выполняет полномочия собственника в части осуществления мероприятий по контролю за использованием земель, находящихся в собственности города Москвы и государственная собственность на которые не разграничена, и объектов нежилого фонда, а также организации их охраны в целях предотвращения и пресечения самовольного занятия и незаконного использования.',
                            'ГОСУДАРСТВЕННАЯ ИНСПЕКЦИЯ ПО КОНТРОЛЮ ЗА ИСПОЛЬЗОВАНИЕМ ОБЪЕКТОВ НЕДВИЖИМОСТИ ГОРОДА МОСКВЫ',
                            'https://knd.mos.ru/kno/details/b3310d09-5c67-4eaf-8eeb-4c011ad60f98?esc=%2Fkno',
                          ),
                          SizedBox(height: 8),
                          dashboardCard(
                            "Орган контроля",
                            'Департамент здравоохранения города Москвы реализует государственную политику в сфере здравоохранения и создаёт необходимые условия для оказания медицинской помощи. Также занимается программами обеспечения лекарственными препаратами, предоставляет услуги по лицензированию в сфере здравоохранения.',
                            'ДЕПАРТАМЕНТ ЗДРАВООХРАНЕНИЯ ГОРОДА МОСКВЫ',
                            'https://knd.mos.ru/requirements/public/8ff91444-9137-47d4-a463-92f400a33da9',
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: CupertinoButton(
                              color: CupertinoColors.systemGrey5,
                              onPressed: () {
                                launchUrl(Uri.parse('https://knd.mos.ru/kno'));
                              },
                              child: const Text(
                                "Все органы контроля",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                      theme: const ExpandableThemeData(
                          tapHeaderToExpand: true, hasIcon: true),
                    ),
                    SizedBox(height: 48),
                    ExpandablePanel(
                      header: Text(
                        "Обязательные требования",
                        style: GoogleFonts.ptSerif(fontSize: 24),
                      ),
                      collapsed: Text(
                        "Исходя из вашей истории запросов",
                        style: GoogleFonts.ptSerif(fontSize: 16),
                      ),
                      expanded: Column(
                        children: [
                          SizedBox(height: 8),
                          dashboardCard(
                              "Обязательное требование",
                              'п. 1 ст. 20 Федерального закона от 22.11.1995 № 171-ФЗ "О государственном регулировании производства и оборота этилового спирта, алкогольной и спиртосодержащей продукции и об ограничении потребления (распития) алкогольной продукции": "Действие лицензии на производство и оборот этилового спирта, алкогольной и спиртосодержащей продукции приостанавливается решением лицензирующего органа на основании материалов, представленных органами, осуществляющими контроль и надзор за соблюдением настоящего Федерального закона, а также по инициативе самого лицензирующего органа в пределах его компетенции в следующих случаях: выявление нарушения, являющегося основанием для аннулирования лицензии".',
                              'Розничная продажа алкогольной продукции без маркировки, либо с маркировкой поддельными марками запрещена.',
                              'https://knd.mos.ru/requirements/public/8ff91444-9137-47d4-a463-92f400a33da9'),
                          SizedBox(height: 8),
                          dashboardCard(
                            "Обязательное требование",
                            'ч. 1 ст. 8.20 Закона г. Москвы от 21.11.2007 № 45 "Кодекс города Москвы об административных правонарушениях": "Нарушение правил содержания и эксплуатации автомобильных дорог (объектов улично-дорожной сети) и технических средств их обустройства - влечет предупреждение или наложение административного штрафа на граждан в размере от одной тысячи пятисот до двух тысяч рублей; на должностных лиц - от пяти тысяч до десяти тысяч рублей; на юридических лиц - от тридцати тысяч до пятидесяти тысяч рублей".',
                            'Соблюдение требований к содержанию объектов дорожного хозяйства в зимний период в соответствии с Постановлением Правительства Москвы №762',
                            'https://knd.mos.ru/requirements/public/d7841855-3052-479b-801f-0e8e812fb901',
                          ),
                          SizedBox(height: 8),
                          dashboardCard(
                            "Обязательное требование",
                            'ч. 1 ст. 8.18 Закона г. Москвы от 21.11.2007 № 45 "Кодекс города Москвы об административных правонарушениях": "Нарушение установленных Правительством Москвы правил производства земляных работ и работ по организации площадок для проведения отдельных работ в сфере благоустройства, в том числе отсутствие утвержденной проектной документации или необходимых согласований при проведении указанных работ, несвоевременное восстановление благоустройства территории после их завершения, непринятие мер по ликвидации провала асфальта (грунта), связанного с производством разрытий, а также несоблюдение установленных требований к обустройству и содержанию строительных площадок - влечет предупреждение или наложение административного штрафа на граждан в размере от трех тысяч до пяти тысяч рублей; на должностных лиц - от двадцати тысяч до тридцати пяти тысяч рублей; на юридических лиц - от трехсот тысяч до пятисот тысяч рублей".',
                            'Требование к аварийному освещению и освещению опасных мест.',
                            'https://knd.mos.ru/requirements/public/20a69a9e-3d06-41ec-956b-0f9f710ecddf',
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: CupertinoButton(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              color: CupertinoColors.systemGrey5,
                              onPressed: () {
                                launchUrl(Uri.parse(
                                    'https://knd.mos.ru/requirements/public#anchor_20a69a9e-3d06-41ec-956b-0f9f710ecddf'));
                              },
                              child: const Text(
                                "Все обязательные требования",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                      theme: const ExpandableThemeData(
                          tapHeaderToExpand: true, hasIcon: true),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
