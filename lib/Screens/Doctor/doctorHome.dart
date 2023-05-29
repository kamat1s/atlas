import 'dart:async';
import 'dart:developer';

import 'package:atlas/Screens/Appointment/doctorAppointment.dart';
import 'package:atlas/Screens/Clinic/clinicAppointments.dart';
import 'package:atlas/Screens/Clinic/clinicPending.dart';
import 'package:atlas/Screens/Clinic/clinicProfile.dart';
import 'package:atlas/Screens/Doctor/doctorPending.dart';
import 'package:atlas/Screens/Doctor/doctorProfile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:atlas/styles.dart';

import '../../Classes/NotificationControllerFCM.dart';
import '../../global.dart';
import '../../query.dart';
import '../Setup/setup.dart';
import 'doctorAppointments.dart';

class DoctorHome extends StatefulWidget {
  const DoctorHome({Key? key}) : super(key: key);

  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome> {
  int panelSelected = 2;

  Stream<QuerySnapshot<Map<String, dynamic>>> userDataStream =
      const Stream.empty();

  late StreamSubscription doctorNotificationStream;

  Widget getPanel() {
    switch (panelSelected) {
      case 1:
        {
          return const DoctorAppointments();
        }
      case 2:
        {
          return const DoctorPending();
        }
      case 3:
        {
          return const DoctorProfile();
        }
      default:
        {
          return const Center();
        }
    }
  }

  @override
  void initState() {
    uid = FirebaseAuth.instance.currentUser!.uid;

    NotificationController.initializeLocalNotifications(debug: true);
    NotificationController.initializeRemoteNotifications(debug: true);
    NotificationController.startListeningNotificationEvents();

    userDataStream = FirebaseFirestore.instance
        .collection('independentDoctors')
        .where("uid", isEqualTo: uid)
        .snapshots();

    doctorNotificationStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .where('dismissed', isEqualTo: false)
        .snapshots()
        .listen((event) async {
      for (var doc in event.docs) {
        if (doc.data()['dismissed'] == false) {
          if (doc.data()['scheduleDate'] == "") {
            await NotificationController.createNewNotification(
                doc.data()['notificationID'], doc.data()['title'], doc.data()['body']);
          } else {
            await NotificationController.scheduleNewNotification(
                doc.data()['notificationID'],
                doc.data()['title'],
                doc.data()['body'],
                doc.data()['scheduleDate']);
          }
        }
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    doctorNotificationStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    bool setupDone = false;

    void toggle() {
      if (!mounted) return;
      setState(() {
        setupDone = !setupDone;
      });
    }

    return StreamBuilder(
        stream: userDataStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.expand();
          }

          userData = snapshot.data!.docs.first.data();

          return FutureBuilder(
            future: checkSetupStatus(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                log(snapshot.data.toString());
                if (snapshot.data == true || setupDone == true) {
                  return Scaffold(
                    backgroundColor: appColors['accent'],
                    body: SafeArea(
                      child: Container(
                        color: appColors['primary'],
                        child: Stack(
                          children: [
                            getPanel(),
                            panelSelected != 3
                                ? Positioned(
                                    left: 0,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 15, top: 15),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(right: 5),
                                            child: Image.asset(
                                                "assets/images/atlas-logo-small.png"),
                                          ),
                                          Text(
                                            "ATLAS",
                                            style: TextStyle(
                                                fontFamily:
                                                    appFonts['Montserrat'],
                                                fontSize: 24.5,
                                                fontWeight: FontWeight.w500,
                                                color: appColors['gray145']),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            Positioned(
                              bottom: 0,
                              child: Column(
                                children: [
                                  Container(
                                    height: 50,
                                    width: deviceWidth,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(15),
                                          topRight: Radius.circular(15)),
                                      boxShadow: [
                                        BoxShadow(
                                          offset: const Offset(0, -5),
                                          blurRadius: 10,
                                          spreadRadius: 0,
                                          color: appColors['black.25']!,
                                        ),
                                      ],
                                      color: appColors['white'],
                                    ),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          child: SizedBox(
                                            width: deviceWidth / 3,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  panelSelected == 1
                                                      ? Icons.inbox
                                                      : Icons.inbox_outlined,
                                                  color: panelSelected == 1
                                                      ? appColors['accent']
                                                      : appColors['black'],
                                                ),
                                                Text(
                                                  "Appointments",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme.labelSmall!
                                                      .copyWith(
                                                    color: panelSelected == 1
                                                        ? appColors['accent']
                                                        : appColors['black'],
                                                    fontWeight:
                                                        panelSelected == 1
                                                            ? FontWeight.w600
                                                            : FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          onTap: () {
                                            if (panelSelected != 1) {
                                              setState(() {
                                                panelSelected = 1;
                                              });
                                            }
                                          },
                                        ),
                                        GestureDetector(
                                          child: SizedBox(
                                            width: deviceWidth / 3,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  panelSelected == 2
                                                      ? Icons.pending
                                                      : Icons.pending_outlined,
                                                  color: panelSelected == 2
                                                      ? appColors['accent']
                                                      : appColors['black'],
                                                ),
                                                Text(
                                                  "Pending",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme.labelSmall!
                                                      .copyWith(
                                                    color: panelSelected == 2
                                                        ? appColors['accent']
                                                        : appColors['black'],
                                                    fontWeight:
                                                        panelSelected == 2
                                                            ? FontWeight.w600
                                                            : FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          onTap: () {
                                            if (panelSelected != 2) {
                                              setState(() {
                                                panelSelected = 2;
                                              });
                                            }
                                          },
                                        ),
                                        GestureDetector(
                                          child: SizedBox(
                                            width: deviceWidth / 3,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  panelSelected == 3
                                                      ? Icons.account_circle
                                                      : Icons
                                                          .account_circle_outlined,
                                                  color: panelSelected == 3
                                                      ? appColors['accent']
                                                      : appColors['black'],
                                                ),
                                                Text(
                                                  "Profile",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme.labelSmall!
                                                      .copyWith(
                                                    color: panelSelected == 3
                                                        ? appColors['accent']
                                                        : appColors['black'],
                                                    fontWeight:
                                                        panelSelected == 3
                                                            ? FontWeight.w600
                                                            : FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          onTap: () {
                                            if (panelSelected != 3) {
                                              setState(() {
                                                panelSelected = 3;
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  return Setup(
                    accountType: "Doctor",
                    onSetupDone: toggle,
                  );
                }
              } else {
                return const Center();
              }
            },
          );
        });
  }
}
