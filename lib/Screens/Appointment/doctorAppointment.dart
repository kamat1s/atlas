//TODO: fix appointment process

import 'dart:developer';

import 'package:atlas/global.dart';
import 'package:atlas/styles.dart';
import 'package:atlas/utils.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../query.dart';
import 'description.dart';

class DoctorAppointment extends StatefulWidget {
  final doctorInformation;
  const DoctorAppointment({Key? key, this.doctorInformation}) : super(key: key);

  @override
  State<DoctorAppointment> createState() => _DoctorAppointmentState();
}

class _DoctorAppointmentState extends State<DoctorAppointment> {
  Map<String, dynamic> doctorInformation = {};

  String service = "";
  String prevService = "";

  String description = "";
  String prevDescription = "";

  int year = 0;
  int month = 0;
  int day = 0;

  String displayMonth = "";
  String displayYear = "";

  var dateTimeNow = DateTime.now();

  Map<String, dynamic> serviceHour = {};
  List<DateTime> timeSlots = [];
  List<DateTime> takenSlots = [];

  var pickedDate;
  var pickedTime;

  bool isServiceEmpty = false;
  bool isScheduleInvalid = false;

  getDifference() {
    var lastDayOfTheMonth = getDaysInMonth(year, month);

    return lastDayOfTheMonth - day;
  }

  getDates() {
    List<DateTime> dates = [];

    int daysLeftThisMonth = getDifference();
    for (int i = 1; i <= daysLeftThisMonth; i++) {
      dates.add(DateTime(year, month, day + i));
    }
    for (int i = 1; i <= 30 - daysLeftThisMonth; i++) {
      dates.add(DateTime(year, month + 1, i));
    }

    return dates;
  }

