import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import '../../global.dart';
import '../../query.dart';
import '../../styles.dart';
import '../../utils.dart';
import '../Appointment/doctorAppointment.dart';

class DoctorsTab extends StatefulWidget {
  final patientHome;
  const DoctorsTab({Key? key, required this.patientHome}) : super(key: key);

  @override
  State<DoctorsTab> createState() => _DoctorsTabState();
}

class _DoctorsTabState extends State<DoctorsTab> {
  TextEditingController doctorNameController = TextEditingController();

  bool showDoctorInfo = false;

  List doctors = [];
  Map<String, dynamic> doctorInformation = {};

  List matchedDoctors = [];

  final Stream<QuerySnapshot> doctorsStream =
      FirebaseFirestore.instance.collection('independentDoctors').snapshots();

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).focusScopeNode.unfocus();
      },
      child: Scaffold(
          body: StreamBuilder(
        stream: doctorsStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            doctors = snapshot.data!.docs;

            print(doctors);

            if (doctors.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: appColors['gray145'],
                      size: 77,
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 89, right: 89, top: 10),
                      child: Text("No Doctors have registered yet",
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: appColors['gray145']),
                          textAlign: TextAlign.center),
                    )
                  ],
                ),
              );
            } else {
              return FutureBuilder(
                future: getVerifiedDoctors(doctors),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return StatefulBuilder(
                      builder: (context, listSetState) {
                        doctors = snapshot.data ?? [];

                        if (doctors.isEmpty &&
                            doctorNameController.text.trim().isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: appColors['gray145'],
                                  size: 77,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 89, right: 89, top: 10),
                                  child: Text("No Verified Doctors yet",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: appColors['gray145']),
                                      textAlign: TextAlign.center),
                                )
                              ],
                            ),
                          );
                        } else {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 100, top: 50),
                                  child: Column(
                                    children: [
                                      Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              25, 20, 25, 68),
                                          child: ListView.builder(
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            shrinkWrap: true,
                                            itemCount: doctorNameController.text
                                                    .trim()
                                                    .isNotEmpty
                                                ? matchedDoctors.length
                                                : doctors.length,
                                            itemBuilder: (context, index) {
                                              var doctors = doctorNameController
                                                      .text
                                                      .trim()
                                                      .isNotEmpty
                                                  ? matchedDoctors
                                                  : this.doctors;

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 15),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    doctorInformation =
                                                        doctorNameController
                                                                .text
                                                                .trim()
                                                                .isNotEmpty
                                                            ? matchedDoctors[
                                                                index]
                                                            : doctors[index];

                                                    listSetState(() {
                                                      showDoctorInfo = true;
                                                    });

                                                    Navigator.of(context)
                                                        .focusScopeNode
                                                        .unfocus();
                                                  },
                                                  child: Container(
                                                      padding: const EdgeInsets
                                                              .fromLTRB(
                                                          15, 10, 15, 10),
                                                      decoration: BoxDecoration(
                                                          color: appColors[
                                                              'white'],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(15),
                                                          boxShadow: [
                                                            BoxShadow(
                                                                color: appColors[
                                                                    'black.25']!,
                                                                offset:
                                                                    const Offset(
                                                                        0, 2),
                                                                blurRadius: 2,
                                                                spreadRadius: 0)
                                                          ]),
                                                      child: Column(
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
                                                                "${doctors[index]['firstName']}${doctors[index]['middleName'].isNotEmpty ? " ${doctors[index]['middleName']} " : " "}${doctors[index]['lastName']}",
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .labelMedium
                                                                    ?.copyWith(
                                                                        fontWeight:
                                                                            FontWeight.w600),
                                                              ),
                                                              Icon(
                                                                doctors[index][
                                                                            'clinicName'] ==
                                                                        ""
                                                                    ? Icons
                                                                        .person_rounded
                                                                    : Icons
                                                                        .home,
                                                                color: appColors[
                                                                    'black'],
                                                                size: 24,
                                                              ),
                                                            ],
                                                          ),
                                                          doctors[index][
                                                                      'address']
                                                                  .isNotEmpty
                                                              ? Padding(
                                                                  padding: const EdgeInsets
                                                                          .only(
                                                                      top: 5),
                                                                  child:
                                                                      FutureBuilder(
                                                                    future: placemarkFromCoordinates(
                                                                        doctors[index]['address']
                                                                            [
                                                                            'latitude'],
                                                                        doctors[index]['address']
                                                                            [
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
                                                                          style: Theme.of(context)
                                                                              .textTheme
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
                                                                  ),
                                                                )
                                                              : const SizedBox
                                                                  .shrink(),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    top: 5),
                                                            child: Text(
                                                              "${doctors[index]['contactNumber']}",
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyMedium
                                                                  ?.copyWith(
                                                                      color: appColors[
                                                                          'gray143']),
                                                            ),
                                                          ),
                                                        ],
                                                      )),
                                                ),
                                              );
                                            },
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                              searchWidget(deviceWidth, listSetState),
                              showDoctorInfo
                                  ? doctorInfo(deviceWidth, deviceHeight, theme,
                                      listSetState)
                                  : const SizedBox.shrink(),
                            ],
                          );
                        }
                      },
                    );
                  } else {
                    return Center(
                      child: CircularProgressIndicator(
                          color: appColors['accent'], strokeWidth: 5),
                    );
                  }
                },
              );
            }
          } else {
            return Center(
              child: CircularProgressIndicator(
                  color: appColors['accent'], strokeWidth: 5),
            );
          }
        },
      )),
    );
  }

  Widget doctorInfo(deviceWidth, deviceHeight, theme, setState) => WillPopScope(
        onWillPop: () async {
          setState(() {
            showDoctorInfo = false;
          });
          return false;
        },
        child: SizedBox(
          height: double.maxFinite,
          width: double.maxFinite,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    showDoctorInfo = false;
                  });
                },
                child: Container(
                  color: appColors['black.25'],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                      color: appColors['primary'],
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15))),
                  height: 465,
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            height: deviceHeight * .35,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: appColors['black']!),
                              ),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(top: 20, bottom: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    doctorInformation['clinicName'].isNotEmpty
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    doctorInformation[
                                                        'clinicName'],
                                                    style: theme.textTheme
                                                        .headlineSmall,
                                                  ),
                                                ],
                                              ),
                                              FutureBuilder(
                                                future:
                                                    placemarkFromCoordinates(
                                                        doctorInformation[
                                                                'address']
                                                            ['latitude'],
                                                        doctorInformation[
                                                                'address']
                                                            ['longitude']),
                                                builder: (BuildContext context,
                                                    AsyncSnapshot<dynamic>
                                                        snapshot) {
                                                  if (snapshot.hasData) {
                                                    //log(snapshot.data.toString());
                                                    var address =
                                                        snapshot.data.first;

                                                    return SizedBox(
                                                      width: deviceWidth * .60,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 8),
                                                        child: Text(
                                                          "${address.street}. ${address.subLocality}, ${address.locality}, ${address.administrativeArea}",
                                                          style: theme.textTheme
                                                              .labelSmall,
                                                        ),
                                                      ),
                                                    );
                                                  } else {
                                                    return const SizedBox
                                                        .shrink();
                                                  }
                                                },
                                              ),
                                            ],
                                          )
                                        : Text(
                                            "${doctorInformation['firstName']}${doctorInformation['middleName'].isNotEmpty ? " ${doctorInformation['middleName']} " : " "}${doctorInformation['lastName']}",
                                            style:
                                                theme.textTheme.headlineSmall,
                                          ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Text(
                                        doctorInformation['contactNumber'],
                                        style: theme.textTheme.labelSmall,
                                      ),
                                    ),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount:
                                          doctorInformation['serviceHours']
                                              .length,
                                      itemBuilder: (context, index) {
                                        var serviceHour =
                                            doctorInformation['serviceHours']
                                                [index];
                                        var day = serviceHour['day'];

                                        return Padding(
                                          padding: EdgeInsets.only(
                                              right: 40,
                                              top: index == 0 ? 8 : 5),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                day,
                                                style:
                                                    theme.textTheme.labelSmall,
                                              ),
                                              Text(
                                                "${formatTime(convertTime(serviceHour['openingHour']))}:${formatTime(serviceHour['openingMinute'])} ${serviceHour['openingMeridiem']} - ${formatTime(convertTime(serviceHour['closingHour']))}:${formatTime(serviceHour['closingMinute'])} ${serviceHour['closingMeridiem']}",
                                                style:
                                                    theme.textTheme.labelSmall,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Text("Services Offered",
                                          style: theme.textTheme.labelSmall),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 5, right: 40),
                                      child: GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 5,
                                            mainAxisExtent: 18,
                                            crossAxisSpacing: 5,
                                          ),
                                          itemCount:
                                              doctorInformation['services']
                                                  .length,
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            return Text(
                                                "· ${doctorInformation['services'][index]}",
                                                style:
                                                    theme.textTheme.labelSmall);
                                          }),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Text("Accreditations",
                                          style: theme.textTheme.labelSmall),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 5, right: 40),
                                      child: GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 5,
                                            mainAxisExtent: 18,
                                            crossAxisSpacing: 5,
                                          ),
                                          itemCount: doctorInformation[
                                                  'accreditations']
                                              .length,
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            return Text(
                                                "· ${doctorInformation['accreditations'][index]}",
                                                style:
                                                    theme.textTheme.labelSmall);
                                          }),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 65, right: 20),
                          child: ElevatedButton(
                            onPressed: () async {
                              Map<String, dynamic> requestDetail;

                              if (isAnonymous) {
                                showCreateAccountPrompt();
                              } else if (!isAnonymous) {
                                requestDetail = await getData(
                                    'verificationRequests',
                                    id: userData['verificationRequestID']);
                                log(requestDetail.toString());
                                if (requestDetail['verificationStatus'] !=
                                    'approved') {
                                  showUnavailableFeaturePrompt();
                                } else {
                                  if (!mounted) return;

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DoctorAppointment(
                                        doctorInformation: doctorInformation,
                                      ),
                                    ),
                                  ).then((value) {
                                    if (value == "Maps") {
                                      if (!mounted) return;
                                      setState(() {
                                        showDoctorInfo = false;
                                      });
                                    } else if (value == "Appointments") {
                                      widget.patientHome.changePanel(2);
                                    }
                                  });
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: appColors['accent'],
                              fixedSize: const Size(170, 58),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Schedule an Appointment",
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: appColors['white'],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.edit_calendar,
                                  color: appColors['white'],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      );

  Widget searchWidget(deviceWidth, setState) => Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 88),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            width: deviceWidth,
            height: 48,
            decoration: BoxDecoration(
              color: appColors['coolGray'],
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: appColors['black.25']!,
                  offset: const Offset(0, 4),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: TextFormField(
                        controller: doctorNameController,
                        style: getTextStyle(
                          textColor: 'black',
                          fontFamily: 'Inter',
                          fontWeight: 400,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          hintText: "Doctor Name",
                          hintStyle: getTextStyle(
                            textColor: 'gray143',
                            fontFamily: 'Inter',
                            fontWeight: 400,
                            fontSize: 16,
                          ),
                        ),
                        onChanged: (doctorName) {
                          searchDoctorByName(name: doctorNameController.text);
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                  Icon(
                    Icons.search,
                    color: appColors['black'],
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  void searchDoctorByName({required String name}) {
    matchedDoctors.clear();

    if (name.trim().isNotEmpty) {
      RegExp regex = RegExp(name.trim(), caseSensitive: false);

      for (var doctor in doctors) {
        for (var match in regex.allMatches(
            "${doctor['firstName']} ${doctor['middleName']} ${doctor['lastName']} | ${doctor['firstName']} ${doctor['lastName']}")) {
          matchedDoctors.add(doctor);
          break;
        }
      }
    } else {
      matchedDoctors = [];
    }

    log(matchedDoctors.length.toString());
    log(matchedDoctors.toString());
  }

  Future<void> showUnavailableFeaturePrompt() async {
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
                    Icons.highlight_off,
                    size: 84,
                    color: appColors['accent'],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Text(
                      "This Action Requires Verification",
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
                        "Wait for approval or re-submit verification request",
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

  Future<List<Map<String, dynamic>>> getVerifiedDoctors(List doctors) async {
    List<Map<String, dynamic>> verifiedDoctors = [];

    for (var doctor in doctors) {
      var doctorData = doctor.data();

      Map<String, dynamic> verificationDetails = await getData(
          'verificationRequests',
          id: doctorData['verificationRequestID']);

      if (verificationDetails['verificationStatus'] == "approved") {
        verifiedDoctors.add(doctorData);
      }
    }

    return verifiedDoctors;
  }
}
