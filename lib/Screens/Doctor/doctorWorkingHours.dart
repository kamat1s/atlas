import 'dart:developer';

import 'package:atlas/query.dart';
import 'package:atlas/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';

import '../../global.dart';
import '../../utils.dart';

class DoctorWorkingHours extends StatefulWidget {
  const DoctorWorkingHours({Key? key}) : super(key: key);

  @override
  State<DoctorWorkingHours> createState() => _DoctorWorkingHoursState();
}

class _DoctorWorkingHoursState extends State<DoctorWorkingHours> {
  Map<String, dynamic> independentDoctorInformation = userData;

  Map<String, dynamic> availableDays = {
    "Monday": false,
    "Tuesday": false,
    "Wednesday": false,
    "Thursday": false,
    "Friday": false,
    "Saturday": false,
    "Sunday": false,
  };

  final _dateTimeNow = DateTime.now();
  DateTime? _openingTime;
  DateTime? _closingTime;

  List serviceHours = [
    {"day": "Monday"},
    {"day": "Tuesday"},
    {"day": "Wednesday"},
    {"day": "Thursday"},
    {"day": "Friday"},
    {"day": "Saturday"},
    {"day": "Sunday"},
  ];

  final Stream<QuerySnapshot<Map<String, dynamic>>>
      independentDoctorDataStream = FirebaseFirestore.instance
          .collection('independentDoctors')
          .where("uid", isEqualTo: uid)
          .snapshots();

