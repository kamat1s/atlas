import 'dart:developer';

import 'package:atlas/Screens/Appointment/rescheduleAppointment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import '../../global.dart';
import '../../query.dart';
import '../../styles.dart';
import '../../utils.dart';
import '../Appointment/cancelAppointment.dart';

class Appointments extends StatefulWidget {
  const Appointments({Key? key}) : super(key: key);

  @override
  State<Appointments> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<Appointments> {
  FocusNode upcomingButtonFocus = FocusNode();
  FocusNode pendingButtonFocus = FocusNode();
  FocusNode historyButtonFocus = FocusNode();

  List upcomingAppointments = [];
  List pendingAppointments = [];
  List pastAppointments = [];

  @override
  void initState() {
    pendingButtonFocus.requestFocus();

    if (!FirebaseAuth.instance.currentUser!.isAnonymous) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        showReminder();
      });
    }

    super.initState();
  }

  Future<void> showReminder() async {
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
                    Icons.alarm,
                    size: 84,
                    color: appColors['accent'],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Text(
                      "Hey ${userData['firstName']}",
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                        "Just a Reminder, Please be at the Clinic at least 30 Minutes ahead of the Scheduled Appointment.",
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

  final Stream<QuerySnapshot> clinicAppointmentStream = isAnonymous
      ? const Stream.empty()
      : FirebaseFirestore.instance
          .collection('clinicAppointments')
          .where("patientID", isEqualTo: userData['patientID'])
          .orderBy('date', descending: true)
          .snapshots();

  final Stream<QuerySnapshot> doctorAppointmentStream = isAnonymous
      ? const Stream.empty()
      : FirebaseFirestore.instance
          .collection('independentDoctorAppointments')
          .where("patientID", isEqualTo: userData['patientID'])
          .orderBy('date', descending: true)
          .snapshots();

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

        if (!isAnonymous) {
          upcomingAppointments.clear();
          pendingAppointments.clear();
          pastAppointments.clear();

          for (var appointments in snapshot.data!.docs) {
            Map<String, dynamic> appointmentDetails =
                appointments.data()! as Map<String, dynamic>;

            appointmentDetails['appointmentType'] = "clinicAppointment";

            if (appointmentDetails['status'] == 'accepted') {
              upcomingAppointments.add(appointmentDetails);
            } else if (appointmentDetails['status'] == 'pending' ||
                appointmentDetails['status'] == 'cancellation' ||
                appointmentDetails['status'] == 'rescheduling') {
              pendingAppointments.add(appointmentDetails);
            } else if (appointmentDetails['status'] == 'cancelled' ||
                appointmentDetails['status'] == 'done' ||
                appointmentDetails['status'] == 'rejected') {
              pastAppointments.add(appointmentDetails);
            }
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: doctorAppointmentStream,
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Text('Something went wrong');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.expand();
            }

            if (!isAnonymous) {
              upcomingAppointments.removeWhere((appointment) =>
                  appointment['appointmentType'] == 'doctorAppointment');
              pendingAppointments.removeWhere((appointment) =>
                  appointment['appointmentType'] == 'doctorAppointment');
              pastAppointments.removeWhere((appointment) =>
                  appointment['appointmentType'] == 'doctorAppointment');

              for (var appointments in snapshot.data!.docs) {
                Map<String, dynamic> appointmentDetails =
                    appointments.data()! as Map<String, dynamic>;

                appointmentDetails['appointmentType'] = "doctorAppointment";

                if (appointmentDetails['status'] == 'accepted') {
                  upcomingAppointments.add(appointmentDetails);
                } else if (appointmentDetails['status'] == 'pending' ||
                    appointmentDetails['status'] == 'cancellation' ||
                    appointmentDetails['status'] == 'rescheduling') {
                  pendingAppointments.add(appointmentDetails);
                } else if (appointmentDetails['status'] == 'cancelled' ||
                    appointmentDetails['status'] == 'done' ||
                    appointmentDetails['status'] == 'rejected') {
                  pastAppointments.add(appointmentDetails);
                }
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
                                    textAlign: TextAlign.center))
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
                                    padding: const EdgeInsets.fromLTRB(
                                        25, 60, 25, 0),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: upcomingAppointments.length,
                                      itemBuilder: (context, index) {
                                        String appointmentType =
                                            upcomingAppointments[index]
                                                ['appointmentType'];
                                        DateTime date = DateTime.parse(
                                            upcomingAppointments[index]
                                                ['date']);
                                        var year = date.year;
                                        var month = formatTime(date.month);
                                        var day = formatTime(date.day);
                                        var startHour =
                                            formatTime(convertTime(date.hour));
                                        var startMinute =
                                            formatTime(date.minute);
                                        var startMeridiem =
                                            getMeridiem(convertTime(date.hour));
                                        var endHour = formatTime(convertTime(
                                            date
                                                .add(
                                                    const Duration(minutes: 30))
                                                .hour));
                                        var endMinute = formatTime(date
                                            .add(const Duration(minutes: 30))
                                            .minute);
                                        var endMeridiem = getMeridiem(
                                            convertTime(date
                                                .add(
                                                    const Duration(minutes: 30))
                                                .hour));

                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 15),
                                          child: Container(
                                            padding: const EdgeInsets.fromLTRB(
                                                15, 10, 15, 10),
                                            height: 180,
                                            decoration: BoxDecoration(
                                                color: appColors['white'],
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: appColors[
                                                          'black.25']!,
                                                      offset:
                                                          const Offset(0, 2),
                                                      blurRadius: 2,
                                                      spreadRadius: 0)
                                                ]),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                appointmentType ==
                                                        'clinicAppointment'
                                                    ? FutureBuilder(
                                                        future: getData(
                                                            "clinics",
                                                            id: upcomingAppointments[
                                                                    index]
                                                                ['clinicID'],
                                                            field:
                                                                "clinicName"),
                                                        builder: (context,
                                                            snapshot) {
                                                          if (snapshot
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .done) {
                                                            var clinicName =
                                                                snapshot.data!;
                                                            return Text(
                                                              "$clinicName",
                                                              style: textTheme
                                                                  .labelMedium
                                                                  ?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600),
                                                            );
                                                          } else {
                                                            return Container(
                                                              height: 16,
                                                              width: 104,
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
                                                      )
                                                    : FutureBuilder(
                                                        future: getData(
                                                          "independentDoctors",
                                                          id: upcomingAppointments[
                                                                  index][
                                                              'independentDoctorID'],
                                                        ),
                                                        builder: (context,
                                                            snapshot) {
                                                          if (snapshot
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .done) {
                                                            var doctorInfo =
                                                                snapshot.data!;
                                                            return Text(
                                                              "Dr. ${doctorInfo['lastName']}",
                                                              style: textTheme
                                                                  .labelMedium
                                                                  ?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600),
                                                            );
                                                          } else {
                                                            return Container(
                                                              height: 16,
                                                              width: 104,
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
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 5),
                                                  child: Text(
                                                    "${upcomingAppointments[index]['service']}",
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
                                                  child: appointmentType ==
                                                          'clinicAppointment'
                                                      ? FutureBuilder(
                                                          future: getData(
                                                            "clinics",
                                                            id: upcomingAppointments[
                                                                    index]
                                                                ['clinicID'],
                                                            field: "address",
                                                          ),
                                                          builder: (context,
                                                              snapshot) {
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
                                                                              color: appColors['gray143']),
                                                                    );
                                                                  } else {
                                                                    return Container(
                                                                      height:
                                                                          16,
                                                                      width:
                                                                          deviceWidth,
                                                                      decoration: BoxDecoration(
                                                                          color: appColors[
                                                                              'coolGray'],
                                                                          borderRadius:
                                                                              BorderRadius.circular(15)),
                                                                    );
                                                                  }
                                                                },
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
                                                        )
                                                      : FutureBuilder(
                                                          future: getData(
                                                            "independentDoctors",
                                                            id: upcomingAppointments[
                                                                    index][
                                                                'independentDoctorID'],
                                                          ),
                                                          builder: (context,
                                                              snapshot) {
                                                            if (snapshot
                                                                    .connectionState ==
                                                                ConnectionState
                                                                    .done) {
                                                              var doctorInfo =
                                                                  snapshot.data;

                                                              var address =
                                                                  doctorInfo[
                                                                      'address'];

                                                              return doctorInfo[
                                                                          'clinicName']
                                                                      .isNotEmpty
                                                                  ? Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Text(
                                                                          "${doctorInfo['clinicName']}",
                                                                          style: textTheme
                                                                              .bodyMedium
                                                                              ?.copyWith(color: appColors['gray143']),
                                                                        ),
                                                                        Padding(
                                                                          padding:
                                                                              const EdgeInsets.only(top: 5),
                                                                          child:
                                                                              FutureBuilder(
                                                                            future:
                                                                                placemarkFromCoordinates(address['latitude'], address['longitude']),
                                                                            builder:
                                                                                (context, snapshot) {
                                                                              if (snapshot.connectionState == ConnectionState.done) {
                                                                                var address = snapshot.data!.first;
                                                                                return Text(
                                                                                  "${address.street}. ${address.subLocality}, ${address.locality}, ${address.administrativeArea}",
                                                                                  style: textTheme.bodyMedium?.copyWith(color: appColors['gray143']),
                                                                                );
                                                                              } else {
                                                                                return Container(
                                                                                  height: 16,
                                                                                  width: deviceWidth,
                                                                                  decoration: BoxDecoration(color: appColors['coolGray'], borderRadius: BorderRadius.circular(15)),
                                                                                );
                                                                              }
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    )
                                                                  : Text(
                                                                      "Online consultation",
                                                                      style: textTheme
                                                                          .bodyMedium
                                                                          ?.copyWith(
                                                                              color: appColors['gray143']),
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
                                                        ),
                                                ),
                                                appointmentType ==
                                                        'clinicAppointment'
                                                    ? Padding(
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
                                                                width: 100,
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
                                                      )
                                                    : const SizedBox.shrink(),
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
                                                const Spacer(),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(right: 5),
                                                        child: Container(
                                                          height: 36,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: appColors[
                                                                'coolGray'],
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                          child: TextButton(
                                                            onPressed:
                                                                () async {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          CancelAppointment(
                                                                    appointmentDetails:
                                                                        upcomingAppointments[
                                                                            index],
                                                                    appointmentType:
                                                                        appointmentType,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            child: Text(
                                                              "Cancel",
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
                                                            const EdgeInsets
                                                                .only(left: 5),
                                                        child: Container(
                                                          height: 36,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: appColors[
                                                                'accent'],
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                          child: TextButton(
                                                            onPressed: () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (context) => Reschedule(
                                                                      appointmentDetails:
                                                                          upcomingAppointments[
                                                                              index],
                                                                      appointmentType:
                                                                          appointmentType),
                                                                ),
                                                              );
                                                            },
                                                            child: Text(
                                                              "Reschedule",
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
                        : pendingButtonFocus.hasFocus &&
                                pendingAppointments.isEmpty
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
                                          style: textTheme.labelMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  color: appColors['gray145']),
                                          textAlign: TextAlign.center),
                                    )
                                  ],
                                ),
                              )
                            : pendingButtonFocus.hasFocus
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 100),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            25, 60, 25, 0),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: pendingAppointments.length,
                                          itemBuilder: (context, index) {
                                            var appointmentType =
                                                pendingAppointments[index]
                                                    ['appointmentType'];
                                            Map<String, dynamic>
                                                appointmentDetails =
                                                pendingAppointments[index];
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
                                                height: 200,
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
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        appointmentType ==
                                                                'clinicAppointment'
                                                            ? FutureBuilder(
                                                                future: getData(
                                                                    "clinics",
                                                                    id: appointmentDetails[
                                                                        'clinicID'],
                                                                    field:
                                                                        "clinicName"),
                                                                builder: (context,
                                                                    snapshot) {
                                                                  if (snapshot
                                                                          .connectionState ==
                                                                      ConnectionState
                                                                          .done) {
                                                                    var clinicName =
                                                                        snapshot
                                                                            .data!;
                                                                    return Text(
                                                                      "$clinicName",
                                                                      style: textTheme
                                                                          .labelMedium
                                                                          ?.copyWith(
                                                                              fontWeight: FontWeight.w600),
                                                                    );
                                                                  } else {
                                                                    return Container(
                                                                      height:
                                                                          16,
                                                                      width:
                                                                          104,
                                                                      decoration: BoxDecoration(
                                                                          color: appColors[
                                                                              'coolGray'],
                                                                          borderRadius:
                                                                              BorderRadius.circular(15)),
                                                                    );
                                                                  }
                                                                },
                                                              )
                                                            : FutureBuilder(
                                                                future: getData(
                                                                  "independentDoctors",
                                                                  id: pendingAppointments[
                                                                          index]
                                                                      [
                                                                      'independentDoctorID'],
                                                                ),
                                                                builder: (context,
                                                                    snapshot) {
                                                                  if (snapshot
                                                                          .connectionState ==
                                                                      ConnectionState
                                                                          .done) {
                                                                    var doctorInfo =
                                                                        snapshot
                                                                            .data!;
                                                                    return Text(
                                                                      "Dr. ${doctorInfo['lastName']}",
                                                                      style: textTheme
                                                                          .labelMedium
                                                                          ?.copyWith(
                                                                              fontWeight: FontWeight.w600),
                                                                    );
                                                                  } else {
                                                                    return Container(
                                                                      height:
                                                                          16,
                                                                      width:
                                                                          104,
                                                                      decoration: BoxDecoration(
                                                                          color: appColors[
                                                                              'coolGray'],
                                                                          borderRadius:
                                                                              BorderRadius.circular(15)),
                                                                    );
                                                                  }
                                                                },
                                                              ),
                                                        Text(
                                                          "${pendingAppointments[index]['status'].substring(0, 1).toUpperCase()}${pendingAppointments[index]['status'].substring(1)}",
                                                          style: textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: appColors[
                                                                      'gray143']),
                                                        )
                                                      ],
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 5),
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
                                                              top: 5),
                                                      child: appointmentType ==
                                                              'clinicAppointment'
                                                          ? FutureBuilder(
                                                              future: getData(
                                                                "clinics",
                                                                id: appointmentDetails[
                                                                    'clinicID'],
                                                                field:
                                                                    "address",
                                                              ),
                                                              builder: (context,
                                                                  snapshot) {
                                                                if (snapshot
                                                                        .connectionState ==
                                                                    ConnectionState
                                                                        .done) {
                                                                  var address =
                                                                      snapshot
                                                                          .data;

                                                                  return FutureBuilder(
                                                                    future: placemarkFromCoordinates(
                                                                        address[
                                                                            'latitude'],
                                                                        address[
                                                                            'longitude']),
                                                                    builder:
                                                                        (context,
                                                                            snapshot) {
                                                                      if (snapshot
                                                                              .connectionState ==
                                                                          ConnectionState
                                                                              .done) {
                                                                        var address = snapshot
                                                                            .data!
                                                                            .first;
                                                                        return Text(
                                                                          "${address.street}. ${address.subLocality}, ${address.locality}, ${address.administrativeArea}",
                                                                          style: textTheme
                                                                              .bodyMedium
                                                                              ?.copyWith(color: appColors['gray143']),
                                                                        );
                                                                      } else {
                                                                        return Container(
                                                                          height:
                                                                              16,
                                                                          width:
                                                                              deviceWidth,
                                                                          decoration: BoxDecoration(
                                                                              color: appColors['coolGray'],
                                                                              borderRadius: BorderRadius.circular(15)),
                                                                        );
                                                                      }
                                                                    },
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
                                                                            BorderRadius.circular(15)),
                                                                  );
                                                                }
                                                              },
                                                            )
                                                          : FutureBuilder(
                                                              future: getData(
                                                                "independentDoctors",
                                                                id: pendingAppointments[
                                                                        index][
                                                                    'independentDoctorID'],
                                                              ),
                                                              builder: (context,
                                                                  snapshot) {
                                                                if (snapshot
                                                                        .connectionState ==
                                                                    ConnectionState
                                                                        .done) {
                                                                  var doctorInfo =
                                                                      snapshot
                                                                          .data;

                                                                  var address =
                                                                      doctorInfo[
                                                                          'address'];

                                                                  return doctorInfo[
                                                                              'clinicName']
                                                                          .isNotEmpty
                                                                      ? Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Text(
                                                                              "${doctorInfo['clinicName']}",
                                                                              style: textTheme.bodyMedium?.copyWith(color: appColors['gray143']),
                                                                            ),
                                                                            Padding(
                                                                              padding: const EdgeInsets.only(top: 5),
                                                                              child: FutureBuilder(
                                                                                future: placemarkFromCoordinates(address['latitude'], address['longitude']),
                                                                                builder: (context, snapshot) {
                                                                                  if (snapshot.connectionState == ConnectionState.done) {
                                                                                    var address = snapshot.data!.first;
                                                                                    return Text(
                                                                                      "${address.street}. ${address.subLocality}, ${address.locality}, ${address.administrativeArea}",
                                                                                      style: textTheme.bodyMedium?.copyWith(color: appColors['gray143']),
                                                                                    );
                                                                                  } else {
                                                                                    return Container(
                                                                                      height: 16,
                                                                                      width: deviceWidth,
                                                                                      decoration: BoxDecoration(color: appColors['coolGray'], borderRadius: BorderRadius.circular(15)),
                                                                                    );
                                                                                  }
                                                                                },
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        )
                                                                      : Text(
                                                                          "Online consultation",
                                                                          style: textTheme
                                                                              .bodyMedium
                                                                              ?.copyWith(color: appColors['gray143']),
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
                                                                            BorderRadius.circular(15)),
                                                                  );
                                                                }
                                                              },
                                                            ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 5),
                                                      child: appointmentType ==
                                                              'clinicAppointment'
                                                          ? FutureBuilder(
                                                              future: getData(
                                                                "doctors",
                                                                id: appointmentDetails[
                                                                    'doctorID'],
                                                                field: "name",
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
                                                                        ?.copyWith(
                                                                            color:
                                                                                appColors['gray143']),
                                                                  );
                                                                } else {
                                                                  return Container(
                                                                    height: 16,
                                                                    width: 100,
                                                                    decoration: BoxDecoration(
                                                                        color: appColors[
                                                                            'coolGray'],
                                                                        borderRadius:
                                                                            BorderRadius.circular(15)),
                                                                  );
                                                                }
                                                              },
                                                            )
                                                          : const SizedBox
                                                              .shrink(),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 5,
                                                              bottom: 10),
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
                                                    const Spacer(),
                                                    Container(
                                                      height: 36,
                                                      width: deviceWidth,
                                                      decoration: BoxDecoration(
                                                        color: appColors[
                                                            'coolGray'],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: TextButton(
                                                        onPressed: () async {
                                                          var accountType =
                                                              appointmentType ==
                                                                      "clinicAppointment"
                                                                  ? "clinic"
                                                                  : "independentDoctor";

                                                          var UID = await getData(
                                                              "${accountType}s",
                                                              id: pendingAppointments[
                                                                      index][
                                                                  '${accountType}ID'],
                                                              field: "uid");

                                                          if (appointmentDetails[
                                                                  'status'] ==
                                                              'pending') {
                                                            showPendingCancellationDialog(
                                                                UID,
                                                                accountType,
                                                                index);
                                                          } else if (appointmentDetails[
                                                                  'status'] ==
                                                              'cancellation') {
                                                            showCancellationDialog(
                                                                UID,
                                                                accountType,
                                                                index);
                                                          } else {
                                                            showReschedulingCancellationDialog(
                                                                UID,
                                                                accountType,
                                                                index);
                                                          }
                                                        },
                                                        child: Text(
                                                          "Cancel",
                                                          style: textTheme
                                                              .bodyMedium,
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
                                    ),
                                  )
                                : historyButtonFocus.hasFocus &&
                                        pastAppointments.isEmpty
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
                                                          color: appColors[
                                                              'gray145']),
                                                  textAlign: TextAlign.center),
                                            )
                                          ],
                                        ),
                                      )
                                    : historyButtonFocus.hasFocus
                                        ? SingleChildScrollView(
                                            scrollDirection: Axis.vertical,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 100),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets
                                                            .fromLTRB(
                                                        25, 60, 25, 0),
                                                    child: ListView.builder(
                                                      shrinkWrap: true,
                                                      physics:
                                                          const NeverScrollableScrollPhysics(),
                                                      itemCount:
                                                          pastAppointments
                                                              .length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        String appointmentType =
                                                            pastAppointments[
                                                                    index][
                                                                'appointmentType'];
                                                        Map<String, dynamic>
                                                            appointmentDetails =
                                                            pastAppointments[
                                                                index];
                                                        DateTime date =
                                                            DateTime.parse(
                                                                appointmentDetails[
                                                                    'date']);
                                                        var year = date.year;
                                                        var month = formatTime(
                                                            date.month);
                                                        var day = formatTime(
                                                            date.day);
                                                        var startHour =
                                                            formatTime(
                                                                convertTime(
                                                                    date.hour));
                                                        var startMinute =
                                                            formatTime(
                                                                date.minute);
                                                        var startMeridiem =
                                                            getMeridiem(
                                                                convertTime(
                                                                    date.hour));
                                                        var endHour = formatTime(
                                                            convertTime(date
                                                                .add(
                                                                    const Duration(
                                                                        minutes:
                                                                            30))
                                                                .hour));
                                                        var endMinute =
                                                            formatTime(date
                                                                .add(
                                                                    const Duration(
                                                                        minutes:
                                                                            30))
                                                                .minute);
                                                        var endMeridiem =
                                                            getMeridiem(
                                                                convertTime(date
                                                                    .add(const Duration(
                                                                        minutes:
                                                                            30))
                                                                    .hour));

                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  bottom: 15),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                        .fromLTRB(
                                                                    15,
                                                                    10,
                                                                    15,
                                                                    10),
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
                                                                          const Offset(0,
                                                                              2),
                                                                      blurRadius:
                                                                          2,
                                                                      spreadRadius:
                                                                          0)
                                                                ]),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                appointmentType ==
                                                                        'clinicAppointment'
                                                                    ? FutureBuilder(
                                                                        future: getData(
                                                                            "clinics",
                                                                            id: appointmentDetails[
                                                                                'clinicID'],
                                                                            field:
                                                                                "clinicName"),
                                                                        builder:
                                                                            (context,
                                                                                snapshot) {
                                                                          if (snapshot.connectionState ==
                                                                              ConnectionState.done) {
                                                                            var clinicName =
                                                                                snapshot.data!;
                                                                            return Row(
                                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Text(
                                                                                  "$clinicName",
                                                                                  style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                                                                                ),
                                                                                Text(
                                                                                  "${appointmentDetails['status'].substring(0, 1).toUpperCase()}${appointmentDetails['status'].substring(1, appointmentDetails['status'].length)}",
                                                                                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: appColors['gray143']),
                                                                                )
                                                                              ],
                                                                            );
                                                                          } else {
                                                                            return Row(
                                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Container(
                                                                                  height: 16,
                                                                                  width: 104,
                                                                                  decoration: BoxDecoration(color: appColors['coolGray'], borderRadius: BorderRadius.circular(15)),
                                                                                ),
                                                                                Container(
                                                                                  height: 15,
                                                                                  width: 60,
                                                                                  decoration: BoxDecoration(color: appColors['coolGray'], borderRadius: BorderRadius.circular(15)),
                                                                                )
                                                                              ],
                                                                            );
                                                                          }
                                                                        },
                                                                      )
                                                                    : FutureBuilder(
                                                                        future:
                                                                            getData(
                                                                          "independentDoctors",
                                                                          id: pastAppointments[index]
                                                                              [
                                                                              'independentDoctorID'],
                                                                        ),
                                                                        builder:
                                                                            (context,
                                                                                snapshot) {
                                                                          if (snapshot.connectionState ==
                                                                              ConnectionState.done) {
                                                                            var doctorInfo =
                                                                                snapshot.data!;
                                                                            return Row(
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Text(
                                                                                  "Dr. ${doctorInfo['lastName']}",
                                                                                  style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                                                                                ),
                                                                                Text(
                                                                                  "${appointmentDetails['status'].substring(0, 1).toUpperCase()}${appointmentDetails['status'].substring(1, appointmentDetails['status'].length)}",
                                                                                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: appColors['gray143']),
                                                                                )
                                                                              ],
                                                                            );
                                                                          } else {
                                                                            return Container(
                                                                              height: 16,
                                                                              width: 104,
                                                                              decoration: BoxDecoration(color: appColors['coolGray'], borderRadius: BorderRadius.circular(15)),
                                                                            );
                                                                          }
                                                                        },
                                                                      ),
                                                                Padding(
                                                                  padding: const EdgeInsets
                                                                          .only(
                                                                      top: 5),
                                                                  child: Text(
                                                                    "${appointmentDetails['service']}",
                                                                    style: textTheme
                                                                        .bodyMedium
                                                                        ?.copyWith(
                                                                            color:
                                                                                appColors['gray143']),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding: const EdgeInsets
                                                                          .only(
                                                                      top: 5),
                                                                  child: appointmentType ==
                                                                          'clinicAppointment'
                                                                      ? FutureBuilder(
                                                                          future:
                                                                              getData(
                                                                            "clinics",
                                                                            id: appointmentDetails['clinicID'],
                                                                            field:
                                                                                "address",
                                                                          ),
                                                                          builder:
                                                                              (context, snapshot) {
                                                                            if (snapshot.connectionState ==
                                                                                ConnectionState.done) {
                                                                              var address = snapshot.data;

                                                                              return FutureBuilder(
                                                                                future: placemarkFromCoordinates(address['latitude'], address['longitude']),
                                                                                builder: (context, snapshot) {
                                                                                  if (snapshot.connectionState == ConnectionState.done) {
                                                                                    var address = snapshot.data!.first;
                                                                                    return Text(
                                                                                      "${address.street}. ${address.subLocality}, ${address.locality}, ${address.administrativeArea}",
                                                                                      style: textTheme.bodyMedium?.copyWith(color: appColors['gray143']),
                                                                                    );
                                                                                  } else {
                                                                                    return Container(
                                                                                      height: 16,
                                                                                      width: deviceWidth,
                                                                                      decoration: BoxDecoration(color: appColors['coolGray'], borderRadius: BorderRadius.circular(15)),
                                                                                    );
                                                                                  }
                                                                                },
                                                                              );
                                                                            } else {
                                                                              return Container(
                                                                                height: 16,
                                                                                width: deviceWidth,
                                                                                decoration: BoxDecoration(color: appColors['coolGray'], borderRadius: BorderRadius.circular(15)),
                                                                              );
                                                                            }
                                                                          },
                                                                        )
                                                                      : FutureBuilder(
                                                                          future:
                                                                              getData(
                                                                            "independentDoctors",
                                                                            id: pastAppointments[index]['independentDoctorID'],
                                                                          ),
                                                                          builder:
                                                                              (context, snapshot) {
                                                                            if (snapshot.connectionState ==
                                                                                ConnectionState.done) {
                                                                              var doctorInfo = snapshot.data;

                                                                              var address = doctorInfo['address'];

                                                                              return doctorInfo['clinicName'].isNotEmpty
                                                                                  ? Column(
                                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                                      children: [
                                                                                        Text(
                                                                                          "${doctorInfo['clinicName']}",
                                                                                          style: textTheme.bodyMedium?.copyWith(color: appColors['gray143']),
                                                                                        ),
                                                                                        Padding(
                                                                                          padding: const EdgeInsets.only(top: 5),
                                                                                          child: FutureBuilder(
                                                                                            future: placemarkFromCoordinates(address['latitude'], address['longitude']),
                                                                                            builder: (context, snapshot) {
                                                                                              if (snapshot.connectionState == ConnectionState.done) {
                                                                                                var address = snapshot.data!.first;
                                                                                                return Text(
                                                                                                  "${address.street}. ${address.subLocality}, ${address.locality}, ${address.administrativeArea}",
                                                                                                  style: textTheme.bodyMedium?.copyWith(color: appColors['gray143']),
                                                                                                );
                                                                                              } else {
                                                                                                return Container(
                                                                                                  height: 16,
                                                                                                  width: deviceWidth,
                                                                                                  decoration: BoxDecoration(color: appColors['coolGray'], borderRadius: BorderRadius.circular(15)),
                                                                                                );
                                                                                              }
                                                                                            },
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    )
                                                                                  : Text(
                                                                                      "Online consultation",
                                                                                      style: textTheme.bodyMedium?.copyWith(color: appColors['gray143']),
                                                                                    );
                                                                            } else {
                                                                              return Container(
                                                                                height: 16,
                                                                                width: deviceWidth,
                                                                                decoration: BoxDecoration(color: appColors['coolGray'], borderRadius: BorderRadius.circular(15)),
                                                                              );
                                                                            }
                                                                          },
                                                                        ),
                                                                ),
                                                                Padding(
                                                                  padding: const EdgeInsets
                                                                          .only(
                                                                      top: 5),
                                                                  child: appointmentType ==
                                                                          'clinicAppointment'
                                                                      ? FutureBuilder(
                                                                          future:
                                                                              getData(
                                                                            "doctors",
                                                                            id: appointmentDetails['doctorID'],
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
                                                                                width: 100,
                                                                                decoration: BoxDecoration(color: appColors['coolGray'], borderRadius: BorderRadius.circular(15)),
                                                                              );
                                                                            }
                                                                          },
                                                                        )
                                                                      : const SizedBox
                                                                          .shrink(),
                                                                ),
                                                                Padding(
                                                                  padding: EdgeInsets.only(
                                                                      top: appointmentType ==
                                                                              'clinicAppointment'
                                                                          ? 5
                                                                          : 0,
                                                                      bottom:
                                                                          10),
                                                                  child: Row(
                                                                    children: [
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.only(right: 20),
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
                                                                            ?.copyWith(color: appColors['gray143']),
                                                                      )
                                                                    ],
                                                                  ),
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
                    padding:
                        const EdgeInsets.only(bottom: 70, left: 30, right: 30),
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
                            focusNode: pendingButtonFocus,
                            onFocusChange: (hasFocus) async {
                              setState(() {});
                            },
                            child: GestureDetector(
                              onTap: () async {
                                pendingButtonFocus.requestFocus();
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    height: double.maxFinite,
                                    width: (deviceWidth - 68) / 3,
                                    decoration: BoxDecoration(
                                        color: pendingButtonFocus.hasFocus
                                            ? appColors['accent']
                                            : appColors['coolGray'],
                                        borderRadius: BorderRadius.circular(5)),
                                    child: Center(
                                      child: Text(
                                        "Pending",
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: pendingButtonFocus.hasFocus
                                              ? appColors['white']
                                              : appColors['gray143'],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Visibility(
                                    visible: pendingAppointments.isNotEmpty,
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
                            focusNode: historyButtonFocus,
                            onFocusChange: (hasFocus) async {
                              setState(() {});
                            },
                            child: GestureDetector(
                              onTap: () {
                                historyButtonFocus.requestFocus();
                              },
                              child: Container(
                                height: double.maxFinite,
                                width: (deviceWidth - 68) / 3,
                                decoration: BoxDecoration(
                                    color: historyButtonFocus.hasFocus
                                        ? appColors['accent']
                                        : appColors['coolGray'],
                                    borderRadius: BorderRadius.circular(5)),
                                child: Center(
                                  child: Text(
                                    "History",
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: historyButtonFocus.hasFocus
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
              ],
            );
          },
        );
      },
    );
  }

  showPendingCancellationDialog(UID, accountType, index) {
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
                                    "Hey there! Are you sure you want to CANCEL this PENDING appointment?",
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
                                          await addNotification(
                                              uid: UID,
                                              title:
                                                  "Appointment Request Cancelled",
                                              body:
                                                  "Hey Doc! A Patient cancelled an Appointment Request.");
                                          await updateData(
                                              '${accountType}Appointments',
                                              id: pendingAppointments[index][
                                                  '${accountType}AppointmentID'],
                                              {
                                                "status": "cancelled",
                                              });

                                          if (!mounted) return;
                                          Navigator.pop(context);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          "Yes, Cancel Now",
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
    ).then((value) {
      if (value != 'back') {
        showPendingCancelledPrompt();
      }
    });
  }

  showPendingCancelledPrompt() {
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
                      "Your Pending Appointment is Successfully Canceled!",
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
                        "The request is now canceled, you may submit another request if you want.",
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

  showCancellationDialog(UID, accountType, index) {
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
                                    "Hey there! Are you sure you want to CANCEL this CANCELLATION request?",
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
                                          var requestType =
                                              pendingAppointments[index]
                                                          ['status'] ==
                                                      "rescheduling"
                                                  ? "Reschedule"
                                                  : "Cancellation";

                                          await addNotification(
                                              uid: UID,
                                              title:
                                                  "$requestType Request Cancelled",
                                              body:
                                                  "Hey Doc! A Patient cancelled a $requestType Request.");

                                          await updateData(
                                              '${accountType}Appointments',
                                              id: pendingAppointments[index][
                                                  '${accountType}AppointmentID'],
                                              {
                                                "status": "accepted",
                                                "rescheduleDate": "",
                                                "reason": ""
                                              });

                                          if (!mounted) return;
                                          Navigator.pop(context);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          "Yes, Cancel Now",
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
    ).then((value) {
      if (value != 'back') {
        showCancellationCancelledPrompt();
      }
    });
  }

  showCancellationCancelledPrompt() {
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
                      "Your Cancellation Request is Successfully Canceled!",
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
                        "The request is now canceled, you may submit another request if you want.",
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

  showReschedulingCancellationDialog(UID, accountType, index) {
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
                                    "Hey there! Are you sure you want to CANCEL this RESCHEDULE request?",
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
                                          var requestType =
                                              pendingAppointments[index]
                                                          ['status'] ==
                                                      "rescheduling"
                                                  ? "Reschedule"
                                                  : "Cancellation";

                                          await addNotification(
                                              uid: UID,
                                              title:
                                                  "$requestType Request Cancelled",
                                              body:
                                                  "Hey Doc! A Patient cancelled a $requestType Request.");

                                          await updateData(
                                              '${accountType}Appointments',
                                              id: pendingAppointments[index][
                                                  '${accountType}AppointmentID'],
                                              {
                                                "status": "accepted",
                                                "rescheduleDate": "",
                                                "reason": ""
                                              });

                                          if (!mounted) return;
                                          Navigator.pop(context);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          "Yes, Cancel Now",
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
    ).then((value) {
      if (value != 'back') {
        showReschedulingCancelledPrompt();
      }
    });
  }

  showReschedulingCancelledPrompt() {
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
                      "Your Reschedule Request is Successfully Canceled!",
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
                        "The request is now canceled, you may submit another request if you want.",
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
