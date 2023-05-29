import 'dart:developer';

import 'package:atlas/query.dart';
import 'package:atlas/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';

import '../../Classes/Doctor.dart';
import '../../global.dart';
import '../../utils.dart';

class EditDoctorInformation extends StatefulWidget {
  final doctorID;
  const EditDoctorInformation({Key? key, required this.doctorID})
      : super(key: key);

  @override
  State<EditDoctorInformation> createState() => _EditDoctorInformationState();
}

class _EditDoctorInformationState extends State<EditDoctorInformation> {
  int doctorID = 0;

  Map<String, dynamic> doctorInformation = {};
  Map<String, dynamic> clinicInformation = userData;

  TextEditingController doctorNameController = TextEditingController();

  List<String> specializations = [];
  List<String> prev = [];

  bool invalidName = false;
  bool noAvailableDays = false;
  bool dataLoaded = false;

  final _dateTimeNow = DateTime.now();
  DateTime? _openingTime;
  DateTime? _closingTime;

  Stream<QuerySnapshot<Map<String, dynamic>>> doctorDataStream =
      const Stream.empty();

  @override
  void initState() {
    doctorID = widget.doctorID;

    doctorDataStream = FirebaseFirestore.instance
        .collection('doctors')
        .where("doctorID", isEqualTo: doctorID)
        .snapshots();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final deviceWidth = MediaQuery.of(context).size.width;

    return StreamBuilder(
        stream: doctorDataStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.expand();
          }

          if (!dataLoaded) {
            doctorInformation = snapshot.data!.docs.first.data();

            doctorNameController.text = doctorInformation['name'];

            for (var specialization in doctorInformation['specializations']) {
              specializations.add(specialization);
            }

            getDoctorServiceHours();

            dataLoaded = true;
          }

          return StatefulBuilder(builder: (context, StateSetter setState) {
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
                          padding: const EdgeInsets.only(
                              top: 74, left: 20, right: 20),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Column(
                              children: [
                                doctorNameWidget(setState),
                                doctorSpecializationsWidget(setState),
                                doctorServiceHoursWidget(setState),
                              ],
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
                                      Navigator.pop(context);
                                    },
                                    child: Icon(
                                      Icons.arrow_back,
                                      color: appColors['black'],
                                    ),
                                  ),
                                ),
                                Text(
                                  "Edit Doctor Information",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () async {
                                    if (!invalidName &&
                                        !noAvailableDays &&
                                        specializations.isNotEmpty) {
                                      Map<String, dynamic> data =
                                          Map.from(doctorInformation);

                                      data['name'] = doctorNameController.text;
                                      data['specializations'] = specializations;

                                      List<Map<String, dynamic>>
                                          updatedServiceHours = [];

                                      for (var serviceHour
                                          in data['serviceHours']) {
                                        if (data['availableDays']
                                            [serviceHour['day']]) {
                                          updatedServiceHours.add(serviceHour);
                                        }
                                      }

                                      data['serviceHours'] =
                                          updatedServiceHours;

                                      showEditConfirmation(data);
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
          });
        });
  }

  Widget doctorNameWidget(setState) => Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Icon(
              Icons.account_circle_outlined,
              color: appColors['black'],
            ),
          ),
          Expanded(
            child: SizedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    style: getTextStyle(
                      textColor: 'black',
                      fontFamily: 'Inter',
                      fontWeight: 500,
                      fontSize: 12,
                    ),
                    controller: doctorNameController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Physician Name",
                      hintStyle: getTextStyle(
                        textColor: 'gray145',
                        fontFamily: 'Inter',
                        fontWeight: 500,
                        fontSize: 12,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        setState(() {
                          invalidName = true;
                        });
                      } else {
                        setState(() {
                          invalidName = false;
                        });
                      }
                    },
                  ),
                  Container(
                    height: 1,
                    color: appColors['gray231'],
                  ),
                  Visibility(
                    visible: invalidName,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        "Physician name is required.",
                        style: getTextStyle(
                          textColor: 'accent',
                          fontFamily: 'Inter',
                          fontWeight: 500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      );

  Widget doctorSpecializationsWidget(setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Row(
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      color: appColors['black'],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Column(
                  children: [
                    ListTile(
                      onTap: () => showSpecialization(setState),
                      title: Text(
                        "Add Specialization",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: appColors['gray145'],
                            fontWeight: FontWeight.w500),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    Divider(
                        height: 0, color: appColors['gray231'], thickness: 1),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: specializations.length,
              itemBuilder: (context, index) {
                var specialization = specializations[index];

                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        specialization,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: appColors['gray145'],
                            fontWeight: FontWeight.w500),
                      ),
                      contentPadding: EdgeInsets.zero,
                      trailing: GestureDetector(
                        child: Icon(Icons.close,
                            color: appColors['gray145'], size: 16),
                        onTap: () {
                          setState(() {
                            specializations.remove(specialization);
                          });
                        },
                      ),
                    ),
                    Divider(
                        height: 0, color: appColors['gray231'], thickness: 1),
                  ],
                );
              },
            ),
          ),
          Visibility(
            visible: specializations.isEmpty,
            child: Padding(
              padding: const EdgeInsets.only(top: 5, left: 44),
              child: Text(
                "Specialization is required.",
                style: getTextStyle(
                  textColor: 'accent',
                  fontFamily: 'Inter',
                  fontWeight: 500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      );

  Widget doctorServiceHoursWidget(setState) => Padding(
        padding: const EdgeInsets.only(top: 23),
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(
                    Icons.watch_later_outlined,
                    color: appColors['black'],
                  ),
                ),
                Text(
                  "Days the Doctor is In",
                  style: getTextStyle(
                    textColor: 'black',
                    fontFamily: 'Inter',
                    fontWeight: 500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: doctorInformation['serviceHours'].length,
                itemBuilder: (context, index) {
                  var serviceHour = doctorInformation['serviceHours'][index];
                  var day = serviceHour['day'];

                  return Padding(
                    padding: const EdgeInsets.only(top: 23),
                    child: Row(
                      children: [
                        Text(
                          "$day",
                          style: getTextStyle(
                            textColor: doctorInformation['availableDays'][day]
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
                            if (doctorInformation['availableDays'][day]) {
                              editTime(index, setState, timeOf: "doctor");
                            }
                          },
                          child: Text(
                            "${formatTime(convertTime(serviceHour['openingHour']))}:${formatTime(serviceHour['openingMinute'])} ${serviceHour['openingMeridiem']} - ${formatTime(convertTime(serviceHour['closingHour']))}:${formatTime(serviceHour['closingMinute'])} ${serviceHour['closingMeridiem']}",
                            style: getTextStyle(
                              textColor: doctorInformation['availableDays'][day]
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
                          value: doctorInformation['availableDays'][day],
                          onChanged: (value) {
                            setState(() {
                              doctorInformation['availableDays'][day] = value!;
                              noAvailableDays =
                                  !doctorInformation['availableDays']
                                      .containsValue(true);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 15),
              child: Column(
                children: [
                  Divider(
                      height: 0,
                      color: noAvailableDays
                          ? appColors['accent']
                          : appColors['gray231'],
                      thickness: 1),
                  noAvailableDays
                      ? Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            "Doctor must have at least one day in the clinic.",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: appColors['accent']),
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      );

  showSpecialization(var setState) {
    showDialog<void>(
      useSafeArea: true,
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        return WillPopScope(
          onWillPop: () async {
            specializations.clear();
            specializations.addAll(prev);
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
                          "Specialization",
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
                                itemCount: userData['services'].length,
                                itemBuilder: (BuildContext context, int index) {
                                  String service = userData['services'][index];
                                  return SizedBox(
                                    height: 48,
                                    child: TextButton(
                                      onPressed: () {
                                        if (!mounted) return;
                                        dialogSetState(() {
                                          if (specializations
                                              .contains(service)) {
                                            specializations.remove(service);
                                          } else {
                                            specializations.add(service);
                                          }
                                        });
                                      },
                                      style: TextButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        backgroundColor:
                                            specializations.contains(service)
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
                                            color: specializations
                                                    .contains(service)
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
                                  specializations.clear();
                                  specializations.addAll(prev);
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
                              onTap: () {
                                setState(() {
                                  prev.clear();
                                  prev.addAll(specializations);
                                });
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

  editTime(int index, var setState, {String timeOf = "clinic"}) {
    showDialog<void>(
      useSafeArea: true,
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        final deviceWidth = MediaQuery.of(context).size.width;

        List<dynamic> serviceHours = [];

        if (timeOf == "clinic") {
          serviceHours = clinicInformation['serviceHours'];
        } else {
          log(timeOf);
          serviceHours = doctorInformation['serviceHours'];
        }

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
                              onTap: () {
                                setState(() {
                                  if (timeOf == "clinic") {
                                    clinicInformation['serviceHours'][index]
                                        ['openingHour'] = _openingTime!.hour;

                                    clinicInformation['serviceHours'][index]
                                            ['openingMinute'] =
                                        _openingTime!.minute;

                                    clinicInformation['serviceHours'][index]
                                            ['openingMeridiem'] =
                                        _openingTime!.hour < 12 ? "AM" : "PM";

                                    clinicInformation['serviceHours'][index]
                                        ['closingHour'] = _closingTime!.hour;

                                    clinicInformation['serviceHours'][index]
                                            ['closingMinute'] =
                                        _closingTime!.minute;

                                    clinicInformation['serviceHours'][index]
                                            ['closingMeridiem'] =
                                        _closingTime!.hour < 12 ? "AM" : "PM";
                                  } else {
                                    doctorInformation['serviceHours'][index]
                                        ['openingHour'] = _openingTime!.hour;

                                    doctorInformation['serviceHours'][index]
                                            ['openingMinute'] =
                                        _openingTime!.minute;

                                    doctorInformation['serviceHours'][index]
                                            ['openingMeridiem'] =
                                        _openingTime!.hour < 12 ? "AM" : "PM";

                                    doctorInformation['serviceHours'][index]
                                        ['closingHour'] = _closingTime!.hour;

                                    doctorInformation['serviceHours'][index]
                                            ['closingMinute'] =
                                        _closingTime!.minute;

                                    doctorInformation['serviceHours'][index]
                                            ['closingMeridiem'] =
                                        _closingTime!.hour < 12 ? "AM" : "PM";

                                    log(doctorInformation['serviceHours'][index]
                                        .toString());
                                  }
                                });

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

  getDoctorServiceHours() {
    for (var serviceHour in clinicInformation['serviceHours']) {
      var day = serviceHour['day'];

      if (!doctorInformation['availableDays'][day]) {
        doctorInformation['serviceHours'].add(serviceHour);
      }
    }
  }

  showEditConfirmation(data) {
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
                                    "Hey Doc! Are you sure you want to Save New Changes?",
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
                                          await updateData('doctors', data, id: doctorID);

                                          if(!mounted) return;

                                          Navigator.pop(context);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          tapTargetSize: MaterialTapTargetSize
                                              .shrinkWrap,
                                        ),
                                        child: Text(
                                          "Yes, Save Now",
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
      if (value != "back") {
        Navigator.pop(context, 'save');
      }
    });
  }
}
