import 'dart:async';
import 'dart:developer';

import 'package:atlas/Screens/Patient/patientDoctorsTab.dart';
import 'package:atlas/Screens/Patient/patientMap.dart';
import 'package:atlas/Screens/Patient/patientProfile.dart';
import 'package:atlas/Screens/Patient/patientSaved.dart';
import 'package:atlas/Screens/Patient/patientAppointments.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:atlas/styles.dart';

import '../../Classes/NotificationControllerFCM.dart';
import '../../query.dart';
import '../Setup/setup.dart';
import 'package:atlas/global.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({Key? key}) : super(key: key);

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  int panelSelected = 1;

  Stream<QuerySnapshot<Map<String, dynamic>>> userDataStream =
      const Stream.empty();

  late StreamSubscription patientNotificationStream;

  void changePanel(int panel) {
    if (!mounted) return;
    setState(() {
      panelSelected = panel;
    });
  }

  Widget getPanel() {
    switch (panelSelected) {
      case 1:
        {
          return PatientMap(
            patientHome: this,
          );
        }
      case 2:
        {
          return const Appointments();
        }
      case 3:
        {
          return DoctorsTab(
            patientHome: this,
          );
        }
      case 4:
        {
          return const PatientProfile();
        }
      default:
        {
          return const Center();
        }
    }
  }

  Future<void> showCreateAccountPrompt() async {
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
                    Icons.no_accounts_outlined,
                    size: 84,
                    color: appColors['accent'],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Text(
                      "Feature Unavailable in Guest Mode",
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text("You need an account to use this feature",
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

  //TODO: fix rescheduled appointment scheduled notification
  @override
  void initState() {
    uid = FirebaseAuth.instance.currentUser!.uid;

    NotificationController.initializeLocalNotifications(debug: true);
    NotificationController.initializeRemoteNotifications(debug: true);
    NotificationController.startListeningNotificationEvents();

    userDataStream = FirebaseFirestore.instance
        .collection('patients')
        .where("uid", isEqualTo: uid)
        .snapshots();

    patientNotificationStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .where('dismissed', isEqualTo: false)
        .snapshots()
        .listen((event) async {
      await NotificationController.cancelScheduled();
      for (var doc in event.docs) {
        if (doc.data()['dismissed'] == false) {
          if (doc.data()['scheduleDate'] == "") {
            await NotificationController.createNewNotification(
                doc.data()['notificationID'],
                doc.data()['title'],
                doc.data()['body']);

            await updateData('notifications', {"dismissed": true},
                id: doc.data()['notificationID']);
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
    patientNotificationStream.cancel();
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
          isAnonymous = FirebaseAuth.instance.currentUser!.isAnonymous;

          userData = isAnonymous ? [] : snapshot.data!.docs.first.data();
          print(userData);

          return FutureBuilder(
            future: checkSetupStatus(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                log("Account Status: ${snapshot.data}");
                if (snapshot.data == true || setupDone == true || isAnonymous) {
                  return Scaffold(
                    backgroundColor: appColors['accent'],
                    body: SafeArea(
                      child: Container(
                        color: appColors['primary'],
                        child: Stack(
                          children: [
                            getPanel(),
                            panelSelected != 1 && panelSelected != 4
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
                                            width: deviceWidth / 4,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  panelSelected == 1
                                                      ? Icons.map_sharp
                                                      : Icons.map_outlined,
                                                  color: panelSelected == 1
                                                      ? appColors['accent']
                                                      : appColors['black'],
                                                ),
                                                Text(
                                                  "Map",
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
                                            width: deviceWidth / 4,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  panelSelected == 2
                                                      ? Icons.calendar_today
                                                      : Icons
                                                          .calendar_today_outlined,
                                                  color: panelSelected == 2
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
                                              if (isAnonymous) {
                                                showCreateAccountPrompt();
                                              } else {
                                                setState(() {
                                                  panelSelected = 2;
                                                });
                                              }
                                            }
                                          },
                                        ),
                                        GestureDetector(
                                          child: SizedBox(
                                            width: deviceWidth / 4,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  panelSelected == 3
                                                      ? Icons.person_rounded
                                                      : Icons
                                                          .person_outline_rounded,
                                                  color: panelSelected == 3
                                                      ? appColors['accent']
                                                      : appColors['black'],
                                                ),
                                                Text(
                                                  "Doctors",
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
                                              if (isAnonymous) {
                                                showCreateAccountPrompt();
                                              } else {
                                                setState(() {
                                                  panelSelected = 3;
                                                });
                                              }
                                            }
                                          },
                                        ),
                                        GestureDetector(
                                          child: SizedBox(
                                            width: deviceWidth / 4,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  panelSelected == 4
                                                      ? Icons.account_circle
                                                      : Icons
                                                          .account_circle_outlined,
                                                  color: panelSelected == 4
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
                                                    color: panelSelected == 4
                                                        ? appColors['accent']
                                                        : appColors['black'],
                                                    fontWeight:
                                                        panelSelected == 4
                                                            ? FontWeight.w600
                                                            : FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          onTap: () {
                                            if (panelSelected != 4) {
                                              setState(() {
                                                panelSelected = 4;
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
                    accountType: "Patient",
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
