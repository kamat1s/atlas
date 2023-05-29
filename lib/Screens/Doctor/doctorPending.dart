import 'dart:developer';

import 'package:atlas/Screens/Appointment/appointmentReview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../global.dart';
import '../../query.dart';
import '../../styles.dart';
import '../../utils.dart';

class DoctorPending extends StatefulWidget {
  const DoctorPending({Key? key}) : super(key: key);

  @override
  State<DoctorPending> createState() => _DoctorPendingState();
}

class _DoctorPendingState extends State<DoctorPending> {
  List pendingAppointments = [];

  @override
  void initState() {
    super.initState();
  }

  final Stream<QuerySnapshot> appointmentStream = FirebaseFirestore.instance
      .collection('independentDoctorAppointments')
      .where('independentDoctorID', isEqualTo: userData["independentDoctorID"])
      .orderBy('date', descending: true)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<QuerySnapshot>(
      stream: appointmentStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.expand();
        }

        pendingAppointments.clear();

        for (var appointments in snapshot.data!.docs) {
          Map<String, dynamic> appointmentDetails =
              appointments.data()! as Map<String, dynamic>;

          appointmentDetails['ID'] = appointments.id;
          if (appointmentDetails['status'] == 'pending' ||
              appointmentDetails['status'] == 'rescheduling' ||
              appointmentDetails['status'] == 'cancellation') {
            pendingAppointments.add(appointmentDetails);
          }
        }

        return pendingAppointments.isEmpty
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
                      padding:
                          const EdgeInsets.only(left: 89, right: 89, top: 10),
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
            : SizedBox(
                height: double.maxFinite,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(25, 60, 25, 0),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pendingAppointments.length,
                            itemBuilder: (context, index) {
                              DateTime date = DateTime.parse(
                                  pendingAppointments[index]['date']);
                              var year = date.year;
                              var month = formatTime(date.month);
                              var day = formatTime(date.day);
                              var startHour =
                                  formatTime(convertTime(date.hour));
                              var startMinute = formatTime(date.minute);
                              var startMeridiem =
                                  getMeridiem(convertTime(date.hour));
                              var endHour = formatTime(convertTime(
                                  date.add(const Duration(minutes: 30)).hour));
                              var endMinute = formatTime(
                                  date.add(const Duration(minutes: 30)).minute);
                              var endMeridiem = getMeridiem(convertTime(
                                  date.add(const Duration(minutes: 30)).hour));

                              var status = pendingAppointments[index]
                                          ['status'] ==
                                      "pending"
                                  ? "New Request"
                                  : pendingAppointments[index]['status'] ==
                                          "rescheduling"
                                      ? "Rescheduling"
                                      : "Cancellation";
                              var color = pendingAppointments[index]
                                          ['status'] ==
                                      "pending"
                                  ? appColors['accepted']
                                  : pendingAppointments[index]['status'] ==
                                          "rescheduling"
                                      ? appColors['pending']
                                      : appColors['accent'];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(15, 10, 15, 10),
                                  decoration: BoxDecoration(
                                      color: appColors['white'],
                                      borderRadius: BorderRadius.circular(15),
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
                                        future: getData("patients",
                                            id: pendingAppointments[index]
                                                ['patientID']),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.done) {
                                            var patientData = snapshot.data!;

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
                                                      "${patientData['firstName']}${patientData['middleName'].isNotEmpty ? " ${patientData['middleName']} " : " "}${patientData['lastName']}",
                                                      style: textTheme
                                                          .labelMedium
                                                          ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                    ),
                                                    Text(status,
                                                        style: textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                                color: color)),
                                                  ],
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 5),
                                                  child: Text(
                                                    "${pendingAppointments[index]['service']}",
                                                    style: textTheme.bodyMedium
                                                        ?.copyWith(
                                                            color: appColors[
                                                                'gray143']),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 5),
                                                  child: Text(
                                                    "${patientData['contactNumber']}",
                                                    style: textTheme.bodyMedium
                                                        ?.copyWith(
                                                            color: appColors[
                                                                'gray143']),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 5, bottom: 10),
                                                  child: Row(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                right: 20),
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
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  height: 18,
                                                  width: 150,
                                                  decoration: BoxDecoration(
                                                      color:
                                                          appColors['coolGray'],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15)),
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
                                                                .circular(15)),
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
                                                                .circular(15)),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 5, bottom: 5),
                                                  child: Container(
                                                    height: 16,
                                                    width: 200,
                                                    decoration: BoxDecoration(
                                                        color: appColors[
                                                            'coolGray'],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15)),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 5),
                                        child: Container(
                                          height: 36,
                                          width: double.maxFinite,
                                          decoration: BoxDecoration(
                                            color: appColors['accent'],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AppointmentReview(
                                                          appointmentDetails:
                                                              pendingAppointments[
                                                                  index], accountType: "independentDoctor"),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              "Review",
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                      color:
                                                          appColors['white']),
                                            ),
                                          ),
                                        ),
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
                ),
              );
      },
    );
  }
}
