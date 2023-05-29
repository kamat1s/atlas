import 'dart:developer';

import 'package:atlas/Screens/Clinic/editDoctorInformation.dart';
import 'package:atlas/query.dart';
import 'package:atlas/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';

import '../../Classes/Doctor.dart';
import '../../global.dart';
import '../../utils.dart';

class ViewDoctorInformation extends StatefulWidget {
  final doctorID;
  const ViewDoctorInformation({Key? key, required this.doctorID})
      : super(key: key);

  @override
  State<ViewDoctorInformation> createState() => _ViewDoctorInformationState();
}

class _ViewDoctorInformationState extends State<ViewDoctorInformation> {
  Map<String, dynamic> doctorInformation = {};
  int doctorID = 0;

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

          if (snapshot.data!.docs.isEmpty) {
            return const Center();
          } else {
            doctorInformation = snapshot.data!.docs.first.data();

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
                                doctorNameWidget(),
                                doctorSpecializationsWidget(),
                                doctorServiceHoursWidget(),
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
                                  "Doctor Information",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditDoctorInformation(
                                          doctorID: doctorID,
                                        ),
                                      ),
                                    ).then((value) {
                                      if (value != "back") {
                                        showInfoUpdatedPrompt();
                                      }
                                    }),
                                    child: Icon(
                                      Icons.edit,
                                      color: appColors['black'],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    bool hasActiveAppointment = false;

                                    hasActiveAppointment =
                                        await checkDoctorActiveAppointment(
                                            doctorID: doctorID);
                                    if (hasActiveAppointment) {
                                      showCannotDeleteInfoPrompt();
                                    } else if (userData['doctors'].length ==
                                        1) {
                                      showSnackBar(
                                          "Clinic must have at least one doctor.");
                                    } else {
                                      showDeleteConfirmation();
                                    }
                                  },
                                  child: Icon(
                                    Icons.delete,
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
        });
  }

  Widget doctorNameWidget() => Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Icon(
              Icons.account_circle,
              color: appColors['accent'],
            ),
          ),
          Text(
            "Dr. ${doctorInformation['name']}",
            style: getTextStyle(
              textColor: 'black',
              fontFamily: 'Inter',
              fontWeight: 500,
              fontSize: 12,
            ),
          ),
        ],
      );

  Widget doctorSpecializationsWidget() => Padding(
        padding: const EdgeInsets.only(top: 23),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Icon(
                Icons.medical_services,
                color: appColors['accent'],
              ),
            ),
            Text(
              doctorInformation['specializations'].toString().substring(1,
                  doctorInformation['specializations'].toString().length - 1),
              style: getTextStyle(
                textColor: 'black',
                fontFamily: 'Inter',
                fontWeight: 500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );

  Widget doctorServiceHoursWidget() => Padding(
        padding: const EdgeInsets.only(top: 23),
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(
                    Icons.watch_later,
                    color: appColors['accent'],
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "$day",
                          style: getTextStyle(
                            textColor: 'black',
                            fontFamily: 'Inter',
                            fontWeight: 500,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "${formatTime(convertTime(serviceHour['openingHour']))}:${formatTime(serviceHour['openingMinute'])} ${serviceHour['openingMeridiem']} - ${formatTime(convertTime(serviceHour['closingHour']))}:${formatTime(serviceHour['closingMinute'])} ${serviceHour['closingMeridiem']}",
                          style: getTextStyle(
                            textColor: 'black',
                            fontFamily: 'Inter',
                            fontWeight: 500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );

  showInfoUpdatedPrompt() {
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
                      "Doctor’s Information Successfully Updated!",
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
                        "Updated Doctor’s Information can now be viewed in the Doctors Section",
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

  showDeleteConfirmation() {
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
                                    "Hey Doc! Are you sure you want to remove this doctor?",
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

                                          await deleteData('doctors', doctorID);

                                          userData['doctors'].remove(doctorID);

                                          await updateData('clinics', userData,
                                              uid: uid);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          "Yes, Remove Now",
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
        Navigator.pop(context);
        showInfoDeletedPrompt();
      }
    });
  }

  showInfoDeletedPrompt() {
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
                    Icons.delete_outline,
                    size: 84,
                    color: appColors['accent'],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Text(
                      "Doctor’s Information Successfully Removed!",
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
                        "This Doctor’s Information cannot be retrieved but you can Add it again in the Doctors Section",
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
                      "Oops! This Doctor has Active or On-going Appointments!",
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
                        "This Doctor’s Information can’t be deleted because it has appointments that are still active.",
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
}