  @override
  void initState() {
    getServiceHours();
    print(serviceHours);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: appColors['accent'],
      body: SafeArea(
        child: Container(
            height: double.maxFinite,
            width: double.maxFinite,
            color: appColors['primary'],
            child: Stack(
              children: [
                StreamBuilder(
                  stream: independentDoctorDataStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Something went wrong');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.expand();
                    }

                    independentDoctorInformation =
                        snapshot.data!.docs.first.data();

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 50),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: serviceHours.length,
                        itemBuilder: (context, index) {
                          var serviceHour = serviceHours[index];
                          var day = serviceHour['day'];

                          return Padding(
                            padding: const EdgeInsets.only(top: 23),
                            child: Row(
                              children: [
                                Text(
                                  "$day",
                                  style: getTextStyle(
                                    textColor: availableDays[day]
                                        ? 'black'
                                        : 'gray145',
                                    fontFamily: 'Inter',
                                    fontWeight: 500,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    if (availableDays[day]) {
                                      editTime(index, setState);
                                    }
                                  },
                                  child: Text(
                                    "${formatTime(convertTime(serviceHour['openingHour']))}:${formatTime(serviceHour['openingMinute'])} ${serviceHour['openingMeridiem']} - ${formatTime(convertTime(serviceHour['closingHour']))}:${formatTime(serviceHour['closingMinute'])} ${serviceHour['closingMeridiem']}",
                                    style: getTextStyle(
                                      textColor: availableDays[day]
                                          ? 'black'
                                          : 'gray145',
                                      fontFamily: 'Inter',
                                      fontWeight: 500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Checkbox(
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  activeColor: appColors['accent'],
                                  value: availableDays[day],
                                  onChanged: (value) async {
                                    int availableDaysCounter = 0;

                                    availableDays.forEach((key, value) {
                                      if (value == true) {
                                        availableDaysCounter++;
                                      }
                                    });

                                    bool dayHasAppointment =
                                        await checkDateWithAppointment(
                                            ID: userData['independentDoctorID'],
                                            accountType: "independentDoctor",
                                            day: day);

                                    if (dayHasAppointment) {
                                      showCannotDeleteInfoPrompt();
                                    } else if (availableDaysCounter > 1 ||
                                        value == true) {
                                      setState(() {
                                        availableDays[day] = value!;
                                      });
                                    } else {
                                      showSnackBar(
                                          "You must provide at least one working hour.");
                                    }

                                    await updateServiceHours();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
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
                              Icons.arrow_back,
                              color: appColors['black'],
                            ),
                          ),
                        ),
                        Text(
                          "Working Hours",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
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

  getServiceHours() {
    for (int i = 0; i < serviceHours.length; i++) {
      for (var serviceHour in independentDoctorInformation['serviceHours']) {
        if (serviceHour['day'] == serviceHours[i]['day']) {
          serviceHours[i] = serviceHour;
          availableDays[serviceHour['day']] = true;
          break;
        }
      }

      if (!availableDays[serviceHours[i]['day']]) {
        serviceHours[i] = {
          "day": serviceHours[i]['day'],
          "openingHour": 7,
          "openingMinute": 0,
          "openingMeridiem": 'AM',
          "closingHour": 17,
          "closingMinute": 0,
          "closingMeridiem": 'PM'
        };
      }
    }
  }

  updateServiceHours() async {
    var newServiceHours = [];

    for (var serviceHour in serviceHours) {
      if (availableDays[serviceHour['day']]) {
        newServiceHours.add(serviceHour);
      }
    }

    independentDoctorInformation['serviceHours'] = newServiceHours;

    await updateData('independentDoctors', independentDoctorInformation,
        uid: uid);
  }

  editTime(int index, var setState) {
    showDialog<void>(
      useSafeArea: true,
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        final deviceWidth = MediaQuery.of(context).size.width;

        _openingTime = DateTime(
            _dateTimeNow.year,
            1,
            1,
            serviceHours[index]['openingHour'],
            serviceHours[index]['openingMinute']);
        _closingTime = DateTime(
            _dateTimeNow.year,
            1,
            1,
            serviceHours[index]['closingHour'],
            serviceHours[index]['closingMinute']);

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              insetPadding: const EdgeInsets.all(15),
              child: SizedBox(
                height: 220,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Set Time",
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      height: 48,
                                      width: (deviceWidth * .5) - 50,
                                      decoration: BoxDecoration(
                                        color: appColors['coolGray'],
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    TimePickerSpinner(
                                      time: _openingTime,
                                      is24HourMode: false,
                                      minutesInterval: 30,
                                      normalTextStyle:
                                          theme.textTheme.labelSmall?.copyWith(
                                              color: appColors['gray143']),
                                      highlightedTextStyle:
                                          theme.textTheme.labelSmall,
                                      alignment: Alignment.center,
                                      spacing: 15,
                                      itemHeight: 38,
                                      itemWidth: 20,
                                      isForce2Digits: true,
                                      onTimeChange: (time) {
                                        if (!mounted) return;
                                        setState(() {
                                          _openingTime = time;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                Text(
                                  "to",
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: appColors['gray143']),
                                ),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      height: 48,
                                      width: (deviceWidth * .5) - 50,
                                      decoration: BoxDecoration(
                                        color: appColors['coolGray'],
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    TimePickerSpinner(
                                      time: _closingTime,
                                      is24HourMode: false,
                                      minutesInterval: 30,
                                      normalTextStyle:
                                          theme.textTheme.labelSmall?.copyWith(
                                              color: appColors['gray143']),
                                      highlightedTextStyle:
                                          theme.textTheme.labelSmall,
                                      alignment: Alignment.center,
                                      spacing: 15,
                                      itemHeight: 38,
                                      itemWidth: 20,
                                      isForce2Digits: true,
                                      onTimeChange: (time) {
                                        if (!mounted) return;
                                        setState(() {
                                          _closingTime = time;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 40),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
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
                              onTap: () async {
                                setState(() {
                                  serviceHours[index]['openingHour'] =
                                      _openingTime!.hour;

                                  serviceHours[index]['openingMinute'] =
                                      _openingTime!.minute;

                                  serviceHours[index]['openingMeridiem'] =
                                      _openingTime!.hour < 12 ? "AM" : "PM";

                                  serviceHours[index]['closingHour'] =
                                      _closingTime!.hour;

                                  serviceHours[index]['closingMinute'] =
                                      _closingTime!.minute;

                                  serviceHours[index]['closingMeridiem'] =
                                      _closingTime!.hour < 12 ? "AM" : "PM";
                                });
                                await updateServiceHours();

                                if (!mounted) return;

                                Navigator.of(context).pop();
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: Text(
                                  "Apply",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: appColors['accent'],
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
              ),
            );
          },
        );
      },
    );
  }

  showSnackBar(var errorMessage) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "$errorMessage",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: appColors['white'],
              ),
        ),
        backgroundColor: appColors['accent'],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  showCannotDeleteInfoPrompt() {
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
                    Icons.dangerous,
                    size: 84,
                    color: appColors['accent'],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Text(
                      "Oops! There are active appointment/s on that time and day!",
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
                        "This working hour can’t be deleted because it has appointments that are still active.",
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
}
