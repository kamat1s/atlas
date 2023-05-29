import 'dart:developer';

import 'package:flutter/material.dart ';
import 'package:geocoding/geocoding.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../query.dart';
import '../../styles.dart';
import '../../utils.dart';

class Reschedule extends StatefulWidget {
  final appointmentDetails;
  final appointmentType;
  const Reschedule({Key? key, required this.appointmentDetails, required this.appointmentType})
      : super(key: key);

  @override
  State<Reschedule> createState() => _RescheduleState();
}

class _RescheduleState extends State<Reschedule> {
  String appointmentType = "";
  String accountType = "";
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

  var doctor;
  var reason;

  List<String> reasons = [
    "Unavailable this day/time",
    "Financial problem",
    "Emergency",
    "Change of Mind"
  ];

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

  generateDateWidget(setState) {
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

    for (var serviceHour in doctor['serviceHours']) {
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

  generateTimeSlots() async {
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

  getDoctorDetails() async {
    if(accountType == 'clinic')
      {
        doctor = await getData('doctors', id: widget.appointmentDetails['doctorID']);
      }
    else{
      doctor = await getData('independentDoctors', id: widget.appointmentDetails['independentDoctorID']);
    }
  }

  checkAvailableSlots() async {
    takenSlots = await getTakenSlots(id: widget.appointmentDetails['${accountType}ID'], accountType: accountType);
  }

  @override
  void initState() {
    appointmentType = widget.appointmentType;
    accountType = appointmentType ==
        "clinicAppointment"
        ? "clinic"
        : "independentDoctor";
    reason = reasons.first;

    year = dateTimeNow.year;
    month = dateTimeNow.month;
    day = dateTimeNow.day;

    displayMonth = formatMonth(month).substring(0, 3);
    displayYear = "$year";

    checkAvailableSlots();

    pickedDate = dateTimeNow.add(const Duration(days: 1));
    log(pickedDate.toString());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final deviceWidth = MediaQuery.of(context).size.width;
    final appointmentDetails = widget.appointmentDetails;
    DateTime date = DateTime.parse(appointmentDetails['date']);
    var month = formatMonth(date.month).substring(0, 3);
    var day = formatTime(date.day);
    var year = date.year;

    var startHour = formatTime(convertTime(date.hour));
    var startMinute = formatTime(date.minute);
    var startMeridiem = getMeridiem(convertTime(date.hour));
    var endHour =
        formatTime(convertTime(date.add(const Duration(minutes: 30)).hour));
    var endMinute = formatTime(date.add(const Duration(minutes: 30)).minute);
    var endMeridiem =
        getMeridiem(convertTime(date.add(const Duration(minutes: 30)).hour));

    showRescheduleSubmittedPrompt(){
      showDialog<void>(
        useSafeArea: true,
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: SizedBox(
              width: 330,
              height: 330,
              child: Padding(
                padding: const EdgeInsets.only(left: 25, right: 25, bottom: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.mark_email_read_outlined,
                      size: 84,
                      color: appColors['accent'],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Text(
                        "Your Reschedule Request is Successfully Submitted!",
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                          "Kindly wait for the ${accountType ==
                              "clinic"
                              ? "clinic"
                              : "doctor"} to review your request, be posted for updates",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: appColors['gray143']),
                          textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 36),
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
                    )
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    showRescheduleSummaryDialog() {
      var appointmentDetails = widget.appointmentDetails;

      //Preferred Schedule
      DateTime preferredDate = DateTime.parse(appointmentDetails['date']);
      var preferredYear = preferredDate.year;
      var preferredMonth = formatMonth(preferredDate.month).substring(0, 3);
      var preferredDay = formatTime(preferredDate.day);
      var preferredStartHour = formatTime(convertTime(preferredDate.hour));
      var preferredStartMinute = formatTime(preferredDate.minute);
      var preferredStartMeridiem = getMeridiem(convertTime(preferredDate.hour));
      var preferredEndHour = formatTime(
          convertTime(preferredDate.add(const Duration(minutes: 30)).hour));
      var preferredEndMinute =
      formatTime(preferredDate.add(const Duration(minutes: 30)).minute);
      var preferredEndMeridiem = getMeridiem(
          convertTime(preferredDate.add(const Duration(minutes: 30)).hour));

      //Schedule
      var date = pickedTime;
      var year = date.year;
      var month = formatMonth(date.month).substring(0, 3);
      var day = formatTime(date.day);
      var startHour = formatTime(convertTime(date.hour));
      var startMinute = formatTime(date.minute);
      var startMeridiem = getMeridiem(convertTime(date.hour));
      var endHour =
      formatTime(convertTime(date.add(const Duration(minutes: 30)).hour));
      var endMinute = formatTime(date.add(const Duration(minutes: 30)).minute);
      var endMeridiem =
      getMeridiem(convertTime(date.add(const Duration(minutes: 30)).hour));

      showDialog<String>(
        useSafeArea: true,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, dialogSetState) {
              return WillPopScope(
                onWillPop: () async {
                  Navigator.pop(context, 'back');
                  return false;
                },
                child: Dialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                  insetPadding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder(
                              future: getData(
                                  "${accountType}s", id: appointmentDetails['${accountType}ID']),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.done) {
                                  var clinicData = snapshot.data!;

                                  return Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "${clinicData['clinicName']}",
                                            style: textTheme.labelMedium
                                                ?.copyWith(
                                                fontWeight:
                                                FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Text(
                                          "${appointmentDetails['service']}",
                                          style: textTheme.bodyMedium?.copyWith(
                                              color: appColors['gray143']),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: FutureBuilder(
                                          future: getData(
                                            "${accountType}s",
                                            id: appointmentDetails['${accountType}ID'],
                                            field: "address",
                                          ),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.done) {
                                              var address = snapshot.data;

                                              return FutureBuilder(
                                                future:
                                                placemarkFromCoordinates(
                                                    address['latitude'],
                                                    address['longitude']),
                                                builder: (context, snapshot) {
                                                  if (snapshot
                                                      .connectionState ==
                                                      ConnectionState.done) {
                                                    var address =
                                                        snapshot.data!.first;
                                                    return Text(
                                                      "${address.street}. ${address.subLocality}, ${address.locality}, ${address.administrativeArea}",
                                                      style: textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                          color: appColors[
                                                          'gray143']),
                                                    );
                                                  } else {
                                                    return Container(
                                                      height: 16,
                                                      width: deviceWidth,
                                                      decoration: BoxDecoration(
                                                          color: appColors[
                                                          'coolGray'],
                                                          borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                              15)),
                                                    );
                                                  }
                                                },
                                              );
                                            } else {
                                              return Container(
                                                height: 16,
                                                width: deviceWidth,
                                                decoration: BoxDecoration(
                                                    color:
                                                    appColors['coolGray'],
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        15)),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                      accountType == "clinic" ? Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: FutureBuilder(
                                          future: getData(
                                            "doctors",
                                            id: appointmentDetails['doctorID'],
                                            field: "name",
                                          ),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.done) {
                                              var name = snapshot.data;

                                              return Text(
                                                "Dr. $name",
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                    color: appColors[
                                                    'gray143']),
                                              );
                                            } else {
                                              return Container(
                                                height: 16,
                                                width: 120,
                                                decoration: BoxDecoration(
                                                    color:
                                                    appColors['coolGray'],
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        15)),
                                              );
                                            }
                                          },
                                        ),
                                      ) : const  SizedBox.shrink(),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 18,
                                        width: 150,
                                        decoration: BoxDecoration(
                                            color: appColors['coolGray'],
                                            borderRadius:
                                            BorderRadius.circular(15)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 5),
                                        child: Container(
                                          height: 16,
                                          width: 50,
                                          decoration: BoxDecoration(
                                              color: appColors['coolGray'],
                                              borderRadius:
                                              BorderRadius.circular(15)),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 5),
                                        child: Container(
                                          height: 16,
                                          width: 120,
                                          decoration: BoxDecoration(
                                              color: appColors['coolGray'],
                                              borderRadius:
                                              BorderRadius.circular(15)),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 5),
                                        child: Container(
                                          height: 16,
                                          width: 110,
                                          decoration: BoxDecoration(
                                              color: appColors['coolGray'],
                                              borderRadius:
                                              BorderRadius.circular(15)),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Text(
                                    "Current Schedule",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding:
                                        const EdgeInsets.only(right: 20),
                                        child: Text(
                                          "$preferredMonth. $preferredDay, $preferredYear",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                      Text(
                                        "$preferredStartHour:$preferredStartMinute ${preferredStartMeridiem.toUpperCase()} - $preferredEndHour:$preferredEndMinute ${preferredEndMeridiem.toUpperCase()}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      )
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 20),
                                  child: Divider(
                                      color: appColors['black'],
                                      height: 0,
                                      thickness: 1),
                                ),
                                Text(
                                  "New Schedule Request",
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding:
                                        const EdgeInsets.only(right: 20),
                                        child: Text(
                                          "$month. $day, $year",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                      Text(
                                        "$startHour:$startMinute ${startMeridiem.toUpperCase()} - $endHour:$endMinute ${endMeridiem.toUpperCase()}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 30),
                              child: Text(
                                "Reason for Rescheduling:",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 15),
                                    child: Icon(
                                        Icons.notification_important_outlined,
                                        color: appColors['accent']),
                                  ),
                                  Text(
                                    "$reason",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            )
                          ],
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
                              padding:
                              const EdgeInsets.fromLTRB(30, 15, 39, 17),
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
                                      "Hey there! Are you satisfied with your RESCHEDULE request?",
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
                              padding:
                              const EdgeInsets.only(left: 20, right: 20),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: Container(
                                        clipBehavior: Clip.hardEdge,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                            BorderRadius.circular(5),
                                            border: Border.all(
                                                color: appColors['white']!)),
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.pop(context, "back");
                                          },
                                          style: OutlinedButton.styleFrom(
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
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
                                            borderRadius:
                                            BorderRadius.circular(5),
                                            border: Border.all(
                                                color: appColors['white']!)),
                                        child: TextButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            var UID = await getData("${accountType}s", id: appointmentDetails['${accountType}ID'], field: "uid");

                                            await addNotification(uid: UID, title: "New Reschedule Request", body: "Hey Doc! A Patient submitted a Reschedule Request. Review it Now!");
                                            await updateData('${accountType}Appointments', id: appointmentDetails['${accountType}AppointmentID'], {"status": "rescheduling", "reason": reason, "rescheduleDate": pickedTime.toString()});
                                          },
                                          style: OutlinedButton.styleFrom(
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
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
                ),
              );
            },
          );
        },
      ).then((value) {
        if (value != 'back') {
          Navigator.pop(context);
          showRescheduleSubmittedPrompt();
        }
      });
    }

    return Scaffold(
      backgroundColor: appColors['accent'],
      body: SafeArea(
        child: Container(
            height: double.maxFinite,
            width: double.maxFinite,
            color: appColors['primary'],
            child: Stack(
              children: [
                FutureBuilder(
                  future: getDoctorDetails(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: SizedBox(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(top: 74, bottom: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        FutureBuilder(
                                          future: getData("${accountType}s",
                                              id: appointmentDetails['${accountType}ID']),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.done) {
                                              var clinicData = snapshot.data!;

                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        "${clinicData['clinicName']}",
                                                        style: textTheme
                                                            .labelMedium
                                                            ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                      ),
                                                    ],
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 10),
                                                    child: Text(
                                                      "${appointmentDetails['service']}",
                                                      style: textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                              color: appColors[
                                                                  'gray143']),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 10),
                                                    child: FutureBuilder(
                                                      future: getData(
                                                        "${accountType}s",
                                                        id: appointmentDetails[
                                                            '${accountType}ID'],
                                                        field: "address",
                                                      ),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .done) {
                                                          var address =
                                                              snapshot.data;

                                                          return FutureBuilder(
                                                            future: placemarkFromCoordinates(
                                                                address[
                                                                    'latitude'],
                                                                address[
                                                                    'longitude']),
                                                            builder: (context,
                                                                snapshot) {
                                                              if (snapshot
                                                                      .connectionState ==
                                                                  ConnectionState
                                                                      .done) {
                                                                var address =
                                                                    snapshot
                                                                        .data!
                                                                        .first;
                                                                return Text(
                                                                  "${address.street}. ${address.subLocality}, ${address.locality}, ${address.administrativeArea}",
                                                                  style: textTheme
                                                                      .bodyMedium
                                                                      ?.copyWith(
                                                                          color:
                                                                              appColors['gray143']),
                                                                );
                                                              } else {
                                                                return Container(
                                                                  height: 16,
                                                                  width:
                                                                      deviceWidth,
                                                                  decoration: BoxDecoration(
                                                                      color: appColors[
                                                                          'coolGray'],
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              15)),
                                                                );
                                                              }
                                                            },
                                                          );
                                                        } else {
                                                          return Container(
                                                            height: 16,
                                                            width: deviceWidth,
                                                            decoration: BoxDecoration(
                                                                color: appColors[
                                                                    'coolGray'],
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            15)),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  accountType == "clinic" ? Padding(
                                                    padding:
                                                    const EdgeInsets.only(
                                                        top: 10),
                                                    child: FutureBuilder(
                                                      future: getData(
                                                        "doctors",
                                                        id: appointmentDetails[
                                                        'doctorID'],
                                                        field: "name",
                                                      ),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot
                                                            .connectionState ==
                                                            ConnectionState
                                                                .done) {
                                                          var name =
                                                              snapshot.data;

                                                          return Text(
                                                            "Dr. $name",
                                                            style: textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                                color: appColors[
                                                                'gray143']),
                                                          );
                                                        } else {
                                                          return Container(
                                                            height: 16,
                                                            width: 120,
                                                            decoration: BoxDecoration(
                                                                color: appColors[
                                                                'coolGray'],
                                                                borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                    15)),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ) : const SizedBox.shrink(),
                                                ],
                                              );
                                            } else {
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    height: 18,
                                                    width: 150,
                                                    decoration: BoxDecoration(
                                                        color: appColors[
                                                            'coolGray'],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15)),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 5),
                                                    child: Container(
                                                      height: 16,
                                                      width: 50,
                                                      decoration: BoxDecoration(
                                                          color: appColors[
                                                              'coolGray'],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      15)),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 5),
                                                    child: Container(
                                                      height: 16,
                                                      width: 120,
                                                      decoration: BoxDecoration(
                                                          color: appColors[
                                                              'coolGray'],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      15)),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 5),
                                                    child: Container(
                                                      height: 16,
                                                      width: 110,
                                                      decoration: BoxDecoration(
                                                          color: appColors[
                                                              'coolGray'],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      15)),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 15),
                                          child: Text(
                                            appointmentDetails['status'] ==
                                                    'pending'
                                                ? "Preferred Schedule"
                                                : "Approved Schedule",
                                            style: textTheme.labelMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 15),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 20),
                                                child: Text(
                                                  "$month. $day, $year",
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
                                                          color: appColors[
                                                              'gray143']),
                                                ),
                                              ),
                                              Text(
                                                "$startHour:$startMinute ${startMeridiem.toUpperCase()} - $endHour:$endMinute ${endMeridiem.toUpperCase()}",
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color: appColors[
                                                            'gray143']),
                                              )
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 20),
                                          child: Divider(
                                              color: appColors['black'],
                                              height: 0,
                                              thickness: 1),
                                        ),
                                      ],
                                    ),
                                    StatefulBuilder(
                                      builder: (context, setState) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Center(
                                              child: Text(
                                                "Schedule Available",
                                                style: textTheme.labelMedium
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600),
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                isScheduleInvalid
                                                    ? Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 15),
                                                        child: Text(
                                                          "Please choose your preferred date and time.",
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                  color: appColors[
                                                                      'accent']),
                                                        ),
                                                      )
                                                    : const SizedBox.shrink(),
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                      top: pickedTime == null
                                                          ? 5
                                                          : 15),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        "Pick a date",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: appColors[
                                                                  'black'],
                                                            ),
                                                      ),
                                                      Text(
                                                        "$displayMonth $displayYear",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: appColors[
                                                                  'black'],
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 10),
                                                  child: SizedBox(
                                                    height: 82,
                                                    child: ListView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      children:
                                                          generateDateWidget(
                                                              setState),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 30),
                                                  child: Text(
                                                    "Pick a time",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: appColors[
                                                              'black'],
                                                        ),
                                                  ),
                                                ),
                                                getServiceHours(
                                                            pickedDate.weekday)
                                                        .isNotEmpty
                                                    ? Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 14),
                                                        child: Column(
                                                          children: [
                                                            SizedBox(
                                                              height: 160,
                                                              child: GridView
                                                                  .builder(
                                                                      shrinkWrap:
                                                                          true,
                                                                      gridDelegate:
                                                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                                                        crossAxisCount:
                                                                            3,
                                                                        mainAxisSpacing:
                                                                            5,
                                                                        mainAxisExtent:
                                                                            36,
                                                                        crossAxisSpacing:
                                                                            5,
                                                                      ),
                                                                      itemCount:
                                                                          timeSlots
                                                                              .length,
                                                                      itemBuilder:
                                                                          (BuildContext context,
                                                                              int index) {
                                                                        int startHour =
                                                                            convertTime(timeSlots[index].hour);
                                                                        int startMinute =
                                                                            timeSlots[index].minute;

                                                                        return GestureDetector(
                                                                          onTap:
                                                                              () {
                                                                            setState(() {
                                                                              if (!takenSlots.contains(timeSlots[index])) {
                                                                                pickedTime = timeSlots[index];
                                                                                isScheduleInvalid = pickedTime == null;
                                                                              }
                                                                            });
                                                                          },
                                                                          child:
                                                                              Container(
                                                                            decoration: BoxDecoration(
                                                                                color: pickedTime == timeSlots[index]
                                                                                    ? appColors['accent']
                                                                                    : takenSlots.contains(timeSlots[index])
                                                                                        ? appColors['gray192']
                                                                                        : appColors['coolGray'],
                                                                                borderRadius: BorderRadius.circular(15)),
                                                                            child:
                                                                                Center(
                                                                              child: Text(
                                                                                "${formatTime(startHour)}:${formatTime(startMinute)} ${timeSlots[index].hour < 12 ? "am" : "pm"}",
                                                                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
                                                                  const EdgeInsets
                                                                          .only(
                                                                      top: 24),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  RichText(
                                                                    text:
                                                                        TextSpan(
                                                                      style: Theme.of(
                                                                              context)
                                                                          .textTheme
                                                                          .labelSmall
                                                                          ?.copyWith(
                                                                            fontSize:
                                                                                10,
                                                                            color:
                                                                                appColors['gray143'],
                                                                          ),
                                                                      children: const <
                                                                          TextSpan>[
                                                                        TextSpan(
                                                                            text:
                                                                                'Reschedule request may or may '),
                                                                        TextSpan(
                                                                            text:
                                                                                'NOT',
                                                                            style:
                                                                                TextStyle(decoration: TextDecoration.underline)),
                                                                        TextSpan(
                                                                            text:
                                                                                ' be\naccepted. '),
                                                                      ],
                                                                    ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                  ),
                                                                  Icon(
                                                                    Icons
                                                                        .priority_high,
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
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 48),
                                                        child: Center(
                                                          child: Column(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .event_busy,
                                                                color: appColors[
                                                                    'gray143'],
                                                                size: 60,
                                                              ),
                                                              Text(
                                                                "No available Schedule \non this day",
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyMedium
                                                                    ?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color: appColors[
                                                                          'gray143'],
                                                                    ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                              ],
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 30),
                                              child: Text(
                                                "Reason for Rescheduling:",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: appColors['black'],
                                                    ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 15),
                                              child: DropdownButtonFormField(
                                                isDense: true,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600),
                                                decoration: InputDecoration(
                                                    filled: true,
                                                    fillColor:
                                                        appColors['coolGray'],
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      borderSide:
                                                          BorderSide.none,
                                                    ),
                                                    contentPadding:
                                                        const EdgeInsets
                                                                .fromLTRB(
                                                            15, 11, 8, 11)),
                                                value: reason,
                                                onChanged: (value) {
                                                  setState(() {
                                                    reason = value!;
                                                    getServiceHours(
                                                        pickedDate.weekday);
                                                  });
                                                },
                                                items:
                                                    reasons.map((String value) {
                                                  return DropdownMenuItem(
                                                    value: value,
                                                    child: Text(value),
                                                  );
                                                }).toList(),
                                              ),
                                            )
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      return const Center();
                    }
                  },
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
                              Navigator.pop(context);
                            },
                            child: Icon(
                              Icons.close,
                              color: appColors['black'],
                            ),
                          ),
                        ),
                        Text(
                          "Reschedule Request",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            if (pickedTime != null) {
                              showRescheduleSummaryDialog();
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
