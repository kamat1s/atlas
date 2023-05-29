import 'package:atlas/Screens/Clinic/clinicBusinessHours.dart';
import 'package:atlas/Screens/Clinic/clinicDoctors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:atlas/styles.dart';

import '../../global.dart';
import '../../query.dart';
import '../notifications.dart';
import '../Verification/verification.dart';

class ClinicProfile extends StatefulWidget {
  const ClinicProfile({Key? key}) : super(key: key);

  @override
  State<ClinicProfile> createState() => _ClinicProfileState();
}

class _ClinicProfileState extends State<ClinicProfile> {
  Stream<QuerySnapshot<Map<String, dynamic>>> userDataStream =
      const Stream.empty();

  @override
  void initState() {
    uid = FirebaseAuth.instance.currentUser!.uid;
    userDataStream = FirebaseFirestore.instance
        .collection('clinics')
        .where("uid", isEqualTo: uid)
        .snapshots();
    super.initState();
  }

  Future<void> showRequestSubmitted() async {
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
                      "Your Re-verification Request is Successfully Submitted!",
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
                        "Expect your request will be reviewed in 2-3 working days.",
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

  Widget getVerificationBadge(Map<String, dynamic> requestDetail) {
    if (userData['requestDetail']['verificationStatus'] == "rejected") {
      return Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: appColors['accent']!, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Text(
                          "Not Verified",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: appColors['accent']),
                        ),
                      ),
                      Icon(
                        Icons.close,
                        color: appColors['accent'],
                        size: 18,
                      ),
                    ],
                  ),
                )),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const Verification(accountType: 'clinic'),
                  )).then((value) {
                if (value) {
                  showRequestSubmitted();
                }
              });
            },
            child: Text("Verify Again",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500, color: appColors['accent'])),
          )
        ],
      );
    } else if (userData['requestDetail']['verificationStatus'] == "pending") {
      return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: appColors['gray143']!, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Text(
                    "On-going Verification",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: appColors['gray143']),
                  ),
                ),
                Icon(
                  Icons.more_horiz,
                  color: appColors['gray143'],
                  size: 18,
                ),
              ],
            ),
          ));
    } else {
      return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: appColors['accent'],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Text(
                    "Verified",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700, color: appColors['white']),
                  ),
                ),
                Icon(
                  Icons.check,
                  color: appColors['white'],
                  size: 18,
                ),
              ],
            ),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fbAuthInstance = FirebaseAuth.instance;

    return Scaffold(
        body: StreamBuilder(
            stream: userDataStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Something went wrong');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.expand();
              }

              userData = snapshot.data!.docs.first.data();

              Stream<QuerySnapshot<Map<String, dynamic>>>
                  verificationRequestStream = FirebaseFirestore.instance
                      .collection('verificationRequests')
                      .where("verificationRequestID",
                          isEqualTo: userData['verificationRequestID'])
                      .snapshots();

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${userData['clinicName']}",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: StreamBuilder(
                            stream: verificationRequestStream,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return const Text('Something went wrong');
                              }

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox.shrink();
                              }

                              var requestDetail =
                                  snapshot.data!.docs.first.data();
                              userData['requestDetail'] = requestDetail;

                              return getVerificationBadge(requestDetail);
                            })),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Divider(color: appColors['gray143']),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Notifications(),
                          ),
                        );
                      },
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: 5, right: 5, top: 25),
                        child: Text(
                          "Notifications",
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ClinicDoctor(),
                        ),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: 5, right: 5, top: 25),
                        child: Text(
                          "Doctors",
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ClinicBusinessHours(),
                        ),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: 5, right: 5, top: 25),
                        child: Text(
                          "Business Hours",
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: 5, right: 5, top: 25),
                        child: Text(
                          "About the app",
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        fbAuthInstance.signOut();

                        String accountType = 'clinic';

                        await getData("${accountType}s",
                                uid: uid, field: "token")
                            .then((token) {
                          if (token != null && token.contains(fcmToken)) {
                            token.remove(fcmToken);
                            updateData(
                                "${accountType}s", uid: uid, {"token": token});
                          }
                        });
                      },
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: 5, right: 5, top: 25),
                        child: Text(
                          "Logout",
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }));
  }
}
