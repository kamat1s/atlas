import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import '../../global.dart';
import '../../postmanApi.dart';
import '../../query.dart';
import '../../styles.dart';
import '../../utils.dart';

class ClinicAppointments extends StatefulWidget {
  const ClinicAppointments({Key? key}) : super(key: key);

  @override
  State<ClinicAppointments> createState() => _ClinicAppointmentsState();
}

class _ClinicAppointmentsState extends State<ClinicAppointments> {
  FocusNode upcomingButtonFocus = FocusNode();
  FocusNode completedButtonFocus = FocusNode();
  FocusNode cancelledButtonFocus = FocusNode();

  List upcomingAppointments = [];
  List completedAppointments = [];
  List cancelledAppointments = [];
  final Stream<QuerySnapshot> clinicAppointmentStream = FirebaseFirestore.instance
      .collection('clinicAppointments')
      .where('clinicID', isEqualTo: userData['clinicID'])
      .orderBy('date', descending: true)
      .snapshots();

  showAppointmentCompletePrompt() {
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
                    Icons.task_alt,
                    size: 84,
                    color: appColors['accent'],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Text(
                      "Appointment Successfully Completed!",
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
                        "The appointment is now moved to the Completed Section of the Appointment Tab",
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

  showCompleteDialog(var clinicAppointmentID) {
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
                                    "Hey Doc! Are you sure you want to Mark this as Complete?",
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
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          border: Border.all(
                                              color: appColors['white']!)),
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, "back");
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
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          border: Border.all(
                                              color: appColors['white']!)),
                                      child: TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          showAppointmentCompletePrompt();
                                          await updateData(
                                              'clinicAppointments',
                                              id: clinicAppointmentID,
                                              {'status': "done"});
                                        },
                                        style: OutlinedButton.styleFrom(
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          "Yes, Complete Now",
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
    );
  }

  showDismissDialog(var clinicAppointmentID) {
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
                          color: appColors['white'],
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
                                    Icons.question_mark,
                                    size: 48,
                                    color: appColors['accent'],
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "Hey Doc! Are you sure you want to Dismiss this Appointment?",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
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
                                            color: appColors['accent']!),
                                        color: appColors['white'],
                                      ),
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, "back");
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
                                        borderRadius: BorderRadius.circular(5),
                                        color: appColors['accent'],
                                      ),
                                      child: TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await updateData(
                                              'clinicAppointments',
                                              id: clinicAppointmentID,
                                              {'status': "dismissed"});
                                        },
                                        style: OutlinedButton.styleFrom(
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          "Yes, Dismiss Now",
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
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    upcomingButtonFocus.requestFocus();

    super.initState();
  }

  @override
  void dispose() {
    upcomingButtonFocus.dispose();
    completedButtonFocus.dispose();
    cancelledButtonFocus.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<QuerySnapshot>(
      stream: clinicAppointmentStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.expand();
        }

        upcomingAppointments.clear();
        completedAppointments.clear();
        cancelledAppointments.clear();

        for (var appointments in snapshot.data!.docs) {
          Map<String, dynamic> appointmentDetails =
              appointments.data()! as Map<String, dynamic>;

          if (appointmentDetails['status'] == 'accepted') {
            upcomingAppointments.add(appointmentDetails);
          } else if (appointmentDetails['status'] == 'done') {
            completedAppointments.add(appointmentDetails);
          } else if (appointmentDetails['status'] == 'cancelled' ||
              appointmentDetails['status'] == 'dismissed' ||
              appointmentDetails['status'] == 'rejected') {
            cancelledAppointments.add(appointmentDetails);
          }
        }

        return Stack(
          children: [
            upcomingButtonFocus.hasFocus && upcomingAppointments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          color: appColors['gray145'],
                          size: 77,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 89, right: 89, top: 10),
                          child: Text("No Upcoming Appointments yet",
                              style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: appColors['gray145']),
                              textAlign: TextAlign.center),
                        )
                      ],
                    ),
                  )
                : upcomingButtonFocus.hasFocus
                    ? SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(25, 60, 25, 0),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: upcomingAppointments.length,
                                  itemBuilder: (context, index) {
                                    DateTime date = DateTime.parse(
                                        upcomingAppointments[index]['date']);
                                    var year = date.year;
                                    var month = formatTime(date.month);
                                    var day = formatTime(date.day);
                                    var startHour =
                                        formatTime(convertTime(date.hour));
                                    var startMinute = formatTime(date.minute);
                                    var startMeridiem = getMeridiem(date.hour);
                                    var endHour = formatTime(convertTime(date
                                        .add(const Duration(minutes: 30))
                                        .hour));
                                    var endMinute = formatTime(date
                                        .add(const Duration(minutes: 30))
                                        .minute);
                                    var endMeridiem = getMeridiem(date
                                        .add(const Duration(minutes: 30))
                                        .hour);

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 15),
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            15, 10, 15, 10),
                                        decoration: BoxDecoration(
                                            color: appColors['white'],
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            boxShadow: [
                                              BoxShadow(
                                                  color: appColors['black.25']!,
                                                  offset: const Offset(0, 2),
                                                  blurRadius: 2,
                                                  spreadRadius: 0)
                                            ]),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            FutureBuilder(
                                              future: getData(
                                                  "patients",
                                                  id: upcomingAppointments[index]
                                                      ['patientID']),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.done) {
                                                  var patientData =
                                                      snapshot.data!;
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "${patientData['firstName']}${patientData['middleName'].isNotEmpty ? " ${patientData['middleName']} " : " "}${patientData['lastName']}",
                                                        style: textTheme
                                                            .labelMedium
                                                            ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 5),
                                                        child: Text(
                                                          "${upcomingAppointments[index]['service']}",
                                                          style: textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                  color: appColors[
                                                                      'gray143']),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 5),
                                                        child: Text(
                                                          "${patientData['contactNumber']}",
                                                          style: textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                  color: appColors[
                                                                      'gray143']),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 5),
                                                        child: FutureBuilder(
                                                          future: getData(
                                                            "doctors",
                                                            id: upcomingAppointments[
                                                                    index]
                                                                ['doctorID'],
                                                            field: "name",
                                                          ),
                                                          builder: (context,
                                                              snapshot) {
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
                                                                        BorderRadius.circular(
                                                                            15)),
                                                              );
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                top: 5,
                                                                bottom: 10),
                                                        child: Row(
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .only(
                                                                      right:
                                                                          20),
                                                              child: Text(
                                                                "$month/$day/${year.toString().substring(2, 4)}",
                                                                style: textTheme
                                                                    .bodyMedium
                                                                    ?.copyWith(
                                                                        color: appColors[
                                                                            'gray143']),
                                                              ),
                                                            ),
                                                            Text(
                                                              "$startHour:$startMinute ${startMeridiem.toUpperCase()} - $endHour:$endMinute ${endMeridiem.toUpperCase()}",
                                                              style: textTheme
                                                                  .bodyMedium
                                                                  ?.copyWith(
                                                                      color: appColors[
                                                                          'gray143']),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                } else {
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Container(
                                                        height: 18,
                                                        width: 150,
                                                        decoration: BoxDecoration(
                                                            color: appColors[
                                                                'coolGray'],
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        15)),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 5),
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
                                                            const EdgeInsets
                                                                .only(top: 5),
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
                                                            const EdgeInsets
                                                                .only(top: 5),
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
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 5),
                                                        child: Container(
                                                          height: 16,
                                                          width: 200,
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
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 5),
                                                    child: Container(
                                                      height: 36,
                                                      decoration: BoxDecoration(
                                                        color: appColors[
                                                            'coolGray'],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: TextButton(
                                                        onPressed: () {
                                                          showDismissDialog(
                                                              upcomingAppointments[
                                                                  index]['clinicAppointmentID']);
                                                        },
                                                        child: Text(
                                                          "Dismiss",
                                                          style: textTheme
                                                              .bodyMedium,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 5),
                                                    child: Container(
                                                      height: 36,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            appColors['accent'],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: TextButton(
                                                        onPressed: () {
                                                          showCompleteDialog(
                                                              upcomingAppointments[
                                                                  index]['clinicAppointmentID']);
                                                        },
                                                        child: Text(
                                                          "Complete",
                                                          style: textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                  color: appColors[
                                                                      'white']),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : completedButtonFocus.hasFocus &&
                            completedAppointments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_available_outlined,
                                  color: appColors['gray145'],
                                  size: 77,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 89, right: 89, top: 10),
                                  child: Text(
                                      "No Appointment requests have been submitted yet",
                                      style: textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: appColors['gray145']),
                                      textAlign: TextAlign.center),
                                )
                              ],
                            ),
                          )
                        : completedButtonFocus.hasFocus
                            ? SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 100),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            25, 60, 25, 0),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount:
                                              completedAppointments.length,
                                          itemBuilder: (context, index) {
                                            Map<String, dynamic>
                                                appointmentDetails =
                                                completedAppointments[index];
                                            DateTime date = DateTime.parse(
                                                appointmentDetails['date']);
                                            var year = date.year;
                                            var month = formatTime(date.month);
                                            var day = formatTime(date.day);
                                            var startHour = formatTime(
                                                convertTime(date.hour));
                                            var startMinute =
                                                formatTime(date.minute);
                                            var startMeridiem =
                                                getMeridiem(date.hour);
                                            var endHour = formatTime(
                                                convertTime(date
                                                    .add(const Duration(
                                                        minutes: 30))
                                                    .hour));
                                            var endMinute = formatTime(date
                                                .add(
                                                    const Duration(minutes: 30))
                                                .minute);
                                            var endMeridiem = getMeridiem(date
                                                .add(
                                                    const Duration(minutes: 30))
                                                .hour);

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 15),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        15, 10, 15, 10),
                                                decoration: BoxDecoration(
                                                    color: appColors['white'],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                    boxShadow: [
                                                      BoxShadow(
                                                          color: appColors[
                                                              'black.25']!,
                                                          offset: const Offset(
                                                              0, 2),
                                                          blurRadius: 2,
                                                          spreadRadius: 0)
                                                    ]),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    FutureBuilder(
                                                      future: getData(
                                                          "patients",
                                                          id: completedAppointments[
                                                                  index]
                                                              ['patientID']),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .done) {
                                                          var patientData =
                                                              snapshot.data!;
                                                          return Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Text(
                                                                    "${patientData['firstName']}${patientData['middleName'].isNotEmpty ? " ${patientData['middleName']} " : " "}${patientData['lastName']}",
                                                                    style: textTheme
                                                                        .labelMedium
                                                                        ?.copyWith(
                                                                            fontWeight:
                                                                                FontWeight.w600),
                                                                  ),
                                                                  Text(
                                                                    "Complete",
                                                                    style: textTheme
                                                                        .bodyMedium
                                                                        ?.copyWith(
                                                                            color:
                                                                                appColors['accepted']),
                                                                  ),
                                                                ],
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        top: 5),
                                                                child: Text(
                                                                  "${completedAppointments[index]['service']}",
                                                                  style: textTheme
                                                                      .bodyMedium
                                                                      ?.copyWith(
                                                                          color:
                                                                              appColors['gray143']),
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        top: 5),
                                                                child: Text(
                                                                  "${patientData['contactNumber']}",
                                                                  style: textTheme
                                                                      .bodyMedium
                                                                      ?.copyWith(
                                                                          color:
                                                                              appColors['gray143']),
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        top: 5),
                                                                child:
                                                                    FutureBuilder(
                                                                  future:
                                                                      getData(
                                                                    "doctors",
                                                                    id: completedAppointments[
                                                                            index]
                                                                        [
                                                                        'doctorID'],
                                                                    field:
                                                                        "name",
                                                                  ),
                                                                  builder: (context,
                                                                      snapshot) {
                                                                    if (snapshot
                                                                            .connectionState ==
                                                                        ConnectionState
                                                                            .done) {
                                                                      var name =
                                                                          snapshot
                                                                              .data;

                                                                      return Text(
                                                                        "Dr. $name",
                                                                        style: textTheme
                                                                            .bodyMedium
                                                                            ?.copyWith(color: appColors['gray143']),
                                                                      );
                                                                    } else {
                                                                      return Container(
                                                                        height:
                                                                            16,
                                                                        width:
                                                                            120,
                                                                        decoration: BoxDecoration(
                                                                            color:
                                                                                appColors['coolGray'],
                                                                            borderRadius: BorderRadius.circular(15)),
                                                                      );
                                                                    }
                                                                  },
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        top: 5),
                                                                child: Row(
                                                                  children: [
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                              .only(
                                                                          right:
                                                                              20),
                                                                      child:
                                                                          Text(
                                                                        "$month/$day/${year.toString().substring(2, 4)}",
                                                                        style: textTheme
                                                                            .bodyMedium
                                                                            ?.copyWith(color: appColors['gray143']),
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      "$startHour:$startMinute ${startMeridiem.toUpperCase()} - $endHour:$endMinute ${endMeridiem.toUpperCase()}",
                                                                      style: textTheme
                                                                          .bodyMedium
                                                                          ?.copyWith(
                                                                              color: appColors['gray143']),
                                                                    )
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        } else {
                                                          return Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Container(
                                                                height: 18,
                                                                width: 150,
                                                                decoration: BoxDecoration(
                                                                    color: appColors[
                                                                        'coolGray'],
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            15)),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        top: 5),
                                                                child:
                                                                    Container(
                                                                  height: 16,
                                                                  width: 50,
                                                                  decoration: BoxDecoration(
                                                                      color: appColors[
                                                                          'coolGray'],
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              15)),
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        top: 5),
                                                                child:
                                                                    Container(
                                                                  height: 16,
                                                                  width: 120,
                                                                  decoration: BoxDecoration(
                                                                      color: appColors[
                                                                          'coolGray'],
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              15)),
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        top: 5),
                                                                child:
                                                                    Container(
                                                                  height: 16,
                                                                  width: 110,
                                                                  decoration: BoxDecoration(
                                                                      color: appColors[
                                                                          'coolGray'],
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              15)),
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        top: 5),
                                                                child:
                                                                    Container(
                                                                  height: 16,
                                                                  width: 200,
                                                                  decoration: BoxDecoration(
                                                                      color: appColors[
                                                                          'coolGray'],
                                                                      borderRadius:
                                                                          BorderRadius.circular(
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
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : cancelledButtonFocus.hasFocus &&
                                    cancelledAppointments.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.history,
                                          color: appColors['gray145'],
                                          size: 77,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 89, right: 89, top: 10),
                                          child: Text(
                                              "No Appointments have been completed yet",
                                              style: textTheme.labelMedium
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          appColors['gray145']),
                                              textAlign: TextAlign.center),
                                        )
                                      ],
                                    ),
                                  )
                                : cancelledButtonFocus.hasFocus
                                    ? SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 100),
                                          child: Column(
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        25, 60, 25, 0),
                                                child: ListView.builder(
                                                  shrinkWrap: true,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  itemCount:
                                                      cancelledAppointments
                                                          .length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    Map<String, dynamic>
                                                        appointmentDetails =
                                                        cancelledAppointments[
                                                            index];
                                                    DateTime date =
                                                        DateTime.parse(
                                                            appointmentDetails[
                                                                'date']);
                                                    var year = date.year;
                                                    var month =
                                                        formatTime(date.month);
                                                    var day =
                                                        formatTime(date.day);
                                                    var startHour = formatTime(
                                                        convertTime(date.hour));
                                                    var startMinute =
                                                        formatTime(date.minute);
                                                    var startMeridiem =
                                                        getMeridiem(convertTime(
                                                            date.hour));
                                                    var endHour = formatTime(
                                                        convertTime(date
                                                            .add(const Duration(
                                                                minutes: 30))
                                                            .hour));
                                                    var endMinute = formatTime(
                                                        date
                                                            .add(const Duration(
                                                                minutes: 30))
                                                            .minute);
                                                    var endMeridiem = getMeridiem(
                                                        convertTime(date
                                                            .add(const Duration(
                                                                minutes: 30))
                                                            .hour));

                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              bottom: 15),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                    .fromLTRB(
                                                                15, 10, 15, 10),
                                                        decoration: BoxDecoration(
                                                            color: appColors[
                                                                'white'],
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        15),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                  color: appColors[
                                                                      'black.25']!,
                                                                  offset:
                                                                      const Offset(
                                                                          0, 2),
                                                                  blurRadius: 2,
                                                                  spreadRadius:
                                                                      0)
                                                            ]),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            FutureBuilder(
                                                              future: getData(
                                                                  "patients",
                                                                  id: cancelledAppointments[
                                                                          index]
                                                                      [
                                                                      'patientID']),
                                                              builder: (context,
                                                                  snapshot) {
                                                                if (snapshot
                                                                        .connectionState ==
                                                                    ConnectionState
                                                                        .done) {
                                                                  var patientData =
                                                                      snapshot
                                                                          .data!;
                                                                  return Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text(
                                                                            "${patientData['firstName']}${patientData['middleName'].isNotEmpty ? " ${patientData['middleName']} " : " "}${patientData['lastName']}",
                                                                            style:
                                                                                textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                                                                          ),
                                                                          Text(
                                                                            "${cancelledAppointments[index]['status'].substring(0, 1).toUpperCase()}${cancelledAppointments[index]['status'].substring(1)}",
                                                                            style:
                                                                                textTheme.bodyMedium?.copyWith(color: appColors['accent']),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.only(top: 5),
                                                                        child:
                                                                            Text(
                                                                          "${cancelledAppointments[index]['service']}",
                                                                          style: textTheme
                                                                              .bodyMedium
                                                                              ?.copyWith(color: appColors['gray143']),
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.only(top: 5),
                                                                        child:
                                                                            Text(
                                                                          "${patientData['contactNumber']}",
                                                                          style: textTheme
                                                                              .bodyMedium
                                                                              ?.copyWith(color: appColors['gray143']),
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.only(top: 5),
                                                                        child:
                                                                            FutureBuilder(
                                                                          future:
                                                                              getData(
                                                                            "doctors",
                                                                            id: cancelledAppointments[index]['doctorID'],
                                                                            field:
                                                                                "name",
                                                                          ),
                                                                          builder:
                                                                              (context, snapshot) {
                                                                            if (snapshot.connectionState ==
                                                                                ConnectionState.done) {
                                                                              var name = snapshot.data;

                                                                              return Text(
                                                                                "Dr. $name",
                                                                                style: textTheme.bodyMedium?.copyWith(color: appColors['gray143']),
                                                                              );
                                                                            } else {
                                                                              return Container(
                                                                                height: 16,
                                                                                width: 120,
                                                                                decoration: BoxDecoration(color: appColors['coolGray'], borderRadius: BorderRadius.circular(15)),
                                                                              );
                                                                            }
                                                                          },
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.only(top: 5),
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Padding(
                                                                              padding: const EdgeInsets.only(right: 20),
                                                                              child: Text(
                                                                                "$month/$day/${year.toString().substring(2, 4)}",
                                                                                style: textTheme.bodyMedium?.copyWith(color: appColors['gray143']),
                                                                              ),
                                                                            ),
                                                                            Text(
                                                                              "$startHour:$startMinute ${startMeridiem.toUpperCase()} - $endHour:$endMinute ${endMeridiem.toUpperCase()}",
                                                                              style: textTheme.bodyMedium?.copyWith(color: appColors['gray143']),
                                                                            )
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  );
                                                                } else {
                                                                  return Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Container(
                                                                        height:
                                                                            18,
                                                                        width:
                                                                            150,
                                                                        decoration: BoxDecoration(
                                                                            color:
                                                                                appColors['coolGray'],
                                                                            borderRadius: BorderRadius.circular(15)),
                                                                      ),
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.only(top: 5),
                                                                        child:
                                                                            Container(
                                                                          height:
                                                                              16,
                                                                          width:
                                                                              50,
                                                                          decoration: BoxDecoration(
                                                                              color: appColors['coolGray'],
                                                                              borderRadius: BorderRadius.circular(15)),
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.only(top: 5),
                                                                        child:
                                                                            Container(
                                                                          height:
                                                                              16,
                                                                          width:
                                                                              120,
                                                                          decoration: BoxDecoration(
                                                                              color: appColors['coolGray'],
                                                                              borderRadius: BorderRadius.circular(15)),
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.only(top: 5),
                                                                        child:
                                                                            Container(
                                                                          height:
                                                                              16,
                                                                          width:
                                                                              110,
                                                                          decoration: BoxDecoration(
                                                                              color: appColors['coolGray'],
                                                                              borderRadius: BorderRadius.circular(15)),
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.only(top: 5),
                                                                        child:
                                                                            Container(
                                                                          height:
                                                                              16,
                                                                          width:
                                                                              200,
                                                                          decoration: BoxDecoration(
                                                                              color: appColors['coolGray'],
                                                                              borderRadius: BorderRadius.circular(15)),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  );
                                                                }
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 70, left: 30, right: 30),
                child: Container(
                  height: 32,
                  width: deviceWidth,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: appColors['coolGray'],
                      borderRadius: BorderRadius.circular(5)),
                  child: Row(
                    children: [
                      Focus(
                        focusNode: upcomingButtonFocus,
                        onFocusChange: (hasFocus) async {
                          setState(() {});
                        },
                        child: GestureDetector(
                          onTap: () {
                            upcomingButtonFocus.requestFocus();
                          },
                          child: Stack(
                            children: [
                              Container(
                                height: double.maxFinite,
                                width: (deviceWidth - 68) / 3,
                                decoration: BoxDecoration(
                                    color: upcomingButtonFocus.hasFocus
                                        ? appColors['accent']
                                        : appColors['coolGray'],
                                    borderRadius: BorderRadius.circular(5)),
                                child: Center(
                                  child: Text(
                                    "Upcoming",
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: upcomingButtonFocus.hasFocus
                                          ? appColors['white']
                                          : appColors['gray143'],
                                    ),
                                  ),
                                ),
                              ),
                              Visibility(
                                visible: upcomingAppointments.isNotEmpty,
                                child: Positioned(
                                  right: 5,
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: appColors['accent']),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Focus(
                        focusNode: completedButtonFocus,
                        onFocusChange: (hasFocus) async {
                          setState(() {});
                        },
                        child: GestureDetector(
                          onTap: () async {
                            completedButtonFocus.requestFocus();
                          },
                          child: Stack(
                            children: [
                              Container(
                                height: double.maxFinite,
                                width: (deviceWidth - 68) / 3,
                                decoration: BoxDecoration(
                                    color: completedButtonFocus.hasFocus
                                        ? appColors['accent']
                                        : appColors['coolGray'],
                                    borderRadius: BorderRadius.circular(5)),
                                child: Center(
                                  child: Text(
                                    "Completed",
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: completedButtonFocus.hasFocus
                                          ? appColors['white']
                                          : appColors['gray143'],
                                    ),
                                  ),
                                ),
                              ),
                              Visibility(
                                visible: completedAppointments.isNotEmpty,
                                child: Positioned(
                                  right: 5,
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: appColors['accent']),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Focus(
                        focusNode: cancelledButtonFocus,
                        onFocusChange: (hasFocus) async {
                          setState(() {});
                        },
                        child: GestureDetector(
                          onTap: () {
                            cancelledButtonFocus.requestFocus();
                          },
                          child: Container(
                            height: double.maxFinite,
                            width: (deviceWidth - 68) / 3,
                            decoration: BoxDecoration(
                                color: cancelledButtonFocus.hasFocus
                                    ? appColors['accent']
                                    : appColors['coolGray'],
                                borderRadius: BorderRadius.circular(5)),
                            child: Center(
                              child: Text(
                                "Cancelled",
                                style: textTheme.bodyMedium?.copyWith(
                                  color: cancelledButtonFocus.hasFocus
                                      ? appColors['white']
                                      : appColors['gray143'],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 115,
              right: 30,
              child: ElevatedButton(
                onPressed: () async {
                  var patientsData = await getPatientTokens(accountType: "clinic");
                  for (var patientData in patientsData) {
                    var title = "Appointment Reminder";
                    var body =
                        "Hey there! Looks like your appointment might start a bit late. Please wait patiently for your time, thank you!";

                    var notificationID = await addNotification(
                        uid: patientData['uid'], title: title, body: body);
                    for (var token in patientData['token']) {
                      sendPushNotification(token, title, body, notificationID);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    )),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 9),
                        child: Text(
                          "Announce\n Delay",
                          style: textTheme.bodyMedium
                              ?.copyWith(color: appColors['white']),
                        ),
                      ),
                      Icon(
                        Icons.campaign_outlined,
                        color: appColors['white'],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
