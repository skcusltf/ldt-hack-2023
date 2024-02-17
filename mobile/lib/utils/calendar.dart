import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:lodt_hack/models/consultation/Consultation.dart';
import 'package:lodt_hack/screens/consultation.dart';

import '../styles/ColorResources.dart';
import 'package:table_calendar/table_calendar.dart';

final calendarConfig = CalendarDatePicker2Config(
  calendarType: CalendarDatePicker2Type.range,
  selectedDayHighlightColor: ColorResources.accentRed,
  weekdayLabels: ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'],
  weekdayLabelTextStyle: const TextStyle(
    color: Colors.black87,
    fontWeight: FontWeight.bold,
  ),
  firstDayOfWeek: 1,
  controlsHeight: 50,
  controlsTextStyle: const TextStyle(
    color: Colors.black,
    fontSize: 15,
    fontWeight: FontWeight.bold,
  ),
  dayTextStyle: const TextStyle(
    color: ColorResources.accentRed,
    fontWeight: FontWeight.normal,
  ),
  disabledDayTextStyle: const TextStyle(
    color: Colors.grey,
  ),
  selectableDayPredicate: (day) => true,
);

class EventCalendar extends StatefulWidget {
  const EventCalendar({
    super.key,
    required this.consultations,
    required this.consultationByDate,
    required this.rangeSelectionEnabled,
    required this.onSelect,
    required this.rangeStart,
    required this.rangeEnd,
  });

  final List<ConsultationModel> consultations;
  final ConsultationModel? Function(DateTime) consultationByDate;
  final bool rangeSelectionEnabled;
  final Function(DateTime?, DateTime?) onSelect;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  @override
  State<EventCalendar> createState() => EventCalendarState();
}

class EventCalendarState extends State<EventCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _rangeStart = widget.rangeStart;
    _rangeEnd = widget.rangeEnd;
  }

  void clear() {
    setState(() {
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  ConsultationModel? getConsultationByDay(DateTime day) {
    if (widget.consultations
        .where((element) => isSameDay(element.date(), day))
        .isEmpty) {
      return null;
    }

    return widget.consultations
        .firstWhere((element) => isSameDay(element.date(), day));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 400,
      child: TableCalendar(
        firstDay: DateTime.utc(2022, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: _focusedDay,
        onFormatChanged: (format) {},
        locale: 'ru_RU',
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
        ),
        calendarStyle: CalendarStyle(
          markerDecoration: const BoxDecoration(
            color: ColorResources.accentRed,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: ColorResources.accentRed.withAlpha(96),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: ColorResources.accentRed,
            shape: BoxShape.circle,
          ),
          rangeStartDecoration: const BoxDecoration(
            color: ColorResources.accentRed,
            shape: BoxShape.circle,
          ),
          rangeEndDecoration: const BoxDecoration(
            color: ColorResources.accentRed,
            shape: BoxShape.circle,
          ),
          rangeHighlightColor: ColorResources.accentRed.withAlpha(96),
        ),
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        eventLoader: (day) {
          if (widget.consultations
              .where((element) => isSameDay(element.date(), day))
              .isNotEmpty) {
            return [""];
          }

          return [];
        },
        rangeStartDay: _rangeStart,
        rangeEndDay: _rangeEnd,
        onRangeSelected: (start, end, focusedDay) {
          setState(() {
            _selectedDay = null;
            _focusedDay = focusedDay;
            _rangeStart = start;
            _rangeEnd = end;

            widget.onSelect(_rangeStart, _rangeEnd);
          });
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            if (widget.consultationByDate(selectedDay) != null) {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => Consultation(
                    consultationModel: widget.consultationByDate(selectedDay)!,
                  ),
                ),
              );
            }
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        rangeSelectionMode: widget.rangeSelectionEnabled
            ? RangeSelectionMode.toggledOn
            : RangeSelectionMode.toggledOff,
      ),
    );
  }
}
