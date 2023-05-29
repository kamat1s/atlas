import 'package:atlas/Screens/Clinic/addNewDoctor.dart';
import 'package:atlas/Screens/Clinic/viewDoctorInformation.dart';
import 'package:atlas/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../global.dart';
import '../../utils.dart';

class ClinicDoctor extends StatefulWidget {
  const ClinicDoctor({Key? key}) : super(key: key);

  @override
  State<ClinicDoctor> createState() => _ClinicDoctorState();
}

class _ClinicDoctorState extends State<ClinicDoctor> {
  @override
  void initState() {
    super.initState();
  }

  final Stream<QuerySnapshot> doctorStream = FirebaseFirestore.instance
      .collection('doctors')
      .where("clinicID", isEqualTo: userData['clinicID'])
      .snapshots();

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
                  stream: doctorStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Something went wrong');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.expand();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 54),
                      child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var doctorDetails = snapshot.data!.docs[index].data()
                              as Map<String, dynamic>;

                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewDoctorInformation(
                                      doctorID: doctorDetails['doctorID'],
                                    ),
                                  ),
                                ),
                                child: Container(
                                  color: appColors['primary'],
                                  width: deviceWidth,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 22),
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 22),
                                        child: Icon(
                                          Icons.account_circle,
                                          color: appColors['accent'],
                                          size: 20,
                                        ),
                                      ),
                                      Text("Dr. ${doctorDetails['name']}")
                                    ],
                                  ),
                                ),
                              ),
                              Divider(
                                  height: 0,
                                  color: appColors['grey192'],
                                  thickness: 0.5),
                            ],
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
                          "Doctors",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddNewDoctor(),
                              ),
                            ).then((value) {
                              if (value != "back") {
                                showDoctorAddedPrompt();
                              }
                            });
                          },
                          child: Icon(
                            Icons.add,
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
  showDoctorAddedPrompt() {
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
                    Icons.inventory_outlined,
                    size: 84,
                    color: appColors['accent'],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Text(
                      "New Doctor’s Information Successfully Created!",
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
                        "New Doctor’s Information can now be viewed in the Doctors Section",
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