  generateDateWidget() {
    List<Widget> dateWidget = [];
    List<DateTime> dates = getDates();

    var nextMonth = dateTimeNow.month + 1 > 12
        ? dateTimeNow.month - 11
        : dateTimeNow.month + 1;
    for (var date in dates) {
      if (date.month == nextMonth) {
        dateWidget.add(
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: VisibilityDetector(
              key: const Key('new-month'),
              onVisibilityChanged: (VisibilityInfo info) {
                if (!mounted) return;
                setState(() {
                  displayMonth = info.visibleBounds.width == 56 || date.day > 5
                      ? "${formatMonth(date.month).substring(0, 3)}"
                      : "${formatMonth(month).substring(0, 3)}";
                  displayYear = info.visibleBounds.width == 56 || date.day > 5
                      ? "${date.year}"
                      : "$year";
                });
              },
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    pickedDate = DateTime(date.year, date.month, date.day);
                    getServiceHours(pickedDate.weekday);
                  });
                  log(pickedDate.toString());
                },
                child: Container(
                  height: 82,
                  width: 56,
                  decoration: BoxDecoration(
                      color: checkPickedDate(pickedDate, date)
                          ? appColors['accent']
                          : appColors['coolGray'],
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "${date.day}",
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                fontWeight: checkPickedDate(pickedDate, date)
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: checkPickedDate(pickedDate, date)
                                    ? appColors['white']
                                    : appColors['black']),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          "${formatWeekday(date.weekday).substring(0, 3).toUpperCase()}",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  fontWeight: checkPickedDate(pickedDate, date)
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: checkPickedDate(pickedDate, date)
                                      ? appColors['white']
                                      : appColors['black']),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        dateWidget.add(
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  pickedDate = DateTime(date.year, date.month, date.day);
                  getServiceHours(pickedDate.weekday);
                });
                log(pickedDate.toString());
              },
              child: Container(
                height: 82,
                width: 56,
                decoration: BoxDecoration(
                    color: checkPickedDate(pickedDate, date)
                        ? appColors['accent']
                        : appColors['coolGray'],
                    borderRadius: BorderRadius.circular(15)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "${date.day}",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              fontWeight: checkPickedDate(pickedDate, date)
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: checkPickedDate(pickedDate, date)
                                  ? appColors['white']
                                  : appColors['black']),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        "${formatWeekday(date.weekday).substring(0, 3).toUpperCase()}",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: checkPickedDate(pickedDate, date)
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: checkPickedDate(pickedDate, date)
                                ? appColors['white']
                                : appColors['black']),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return dateWidget;
  }

  Map<String, dynamic> getServiceHours(var weekday) {
    bool isAvailable = false;

    serviceHour = {};

    for (var serviceHour in doctorInformation['serviceHours']) {
      if (serviceHour['day'] == formatWeekday(weekday)) {
        log(serviceHour.toString());
        this.serviceHour = serviceHour;
        isAvailable = true;
        break;
      }
    }

    if (isAvailable) {
      isScheduleInvalid = pickedTime == null;
      generateTimeSlots();
    } else {
      pickedTime = null;
      isScheduleInvalid = true;
    }
    log(name: "SCHEDULE INVALID", isScheduleInvalid.toString());

    return serviceHour;
  }

  generateTimeSlots() {
    timeSlots = [];
    /*log(
        name: "OPENING TIME",
        "${serviceHour['openingHour']}:${serviceHour['openingMinute']} ${serviceHour['openingMeridiem']}");
    log(
        name: "CLOSING TIME",
        "${serviceHour['closingHour']}:${serviceHour['closingMinute']} ${serviceHour['closingMeridiem']}");*/
    DateTime openingTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        serviceHour['openingHour'],
        serviceHour['openingMinute']);
    DateTime closingTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        serviceHour['closingHour'],
        serviceHour['closingMinute']);
    /* log(name: "OPENING TIME", openingTime.toString());
    log(name: "CLOSING TIME", closingTime.toString());*/

    int numberOfSlots = closingTime.difference(openingTime).inMinutes ~/ 30;
    /*log(name: "NUMBER OF TIME SLOTS", "$numberOfSlots");*/

    DateTime startingTime = openingTime;

    for (int i = 0; i < numberOfSlots; i++) {
      timeSlots.add(startingTime);
      startingTime = startingTime.add(const Duration(minutes: 30));
    }

    /* log(name: "TIME SLOTS", timeSlots.toString());*/
  }

  checkPickedDate(DateTime pickedDate, DateTime newDate) {
    return pickedDate.year == newDate.year &&
        pickedDate.day == newDate.day &&
        pickedDate.month == newDate.month;
  }

  showServices() {
    showDialog<void>(
      useSafeArea: true,
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        return WillPopScope(
          onWillPop: () async {
            service = prevService;
            return true;
          },
          child: StatefulBuilder(
            builder: (context, dialogSetState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                insetPadding: const EdgeInsets.all(15),
                child: SizedBox(
                  height: 285,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Services",
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 15, bottom: 45),
                            child: GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 10,
                                  mainAxisExtent: 48,
                                  crossAxisSpacing: 20,
                                ),
                                itemCount:
                                    widget.doctorInformation['services'].length,
                                itemBuilder: (BuildContext context, int index) {
                                  String service = widget
                                      .doctorInformation['services'][index];
                                  return SizedBox(
                                    height: 48,
                                    child: TextButton(
                                      onPressed: () {
                                        if (!mounted) return;
                                        dialogSetState(() {
                                          if (this.service == service) {
                                            service = "";
                                          } else {
                                            this.service = service;
                                          }
                                        });
                                      },
                                      style: TextButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        backgroundColor: this.service == service
                                            ? appColors['accent']
                                            : appColors['coolGray'],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 10, right: 10),
                                        child: Text(
                                          service,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: this.service == service
                                                ? appColors['white']
                                                : appColors['black'],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 40),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    service = prevService;
                                  });
                                },
                                child: Text(
                                  "Cancel",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: appColors['black'],
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                                setState(() {
                                  prevService = service;
                                  isServiceEmpty = service.isEmpty;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: Text(
                                  "Confirm",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: appColors['accent'],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  showAppointmentSummary() {
    showDialog<void>(
      useSafeArea: true,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            var month = formatMonth(pickedTime.month).substring(0, 3);
            var day = formatTime(pickedTime.day);
            var weekday = formatWeekday(pickedTime.weekday).substring(0, 3);
            var startHour = formatTime(convertTime(pickedTime.hour));
            var startMinute = formatTime(pickedTime.minute);
            var startMeridiem = getMeridiem(pickedTime.hour);
            var endHour = formatTime(
                convertTime(pickedTime.add(const Duration(minutes: 30)).hour));
            var endMinute =
                formatTime(pickedTime.add(const Duration(minutes: 30)).minute);
            var endMeridiem =
                getMeridiem(pickedTime.add(const Duration(minutes: 30)).hour);

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              insetPadding: const EdgeInsets.all(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 30, 30, 15),
                    child: SizedBox(
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: Icon(
                                  Icons.medical_services_outlined,
                                  color: appColors['black'],
                                ),
                              ),
                              Text(
                                service,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              )
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 23),
                            child: Row(
                              crossAxisAlignment: description.isEmpty
                                  ? CrossAxisAlignment.center
                                  : CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Icon(
                                    Icons.description_outlined,
                                    color: appColors['black'],
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    description.isEmpty
                                        ? "No description"
                                        : description,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                )
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 23),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Icon(
                                    Icons.person_outline,
                                    color: appColors['black'],
                                  ),
                                ),
                                Text(
                                  'Doctor ${doctorInformation['firstName']}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                )
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 23),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Icon(
                                    Icons.watch_later_outlined,
                                    color: appColors['black'],
                                  ),
                                ),
                                Text(
                                  '$month $day $weekday, $startHour:$startMinute $startMeridiem - $endHour:$endMinute $endMeridiem',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 131,
                    decoration: BoxDecoration(
                        color: appColors['accent'],
                        borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(30, 15, 39, 17),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 18),
                                child: Icon(
                                  Icons.assignment_outlined,
                                  size: 48,
                                  color: appColors['white'],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "Hey there! Are you satisfied with your appointment request?",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: appColors['white']),
                                ),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Container(
                                    clipBehavior: Clip.hardEdge,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                            color: appColors['white']!)),
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        "No, Go Back",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: appColors['white']),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Container(
                                    clipBehavior: Clip.hardEdge,
                                    decoration: BoxDecoration(
                                        color: appColors['white'],
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                            color: appColors['white']!)),
                                    child: TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        submitAppointment();
                                      },
                                      style: OutlinedButton.styleFrom(
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        "Yes, Submit Now",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: appColors['accent']),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  submitAppointment() async {
    Map<String, dynamic> appointmentDetails = {
      "service": service,
      "description": description,
      "date": pickedTime.toString(),
      "independentDoctorID": doctorInformation['independentDoctorID'],
      "patientID": userData['patientID'],
      "status": "pending"
    };

    log(name: "APPOINTMENT DETAILS", appointmentDetails.toString());

    await addNotification(
        uid: doctorInformation['uid'],
        title: "New Appointment Request",
        body:
            "Hey Doc! A Patient submitted an Appointment Request. Review it Now!");
    await addAppointment(appointmentDetails, "independentDoctor");
    showSuccessfulPrompt();
  }

  showSuccessfulPrompt() {
    showDialog<String>(
      useSafeArea: true,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              insetPadding: const EdgeInsets.all(15),
              child: SizedBox(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Icon(
                        Icons.celebration_outlined,
                        color: appColors['accent'],
                        size: 84,
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 30, left: 58, right: 58),
                      child: Text(
                        "Your Appointment Request is Successfully Submitted!",
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 10, left: 24, right: 24),
                      child: Text(
                        "Kindly wait for the Clinic to review your request.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: appColors['gray143']),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, top: 50, bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Container(
                                clipBehavior: Clip.hardEdge,
                                decoration: BoxDecoration(
                                    color: appColors['white'],
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                        color: appColors['accent']!)),
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, "Maps");
                                  },
                                  style: OutlinedButton.styleFrom(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    "Go back",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: appColors['accent']),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Container(
                                clipBehavior: Clip.hardEdge,
                                decoration: BoxDecoration(
                                    color: appColors['accent'],
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                        color: appColors['accent']!)),
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, "Appointments");
                                  },
                                  style: OutlinedButton.styleFrom(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    "Go to Appointments",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: appColors['white']),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((value) => Navigator.pop(context, value));
  }

  showAppointmentDuplicatePrompt(Map<String, dynamic> appointmentDetail) {
    showDialog<void>(
      useSafeArea: true,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              insetPadding: const EdgeInsets.all(15),
              child: SizedBox(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Icon(
                        Icons.event_busy_outlined,
                        color: appColors['accent'],
                        size: 84,
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 30, left: 35, right: 35),
                      child: Text(
                        "You already have an Scheduled Appointment that Day",
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 10, left: 25, right: 25),
                      child: Text(
                        "You can either set this one on another day or cancel your existing appointment that day.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: appColors['gray143']),
                      ),
                    ),
                    appointmentDetail['status'] == 'pending'
                        ? Padding(
                            padding: const EdgeInsets.only(
                                left: 20, right: 20, top: 50, bottom: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Container(
                                      height: 48,
                                      clipBehavior: Clip.hardEdge,
                                      decoration: BoxDecoration(
                                          color: appColors['white'],
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          border: Border.all(
                                              color: appColors['accent']!)),
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          "Go back",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  color: appColors['accent']),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Container(
                                      height: 48,
                                      clipBehavior: Clip.hardEdge,
                                      decoration: BoxDecoration(
                                          color: appColors['accent'],
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          border: Border.all(
                                              color: appColors['accent']!)),
                                      child: TextButton(
                                        onPressed: () async {
                                          appointmentDetail['clinicData'] =
                                              await getData('independentDoctors',
                                                  id: appointmentDetail[
                                                      'independentDoctorID']);

                                          showAppointmentComparison(
                                              appointmentDetail);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          textAlign: TextAlign.center,
                                          "View Existing Appointment",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  color: appColors['white']),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(25, 25, 25, 15),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Container(
                                height: 36,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: appColors['accent']),
                                child: Center(
                                  child: Text(
                                    "Got it",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: appColors['white']),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  showAppointmentComparison(Map<String, dynamic> appointmentDetail) {
    showDialog<String>(
      useSafeArea: true,
      context: context,
      builder: (BuildContext context) {
        final textTheme = Theme.of(context).textTheme;

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            var month = formatMonth(pickedTime.month).substring(0, 3);
            var day = formatTime(pickedTime.day);
            var year = pickedDate.year;

            //CURRENT APPOINTMENT TIME;
            var currentAppointmentDateTime =
                DateTime.parse(appointmentDetail['date']);
            var startHour =
                formatTime(convertTime(currentAppointmentDateTime.hour));
            var startMinute = formatTime(currentAppointmentDateTime.minute);
            var startMeridiem = getMeridiem(currentAppointmentDateTime.hour);
            var endHour = formatTime(convertTime(currentAppointmentDateTime
                .add(const Duration(minutes: 30))
                .hour));
            var endMinute = formatTime(currentAppointmentDateTime
                .add(const Duration(minutes: 30))
                .minute);
            var endMeridiem = getMeridiem(currentAppointmentDateTime
                .add(const Duration(minutes: 30))
                .hour);

            //New APPOINTMENT TIME;
            var newStartHour = formatTime(convertTime(pickedTime.hour));
            var newStartMinute = formatTime(pickedTime.minute);
            var newStartMeridiem = getMeridiem(pickedTime.hour);
            var newEndHour = formatTime(
                convertTime(pickedTime.add(const Duration(minutes: 30)).hour));
            var newEndMinute =
                formatTime(pickedTime.add(const Duration(minutes: 30)).minute);
            var newEndMeridiem =
                getMeridiem(pickedTime.add(const Duration(minutes: 30)).hour);

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              insetPadding: const EdgeInsets.all(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            "Current Appointment Request",
                            style: textTheme.labelSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Text(
                            "${appointmentDetail['clinicData']['clinicName']}",
                            style: textTheme.labelSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Text(
                            "${appointmentDetail['service']}",
                            style: textTheme.bodyMedium,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: FutureBuilder(
                            future: placemarkFromCoordinates(
                                appointmentDetail['clinicData']['address']
                                    ['latitude'],
                                appointmentDetail['clinicData']['address']
                                    ['longitude']),
                            builder: (BuildContext context,
                                AsyncSnapshot<dynamic> snapshot) {
                              if (snapshot.hasData) {
                                var address = snapshot.data.first;

                                return Text(
                                  "${address.street}. ${address.subLocality}, ${address.locality}, ${address.administrativeArea}",
                                  style: textTheme.bodyMedium,
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Text(
                            "Dr. ${appointmentDetail['clinicData']['firstName']}",
                            style: textTheme.bodyMedium,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Text(
                            "Schedule",
                            style: textTheme.labelSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 38),
                                child: Text(
                                  "$month. $day, $year",
                                ),
                              ),
                              Text(
                                  "$startHour:$startMinute ${startMeridiem.toUpperCase()} - $endHour:$endMinute ${endMeridiem.toUpperCase()}")
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: appColors['accent'],
                        borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  "New Appointment Request",
                                  style: textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: appColors['white']),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: Text(
                                  "${widget.doctorInformation['clinicName']}",
                                  style: textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: appColors['white']),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: Text(
                                  service,
                                  style: textTheme.bodyMedium
                                      ?.copyWith(color: appColors['white']),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: FutureBuilder(
                                  future: placemarkFromCoordinates(
                                      widget.doctorInformation['address']
                                          ['latitude'],
                                      widget.doctorInformation['address']
                                          ['longitude']),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<dynamic> snapshot) {
                                    if (snapshot.hasData) {
                                      var address = snapshot.data.first;

                                      return Text(
                                        "${address.street}. ${address.subLocality}, ${address.locality}, ${address.administrativeArea}",
                                        style: textTheme.bodyMedium?.copyWith(
                                            color: appColors['white']),
                                      );
                                    } else {
                                      return const SizedBox.shrink();
                                    }
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: Text(
                                  "Dr. ${appointmentDetail['clinicData']['firstName']}",
                                  style: textTheme.bodyMedium
                                      ?.copyWith(color: appColors['white']),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: Text(
                                  "Schedule",
                                  style: textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: appColors['white']),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(right: 38),
                                      child: Text(
                                        "$month. $day, $year",
                                        style: textTheme.bodyMedium?.copyWith(
                                            color: appColors['white']),
                                      ),
                                    ),
                                    Text(
                                      "$newStartHour:$newStartMinute ${newStartMeridiem.toUpperCase()} - $newEndHour:$newEndMinute ${newEndMeridiem.toUpperCase()}",
                                      style: textTheme.bodyMedium
                                          ?.copyWith(color: appColors['white']),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Divider(
                            height: 0,
                            color: appColors['white'],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(30, 15, 39, 17),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 18),
                                child: Icon(
                                  Icons.assignment_outlined,
                                  size: 48,
                                  color: appColors['white'],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "Hey there! Do you want to CANCEL CURRENT request and SUBMIT NEW request?",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: appColors['white']),
                                ),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, bottom: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Container(
                                    clipBehavior: Clip.hardEdge,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                            color: appColors['white']!)),
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        "No, Go Back",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: appColors['white']),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Container(
                                    clipBehavior: Clip.hardEdge,
                                    decoration: BoxDecoration(
                                        color: appColors['white'],
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                            color: appColors['white']!)),
                                    child: TextButton(
                                      onPressed: () async {

                                        await addNotification(
                                            uid: doctorInformation['uid'],
                                            title:
                                                "Appointment Request Cancelled",
                                            body:
                                                "Hey Doc! A Patient cancelled an Appointment Request.");
                                        await updateData(
                                            'independentDoctorAppointments',
                                            id: appointmentDetail[
                                                'independentDoctorID'],
                                            {'status': 'cancelled'});
                                        if (!mounted) return;
                                        Navigator.pop(context, "submit");

                                        submitAppointment();
                                      },
                                      style: OutlinedButton.styleFrom(
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        "Yes, Submit Now",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: appColors['accent']),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    ).then((value) {
      if (value == "submit") {
        Navigator.pop(context);
      }
    });
  }

  checkAvailableSlots() async {
    takenSlots = await getTakenSlots(
        id: doctorInformation['independentDoctorID'], accountType: 'independentDoctor');
    print(takenSlots);
  }

  @override
  void initState() {
    year = dateTimeNow.year;
    month = dateTimeNow.month;
    day = dateTimeNow.day;

    doctorInformation = widget.doctorInformation;

    checkAvailableSlots();

    displayMonth = formatMonth(month).substring(0, 3);
    displayYear = "$year";

    pickedDate = dateTimeNow.add(const Duration(days: 1));
    log(pickedDate.toString());

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColors['accent'],
      body: SafeArea(
        child: Container(
            height: double.maxFinite,
            width: double.maxFinite,
            color: appColors['primary'],
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 59, 10, 10),
                  child: SizedBox(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.medical_services_outlined,
                                  color: appColors['black']),
                              horizontalTitleGap: 3,
                              dense: true,
                              title: Text(
                                service.isEmpty
                                    ? "Add Service to Consult"
                                    : service,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: service.isEmpty
                                          ? appColors['gray145']
                                          : appColors['black'],
                                    ),
                              ),
                              onTap: () => showServices(),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 44),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(
                                      height: 0,
                                      color: isServiceEmpty
                                          ? appColors['accent']
                                          : appColors['gray231'],
                                      thickness: 1),
                                  isServiceEmpty
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: Text(
                                            "Please choose a service that you want to consult",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                    color: appColors['accent']),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ],
                              ),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.description_outlined,
                                  color: appColors['black']),
                              horizontalTitleGap: 3,
                              dense: true,
                              title: Text(
                                description.isEmpty
                                    ? "Description"
                                    : description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: description.isEmpty
                                          ? appColors['gray145']
                                          : appColors['black'],
                                    ),
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      Description(description: description),
                                ),
                              ).then((value) {
                                setState(() {
                                  description = value ?? "";
                                });
                              }),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 44),
                              child: Divider(
                                color: appColors['gray143'],
                                height: 0,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 20),
                                    child: Icon(
                                      Icons.watch_later_outlined,
                                      color: appColors['black'],
                                    ),
                                  ),
                                  Text(
                                    "Preferred Schedule",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: appColors['black'],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            service.isNotEmpty
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      isScheduleInvalid && service.isNotEmpty
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 44, top: 5),
                                              child: Text(
                                                "Please choose your preferred date and time.",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                        color: appColors[
                                                            'accent']),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 30),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Pick a date",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: appColors['black'],
                                                  ),
                                            ),
                                            Text(
                                              "$displayMonth $displayYear",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: appColors['black'],
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: SizedBox(
                                          height: 82,
                                          child: ListView(
                                            scrollDirection: Axis.horizontal,
                                            children: generateDateWidget(),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 30),
                                        child: Text(
                                          "Pick a time",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: appColors['black'],
                                              ),
                                        ),
                                      ),
                                      getServiceHours(pickedDate.weekday)
                                              .isNotEmpty
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 14),
                                              child: Column(
                                                children: [
                                                  SizedBox(
                                                    height: 160,
                                                    child: GridView.builder(
                                                        shrinkWrap: true,
                                                        gridDelegate:
                                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount: 3,
                                                          mainAxisSpacing: 5,
                                                          mainAxisExtent: 36,
                                                          crossAxisSpacing: 5,
                                                        ),
                                                        itemCount:
                                                            timeSlots.length,
                                                        itemBuilder:
                                                            (BuildContext
                                                                    context,
                                                                int index) {
                                                          int startHour =
                                                              convertTime(
                                                                  timeSlots[
                                                                          index]
                                                                      .hour);
                                                          int startMinute =
                                                              timeSlots[index]
                                                                  .minute;

                                                          return GestureDetector(
                                                            onTap: () {
                                                              setState(() {
                                                                if (!takenSlots
                                                                    .contains(
                                                                        timeSlots[
                                                                            index])) {
                                                                  pickedTime =
                                                                      timeSlots[
                                                                          index];
                                                                  isScheduleInvalid =
                                                                      pickedTime ==
                                                                          null;
                                                                }
                                                              });
                                                            },
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                  color: pickedTime == timeSlots[index]
                                                                      ? appColors['accent']
                                                                      : takenSlots.contains(timeSlots[index])
                                                                          ? appColors['gray192']
                                                                          : appColors['coolGray'],
                                                                  borderRadius: BorderRadius.circular(15)),
                                                              child: Center(
                                                                child: Text(
                                                                  "${formatTime(startHour)}:${formatTime(startMinute)} ${timeSlots[index].hour < 12 ? "am" : "pm"}",
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .labelMedium
                                                                      ?.copyWith(
                                                                          color: pickedTime == timeSlots[index]
                                                                              ? appColors['white']
                                                                              : takenSlots.contains(timeSlots[index])
                                                                                  ? appColors['gray143']
                                                                                  : appColors['black'],
                                                                          fontWeight: pickedTime == timeSlots[index] ? FontWeight.w600 : FontWeight.w500),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 24),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        RichText(
                                                          text: TextSpan(
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .labelSmall
                                                                ?.copyWith(
                                                                  fontSize: 10,
                                                                  color: appColors[
                                                                      'gray143'],
                                                                ),
                                                            children: const <
                                                                TextSpan>[
                                                              TextSpan(
                                                                  text:
                                                                      'Preferred Schedule may or may '),
                                                              TextSpan(
                                                                  text: 'NOT',
                                                                  style: TextStyle(
                                                                      decoration:
                                                                          TextDecoration
                                                                              .underline)),
                                                              TextSpan(
                                                                  text:
                                                                      ' be\naccepted. '),
                                                            ],
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        Icon(
                                                          Icons.priority_high,
                                                          color: appColors[
                                                              'gray143'],
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 48),
                                              child: Center(
                                                child: Column(
                                                  children: [
                                                    Icon(
                                                      Icons.event_busy,
                                                      color:
                                                          appColors['gray143'],
                                                      size: 60,
                                                    ),
                                                    Text(
                                                      "No available Schedule \non this day",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: appColors[
                                                                'gray143'],
                                                          ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                    ],
                                  )
                                : Padding(
                                    padding: const EdgeInsets.only(top: 48),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.event_busy,
                                            color: appColors['gray143'],
                                            size: 60,
                                          ),
                                          Text(
                                            "Select a Service to see\navailable schedules",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: appColors['gray143'],
                                                ),
                                            textAlign: TextAlign.center,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: appColors['white'],
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 0.5),
                        blurRadius: 4,
                        spreadRadius: 0,
                        color: appColors['black.25']!,
                      ),
                    ],
                  ),
                  height: 54,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 15, 15, 15),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 15),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context, "Clinic Info");
                            },
                            child: Icon(
                              Icons.close,
                              color: appColors['black'],
                            ),
                          ),
                        ),
                        Text(
                          "New Consultation Appointment",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            setState(() {
                              isServiceEmpty = service.isEmpty;
                              isScheduleInvalid = pickedTime == null;
                            });
                            if (!(isServiceEmpty || isScheduleInvalid)) {
                              var duplicate = await checkDuplicateAppointment(
                                  userData["patientID"], pickedTime, "independentDoctor");

                              log(name: "DUPLICATE", duplicate.toString());
                              if (duplicate.isNotEmpty) {
                                showAppointmentDuplicatePrompt(duplicate);
                              } else {
                                showAppointmentSummary();
                              }
                            }
                          },
                          child: Icon(
                            Icons.check,
                            color: appColors['black'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
