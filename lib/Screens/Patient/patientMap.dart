import 'dart:developer';

import 'package:atlas/Screens/Appointment/clinicAppointment.dart';
import 'package:atlas/Screens/Appointment/doctorAppointment.dart';
import 'package:atlas/Screens/Patient/patientSaved.dart';
import 'package:atlas/global.dart';
import 'package:atlas/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:atlas/styles.dart';

import '../../query.dart';

class PatientMap extends StatefulWidget {
  final patientHome;
  const PatientMap({Key? key, required this.patientHome}) : super(key: key);

  @override
  State<PatientMap> createState() => _PatientMapState();
}

class _PatientMapState extends State<PatientMap> {
  final _mapController = MapController();

  final clinicNameController = TextEditingController();

  final scrollController = ScrollController();

  bool mapIsReady = false;
  bool onCurrentLocation = true;

  List<Map<String, dynamic>> clinicsInformation = [];
  List<Map<String, dynamic>> doctorsInformation = [];

  Map<String, dynamic> clinicInformation = {};
  Map<String, dynamic> doctorInformation = {};

  int clinicID = 0;
  int doctorID = 0;

  List<String> accreditations = [
    "DOH",
    "PhilHealth",
    "LTO",
    "POEA",
    "Kaiser",
    "DMW"
  ];

  String? category;

  List<String> categories = <String>[
    'Dental',
    'Diagnostic/Imaging',
    'Medical',
  ];

  List<String> prevSelectedAccreditations = [];
  List<String> selectedAccreditations = [];
  List<String> prevSelectedServices = [];
  List<String> selectedServices = [];

  List<String> selectedDentalServices = [];
  List<String> selectedDiagnosticServices = [];
  List<String> selectedMedicalServices = [];
  List<String> prevSelectedDentalServices = [];
  List<String> prevSelectedDiagnosticServices = [];
  List<String> prevSelectedMedicalServices = [];

  List<DocumentSnapshot> services = [];

  List<String> filteredServices = [];

  List<String> dentalServices = [];
  List<String> diagnosticServices = [];
  List<String> medicalServices = [];

  List savedClinics = [];

  List<Marker> nearbyClinicsMarker = [];
  bool searchArea = false;
  bool applyFilter = false;
  bool clear = false;

  List matchedClinics = [];

  List nearbyClinicsInfo = [];

  bool showClinicInfo = false;
  bool showClinicList = false;

  bool showCloseButton = true;

  String drawerType = "filterDrawer";

  showMore() {
    showDialog<void>(
      useSafeArea: true,
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        final deviceHeight = MediaQuery.of(context).size.height;

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              insetPadding: const EdgeInsets.all(15),
              child: SizedBox(
                height: deviceHeight * .60,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
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
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              category!,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 15, right: 15, bottom: 15),
                        child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              mainAxisExtent: 48,
                              crossAxisSpacing: 20,
                            ),
                            itemCount: filteredServices.length,
                            itemBuilder: (BuildContext context, int index) {
                              String service = filteredServices[index];
                              return SizedBox(
                                height: 48,
                                child: TextButton(
                                  onPressed: () {
                                    if (!mounted) return;
                                    dialogSetState(() {
                                      if (category == 'Dental') {
                                        selectedServices =
                                            selectedDentalServices;
                                      } else if (category ==
                                          'Diagnostic/Imaging') {
                                        selectedServices =
                                            selectedDiagnosticServices;
                                      } else if (category == 'Medical') {
                                        selectedServices =
                                            selectedMedicalServices;
                                      }
                                      log("filtered Selected Services: $selectedServices");

                                      if (selectedServices.contains(service)) {
                                        selectedServices.remove(service);

                                        if (!(selectedServices.length !=
                                                index + 1 &&
                                            index + 1 ==
                                                filteredServices.length)) {
                                          for (int i = index;
                                              i < filteredServices.length - 1;
                                              i++) {
                                            if (selectedServices.contains(
                                                filteredServices[i + 1])) {
                                              filteredServices.remove(service);
                                              filteredServices.insert(
                                                  i + 1, service);
                                            }
                                          }
                                        }
                                      } else {
                                        selectedServices.add(service);
                                        filteredServices.remove(service);
                                        filteredServices.insert(
                                            selectedServices.length - 1,
                                            service);
                                      }

                                      if (category == 'Dental') {
                                        selectedDentalServices =
                                            selectedServices;
                                      } else if (category ==
                                          'Diagnostic/Imaging') {
                                        selectedDiagnosticServices =
                                            selectedServices;
                                      } else if (category == 'Medical') {
                                        selectedMedicalServices =
                                            selectedServices;
                                      }

                                      selectedServices = [];
                                      selectedServices
                                          .addAll(selectedDentalServices);
                                      selectedServices
                                          .addAll(selectedDiagnosticServices);
                                      selectedServices
                                          .addAll(selectedMedicalServices);

                                      log("Selected Services: $selectedServices");
                                    });
                                    setState(() {});
                                  },
                                  style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    backgroundColor:
                                        selectedServices.contains(service)
                                            ? appColors['accent']
                                            : appColors['coolGray'],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 10, right: 10),
                                    child: Text(
                                      service,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            selectedServices.contains(service)
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

  bool filterClinic(Map<String, dynamic> clinicInformation) {
    List<dynamic> accreditations = clinicInformation['accreditations'];
    List<dynamic> services = clinicInformation['services'];

    log(clinicInformation['requestDetail']['verificationStatus']);

    if (clinicInformation['requestDetail']['verificationStatus'] !=
        'approved') {
      return false;
    }

    if (selectedAccreditations.isEmpty && selectedServices.isEmpty) return true;

    for (int i = 0; i < selectedAccreditations.length; i++) {
      if (!accreditations.contains(selectedAccreditations[i])) {
        return false;
      }
    }

    for (int i = 0; i < selectedServices.length; i++) {
      if (!services.contains(selectedServices[i])) {
        return false;
      }
    }

    return true;
  }

  void searchClinicByName({required String name}) {
    matchedClinics.clear();

    if (name.trim().isNotEmpty) {
      RegExp regex = RegExp(name.trim(), caseSensitive: false);

      for (var clinicInformation in clinicsInformation) {
        for (var match in regex.allMatches(clinicInformation['clinicName'])) {
          matchedClinics.add(clinicInformation);
          break;
        }
      }
      for (var doctorInformation in doctorsInformation) {
        for (var match in regex.allMatches(doctorInformation['clinicName'])) {
          matchedClinics.add(doctorInformation);
          break;
        }
      }
    } else {
      matchedClinics = [];
    }
  }

  List<Marker> findNearbyClinics(LatLng currentLocation) {
    nearbyClinicsMarker = [];
    nearbyClinicsInfo = [];
    applyFilter = false;
    searchArea = false;
    clear = false;

    // Clinics
    for (int i = 0; i < clinicsInformation.length; i++) {
      Marker marker = Marker(
        point: LatLng(clinicsInformation[i]['address']['latitude'],
            clinicsInformation[i]['address']['longitude']),
        rotate: false,
        builder: (context) => Align(
          alignment: const FractionalOffset(0.5, -1),
          child: GestureDetector(
            onTap: () {
              clinicInformation = clinicsInformation[i];
              log(clinicsInformation[i]['clinicName']);
              clinicID = clinicsInformation[i]['clinicID'];
              setState(() {
                showClinicInfo = true;
              });
            },
            child: Icon(
              Icons.location_pin,
              color: appColors['accent'],
            ),
          ),
        ),
      );

      var startLatitude = currentLocation.latitude;
      var startLongitude = currentLocation.longitude;
      var endLatitude = clinicsInformation[i]['address']['latitude'];
      var endLongitude = clinicsInformation[i]['address']['longitude'];

      var distance = Geolocator.distanceBetween(
          startLatitude, startLongitude, endLatitude, endLongitude);

      /*print(distance);*/
      if (distance <= 1500 && filterClinic(clinicsInformation[i])) {
        nearbyClinicsMarker.add(marker);
        nearbyClinicsInfo.add(clinicsInformation[i]);
      }
    }

    // Doctor Clinics
    for (int i = 0; i < doctorsInformation.length; i++) {
      if (doctorsInformation[i]['clinicName'] != "") {
        Marker marker = Marker(
          point: LatLng(doctorsInformation[i]['address']['latitude'],
              doctorsInformation[i]['address']['longitude']),
          rotate: false,
          builder: (context) => Align(
            alignment: const FractionalOffset(0.5, -1),
            child: GestureDetector(
              onTap: () {
                clinicInformation = doctorsInformation[i];
                log(doctorsInformation[i]['clinicName']);
                doctorID = doctorsInformation[i]['independentDoctorID'];
                setState(() {
                  showClinicInfo = true;
                });
              },
              child: Icon(
                Icons.location_pin,
                color: appColors['accent'],
              ),
            ),
          ),
        );

        var startLatitude = currentLocation.latitude;
        var startLongitude = currentLocation.longitude;
        var endLatitude = doctorsInformation[i]['address']['latitude'];
        var endLongitude = doctorsInformation[i]['address']['longitude'];

        var distance = Geolocator.distanceBetween(
            startLatitude, startLongitude, endLatitude, endLongitude);

        if (distance <= 1500 && filterClinic(doctorsInformation[i])) {
          nearbyClinicsMarker.add(marker);
          nearbyClinicsInfo.add(doctorsInformation[i]);
        }
      }
    }

    return nearbyClinicsMarker;
  }

  clearFilter() {
    setState(() {
      clear = true;
      prevSelectedAccreditations.clear();
      prevSelectedServices.clear();
      prevSelectedDentalServices.clear();
      prevSelectedDiagnosticServices.clear();
      prevSelectedMedicalServices.clear();
    });
  }

  updateFilter() {
    prevSelectedAccreditations.clear();
    prevSelectedAccreditations.addAll(selectedAccreditations);

    prevSelectedDentalServices.clear();
    prevSelectedDiagnosticServices.clear();
    prevSelectedMedicalServices.clear();

    prevSelectedDentalServices.addAll(selectedDentalServices);
    prevSelectedDiagnosticServices.addAll(selectedDiagnosticServices);
    prevSelectedMedicalServices.addAll(selectedMedicalServices);

    prevSelectedServices.clear();

    prevSelectedServices.addAll(selectedDentalServices);
    prevSelectedServices.addAll(selectedDiagnosticServices);
    prevSelectedServices.addAll(selectedMedicalServices);
  }

  getPreviousFilter() {
    selectedAccreditations.clear();
    selectedAccreditations.addAll(prevSelectedAccreditations);

    selectedDentalServices.clear();
    selectedDiagnosticServices.clear();
    selectedMedicalServices.clear();

    selectedDentalServices.addAll(prevSelectedDentalServices);
    selectedDiagnosticServices.addAll(prevSelectedDiagnosticServices);
    selectedMedicalServices.addAll(prevSelectedMedicalServices);

    selectedServices.clear();
    selectedServices.addAll(prevSelectedDentalServices);
    selectedServices.addAll(prevSelectedDiagnosticServices);
    selectedServices.addAll(prevSelectedMedicalServices);
    log(name: "PREV ACCREDITATIONS", prevSelectedAccreditations.toString());
    log(name: "PREV SERVICES", prevSelectedServices.toString());
  }

  Stream clinicVerificationRequestStream = FirebaseFirestore.instance
      .collection('verificationRequests')
      .where('accountType', isEqualTo: 'clinic')
      .snapshots();

  Stream doctorClinicVerificationRequestStream = FirebaseFirestore.instance
      .collection('verificationRequests')
      .where('accountType', isEqualTo: 'independentDoctor')
      .snapshots();

  @override
  void initState() {
    super.initState();
    savedClinics = FirebaseAuth.instance.currentUser!.isAnonymous
        ? []
        : userData['savedClinics'];

    category = categories.first;

    scrollController.addListener(() {
      if (scrollController.position.pixels == 0) {
        setState(() {
          showCloseButton = true;
        });
      } else if (showCloseButton != false) {
        setState(() {
          showCloseButton = false;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      clinicsInformation = await getClinicInformation();
      doctorsInformation = await getDoctorInformation();
      services = await getServices();
      for (var element in services) {
        if (element.get('category') == category) {
          if (!mounted) return;
          setState(() {
            filteredServices.add(element.id);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    clinicNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;

    Widget clinicInfo() {
      return SizedBox(
        height: double.maxFinite,
        width: double.maxFinite,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  showClinicInfo = false;
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
                        clinicInformation['accountType'] == "clinic"
                            ? Container(
                                padding:
                                    const EdgeInsets.only(left: 20, right: 20),
                                height: deviceHeight * .35,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom:
                                        BorderSide(color: appColors['black']!),
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 20, bottom: 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              clinicInformation['clinicName'],
                                              style:
                                                  theme.textTheme.headlineSmall,
                                            ),
                                            // TODO: consider replacing futureBuilder with streamBuilder
                                            GestureDetector(
                                              onTap: () async {
                                                if (isAnonymous) {
                                                  showCreateAccountPrompt();
                                                } else {
                                                  if (savedClinics
                                                      .contains(clinicID)) {
                                                    savedClinics
                                                        .remove(clinicID);
                                                    log(savedClinics
                                                        .toString());
                                                  } else {
                                                    savedClinics.add(clinicID);
                                                    log(savedClinics
                                                        .toString());
                                                  }
                                                  await updateData(
                                                      "patients",
                                                      uid: uid,
                                                      {
                                                        "savedClinics":
                                                            savedClinics
                                                      }).then((value) async {
                                                    savedClinics = await getData(
                                                            "patients",
                                                            uid: uid,
                                                            field:
                                                                "savedClinics") ??
                                                        [];
                                                  });
                                                }
                                              },
                                              child: savedClinics
                                                      .contains(clinicID)
                                                  ? const Icon(Icons.bookmark)
                                                  : const Icon(
                                                      Icons.bookmark_outline),
                                            ),
                                          ],
                                        ),
                                        FutureBuilder(
                                          future: placemarkFromCoordinates(
                                              clinicInformation['address']
                                                  ['latitude'],
                                              clinicInformation['address']
                                                  ['longitude']),
                                          builder: (BuildContext context,
                                              AsyncSnapshot<dynamic> snapshot) {
                                            if (snapshot.hasData) {
                                              //log(snapshot.data.toString());
                                              var address = snapshot.data.first;

                                              return SizedBox(
                                                width: deviceWidth * .60,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8),
                                                  child: Text(
                                                    "${address.street}. ${address.subLocality}, ${address.locality}, ${address.administrativeArea}",
                                                    style: theme
                                                        .textTheme.labelSmall,
                                                  ),
                                                ),
                                              );
                                            } else {
                                              return const SizedBox.shrink();
                                            }
                                          },
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: Text(
                                            clinicInformation['phoneNumber'],
                                            style: theme.textTheme.labelSmall,
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: Text(
                                            clinicInformation['landline'],
                                            style: theme.textTheme.labelSmall,
                                          ),
                                        ),
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount:
                                              clinicInformation['serviceHours']
                                                  .length,
                                          itemBuilder: (context, index) {
                                            var serviceHour = clinicInformation[
                                                'serviceHours'][index];
                                            var day = serviceHour['day'];

                                            return Padding(
                                              padding: EdgeInsets.only(
                                                  right: 40,
                                                  top: index == 0 ? 8 : 5),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    day,
                                                    style: theme
                                                        .textTheme.labelSmall,
                                                  ),
                                                  Text(
                                                    "${formatTime(convertTime(serviceHour['openingHour']))}:${formatTime(serviceHour['openingMinute'])} ${serviceHour['openingMeridiem']} - ${formatTime(convertTime(serviceHour['closingHour']))}:${formatTime(serviceHour['closingMinute'])} ${serviceHour['closingMeridiem']}",
                                                    style: theme
                                                        .textTheme.labelSmall,
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10),
                                          child: Text("Services Offered",
                                              style:
                                                  theme.textTheme.labelSmall),
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
                                                  clinicInformation['services']
                                                      .length,
                                              itemBuilder:
                                                  (BuildContext context,
                                                      int index) {
                                                return Text(
                                                    "· ${clinicInformation['services'][index]}",
                                                    style: theme
                                                        .textTheme.labelSmall);
                                              }),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10),
                                          child: Text("Accreditations",
                                              style:
                                                  theme.textTheme.labelSmall),
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
                                              itemCount: clinicInformation[
                                                      'accreditations']
                                                  .length,
                                              itemBuilder:
                                                  (BuildContext context,
                                                      int index) {
                                                return Text(
                                                    "· ${clinicInformation['accreditations'][index]}",
                                                    style: theme
                                                        .textTheme.labelSmall);
                                              }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                padding:
                                    const EdgeInsets.only(left: 20, right: 20),
                                height: deviceHeight * .35,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom:
                                        BorderSide(color: appColors['black']!),
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 20, bottom: 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              clinicInformation['clinicName'],
                                              style:
                                                  theme.textTheme.headlineSmall,
                                            ),
                                          ],
                                        ),
                                        FutureBuilder(
                                          future: placemarkFromCoordinates(
                                              clinicInformation['address']
                                                  ['latitude'],
                                              clinicInformation['address']
                                                  ['longitude']),
                                          builder: (BuildContext context,
                                              AsyncSnapshot<dynamic> snapshot) {
                                            if (snapshot.hasData) {
                                              //log(snapshot.data.toString());
                                              var address = snapshot.data.first;

                                              return SizedBox(
                                                width: deviceWidth * .60,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8),
                                                  child: Text(
                                                    "${address.street}. ${address.subLocality}, ${address.locality}, ${address.administrativeArea}",
                                                    style: theme
                                                        .textTheme.labelSmall,
                                                  ),
                                                ),
                                              );
                                            } else {
                                              return const SizedBox.shrink();
                                            }
                                          },
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: Text(
                                            clinicInformation['contactNumber'],
                                            style: theme.textTheme.labelSmall,
                                          ),
                                        ),
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount:
                                              clinicInformation['serviceHours']
                                                  .length,
                                          itemBuilder: (context, index) {
                                            var serviceHour = clinicInformation[
                                                'serviceHours'][index];
                                            var day = serviceHour['day'];

                                            return Padding(
                                              padding: EdgeInsets.only(
                                                  right: 40,
                                                  top: index == 0 ? 8 : 5),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    day,
                                                    style: theme
                                                        .textTheme.labelSmall,
                                                  ),
                                                  Text(
                                                    "${formatTime(convertTime(serviceHour['openingHour']))}:${formatTime(serviceHour['openingMinute'])} ${serviceHour['openingMeridiem']} - ${formatTime(convertTime(serviceHour['closingHour']))}:${formatTime(serviceHour['closingMinute'])} ${serviceHour['closingMeridiem']}",
                                                    style: theme
                                                        .textTheme.labelSmall,
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10),
                                          child: Text("Services Offered",
                                              style:
                                                  theme.textTheme.labelSmall),
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
                                                  clinicInformation['services']
                                                      .length,
                                              itemBuilder:
                                                  (BuildContext context,
                                                      int index) {
                                                return Text(
                                                    "· ${clinicInformation['services'][index]}",
                                                    style: theme
                                                        .textTheme.labelSmall);
                                              }),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10),
                                          child: Text("Accreditations",
                                              style:
                                                  theme.textTheme.labelSmall),
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
                                              itemCount: clinicInformation[
                                                      'accreditations']
                                                  .length,
                                              itemBuilder:
                                                  (BuildContext context,
                                                      int index) {
                                                return Text(
                                                    "· ${clinicInformation['accreditations'][index]}",
                                                    style: theme
                                                        .textTheme.labelSmall);
                                              }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
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

                                if (clinicInformation['accountType'] ==
                                    'clinic') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ClinicAppointment(
                                        clinicInformation: clinicInformation,
                                      ),
                                    ),
                                  ).then((value) {
                                    if (value == "Maps") {
                                      if (!mounted) return;
                                      setState(() {
                                        showClinicInfo = false;
                                      });
                                    } else if (value == "Appointments") {
                                      widget.patientHome.changePanel(2);
                                    }
                                  });
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DoctorAppointment(
                                        doctorInformation: clinicInformation,
                                      ),
                                    ),
                                  ).then((value) {
                                    if (value == "Maps") {
                                      if (!mounted) return;
                                      setState(() {
                                        showClinicInfo = false;
                                      });
                                    } else if (value == "Appointments") {
                                      widget.patientHome.changePanel(2);
                                    }
                                  });
                                }
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
      );
    }

    Widget clinicList() {
      log(name: "LENGTH: ", nearbyClinicsInfo.length.toString());

      return Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Visibility(
              visible: showCloseButton,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      showClinicList = false;
                    });
                  },
                  child: CircleAvatar(
                    backgroundColor: appColors['primary'],
                    child: Icon(
                      Icons.arrow_downward,
                      color: appColors['black'],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: SizedBox(
                height: nearbyClinicsInfo.length > 1 ? 230 : null,
                child: SingleChildScrollView(
                  controller: scrollController,
                  scrollDirection: Axis.vertical,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 70),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: nearbyClinicsInfo.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> clinic = nearbyClinicsInfo[index];
                        String clinicName = clinic['clinicName'];
                        String accountType = clinic['accountType'];
                        String contact = accountType == "clinic"
                            ? "${clinic['phoneNumber']} / ${clinic['landline']}"
                            : "${clinic['contactNumber']}";

                        var latitude = clinic['address']['latitude'];
                        var longitude = clinic['address']['longitude'];

                        return FutureBuilder(
                          future: placemarkFromCoordinates(latitude, longitude),
                          builder: (BuildContext context,
                              AsyncSnapshot<dynamic> snapshot) {
                            if (snapshot.hasData) {
                              var address = snapshot.data.first;

                              return GestureDetector(
                                onTap: () {
                                  _mapController.move(
                                    LatLng(latitude, longitude),
                                    17.5,
                                  );
                                  _mapController.rotate(0);

                                  showClinicList = false;

                                  setState(
                                    () {
                                      searchArea = true;
                                    },
                                  );
                                },
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(top: index == 0 ? 0 : 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: appColors['primary'],
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          clinicName,
                                          style: getTextStyle(
                                            textColor: 'black',
                                            fontFamily: 'Inter',
                                            fontWeight: 600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: Text(
                                            "${address.street}. ${address.subLocality}, ${address.locality}, ${address.administrativeArea}",
                                            maxLines: 2,
                                            style: getTextStyle(
                                              textColor: 'black',
                                              fontFamily: 'Inter',
                                              fontWeight: 400,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: Text(
                                            contact,
                                            style: getTextStyle(
                                              textColor: 'black',
                                              fontFamily: 'Inter',
                                              fontWeight: 400,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      onEndDrawerChanged: (isOpened) {
        log(name: "DRAWER isOPEN:", isOpened.toString());
        log(name: "SELECTED ACCREDITATIONS", selectedAccreditations.toString());
        log(name: "SELECTED SERVICES", selectedServices.toString());
        if (applyFilter == false && !isOpened) {
          log(name: "DO APPLY", applyFilter.toString());
          getPreviousFilter();
        }
        applyFilter = false;

        //TODO: fix search filter visual bug (filter arrangement return to default whenever selecting new category)
      },
      endDrawer: drawerType == "filterDrawer"
          ? Padding(
              padding: const EdgeInsets.only(left: 80),
              child: Drawer(
                width: double.maxFinite,
                child: StatefulBuilder(builder: (context, filterSetState) {
                  return Padding(
                    padding: const EdgeInsets.only(
                        top: 20, left: 20, right: 20, bottom: 65),
                    child: Column(
                      children: [
                        Text(
                          "Search Filter",
                          style: theme.textTheme.headlineSmall,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Divider(
                              thickness: 1.5, color: appColors['black']),
                        ),
                        SizedBox(
                          width: double.maxFinite,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  "Accreditations",
                                  style: theme.textTheme.labelMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 5,
                                      mainAxisExtent: 48,
                                      crossAxisSpacing: 12,
                                    ),
                                    itemCount: accreditations.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      var accreditation = accreditations[index];

                                      return SizedBox(
                                        height: 48,
                                        child: TextButton(
                                          onPressed: () {
                                            filterSetState(() {
                                              if (selectedAccreditations
                                                  .contains(accreditation)) {
                                                selectedAccreditations
                                                    .remove(accreditation);
                                              } else {
                                                selectedAccreditations
                                                    .add(accreditation);
                                              }
                                            });
                                          },
                                          style: TextButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            backgroundColor:
                                                selectedAccreditations
                                                        .contains(accreditation)
                                                    ? appColors['accent']
                                                    : appColors['coolGray'],
                                          ),
                                          child: Text(
                                            accreditations[index],
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: selectedAccreditations
                                                      .contains(accreditation)
                                                  ? appColors['white']
                                                  : appColors['black'],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 50),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Services",
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w500),
                                    ),
                                    SizedBox(
                                      height: 24,
                                      width: 100,
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton(
                                          menuMaxHeight: 250,
                                          value: category,
                                          isExpanded: true,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                  overflow:
                                                      TextOverflow.visible),
                                          onChanged: (String? value) async {
                                            filterSetState(() {
                                              category = value!;
                                            });

                                            if (dentalServices.isEmpty &&
                                                diagnosticServices.isEmpty &&
                                                medicalServices.isEmpty) {
                                              for (var element in services) {
                                                if (element.get('category') ==
                                                    'Dental') {
                                                  dentalServices
                                                      .add(element.id);
                                                } else if (element
                                                        .get('category') ==
                                                    'Diagnostic/Imaging') {
                                                  diagnosticServices
                                                      .add(element.id);
                                                } else if (element
                                                        .get('category') ==
                                                    'Medical') {
                                                  medicalServices
                                                      .add(element.id);
                                                }
                                              }
                                            }

                                            filterSetState(() {
                                              if (category == 'Dental') {
                                                filteredServices =
                                                    dentalServices;
                                              } else if (category ==
                                                  'Diagnostic/Imaging') {
                                                filteredServices =
                                                    diagnosticServices;
                                              } else if (category ==
                                                  'Medical') {
                                                filteredServices =
                                                    medicalServices;
                                              }
                                            });

                                            log("Filtered Services: $filteredServices");
                                            log(
                                                name: "Selected Services",
                                                selectedServices.toString());
                                          },
                                          items: categories
                                              .map<DropdownMenuItem<String>>(
                                                  (String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 5,
                                      mainAxisExtent: 48,
                                      crossAxisSpacing: 10,
                                    ),
                                    itemCount: filteredServices.length > 6
                                        ? 6
                                        : filteredServices.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      String service = filteredServices[index];
                                      if (index <= 4) {
                                        return SizedBox(
                                          height: 48,
                                          child: TextButton(
                                            onPressed: () => filterSetState(() {
                                              if (category == 'Dental') {
                                                selectedServices =
                                                    selectedDentalServices;
                                              } else if (category ==
                                                  'Diagnostic/Imaging') {
                                                selectedServices =
                                                    selectedDiagnosticServices;
                                              } else if (category ==
                                                  'Medical') {
                                                selectedServices =
                                                    selectedMedicalServices;
                                              }
                                              log("filtered Selected Services: $selectedServices");

                                              if (selectedServices
                                                  .contains(service)) {
                                                selectedServices
                                                    .remove(service);

                                                if (!(selectedServices.length !=
                                                        index + 1 &&
                                                    index + 1 ==
                                                        filteredServices
                                                            .length)) {
                                                  for (int i = index;
                                                      i <
                                                          filteredServices
                                                                  .length -
                                                              1;
                                                      i++) {
                                                    if (selectedServices
                                                        .contains(
                                                            filteredServices[
                                                                i + 1])) {
                                                      filteredServices
                                                          .remove(service);
                                                      filteredServices.insert(
                                                          i + 1, service);
                                                    }
                                                  }
                                                }
                                              } else {
                                                selectedServices.add(service);
                                                filteredServices
                                                    .remove(service);
                                                filteredServices.insert(
                                                    selectedServices.length - 1,
                                                    service);
                                              }

                                              if (category == 'Dental') {
                                                selectedDentalServices =
                                                    selectedServices;
                                              } else if (category ==
                                                  'Diagnostic/Imaging') {
                                                selectedDiagnosticServices =
                                                    selectedServices;
                                              } else if (category ==
                                                  'Medical') {
                                                selectedMedicalServices =
                                                    selectedServices;
                                              }

                                              selectedServices = [];
                                              selectedServices.addAll(
                                                  selectedDentalServices);
                                              selectedServices.addAll(
                                                  selectedDiagnosticServices);
                                              selectedServices.addAll(
                                                  selectedMedicalServices);

                                              log("Selected Services: $selectedServices");
                                            }),
                                            style: TextButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              backgroundColor: selectedServices
                                                      .contains(service)
                                                  ? appColors['accent']
                                                  : appColors['coolGray'],
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 10, right: 10),
                                              child: Text(
                                                service,
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: selectedServices
                                                          .contains(service)
                                                      ? appColors['white']
                                                      : appColors['black'],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        return SizedBox(
                                          height: 48,
                                          child: TextButton(
                                            onPressed: () {
                                              showMore();
                                            },
                                            style: TextButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              backgroundColor:
                                                  appColors['coolGray'],
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 10, right: 10),
                                              child: Text(
                                                "More",
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: appColors['black'],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    }),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Divider(thickness: 1.5, color: appColors['black']),
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  log(
                                      name: "APPLY",
                                      selectedServices.toString());
                                  updateFilter();
                                  Scaffold.of(context).closeEndDrawer();
                                  setState(() {
                                    applyFilter = true;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  fixedSize: Size((deviceWidth - 130) / 2, 36),
                                  backgroundColor: appColors['accent'],
                                ),
                                child: Text(
                                  "Apply",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: appColors['white'],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  clearFilter();
                                  Scaffold.of(context).closeEndDrawer();
                                },
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  fixedSize: Size((deviceWidth - 130) / 2, 36),
                                  backgroundColor: appColors['gray145'],
                                ),
                                child: Text(
                                  "Clear",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: appColors['white'],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(left: 80),
              child: Drawer(
                width: double.maxFinite,
                child: StatefulBuilder(builder: (context, searchSetState) {
                  return Padding(
                    padding: const EdgeInsets.only(
                        top: 20, left: 20, right: 20, bottom: 65),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            reverse: true,
                            itemCount: matchedClinics.length,
                            itemBuilder: (context, index) {
                              Map<String, dynamic> clinic =
                                  matchedClinics[index];
                              String clinicName = clinic['clinicName'];
                              String accountType = clinic['accountType'];
                              String contact = accountType == "clinic"
                                  ? "${clinic['phoneNumber']} / ${clinic['landline']}"
                                  : "${clinic['contactNumber']}";

                              var latitude = clinic['address']['latitude'];
                              var longitude = clinic['address']['longitude'];

                              return FutureBuilder(
                                future: placemarkFromCoordinates(
                                    latitude, longitude),
                                builder: (BuildContext context,
                                    AsyncSnapshot<dynamic> snapshot) {
                                  if (snapshot.hasData) {
                                    var address = snapshot.data.first;

                                    return GestureDetector(
                                      onTap: () {
                                        _mapController.move(
                                          LatLng(latitude, longitude),
                                          17.5,
                                        );
                                        _mapController.rotate(0);

                                        clearFilter();

                                        Scaffold.of(context).closeEndDrawer();

                                        setState(
                                          () {
                                            searchArea = true;
                                            showClinicList = false;
                                          },
                                        );
                                      },
                                      child: Container(
                                        color: appColors['primary'],
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              child: Divider(
                                                color: appColors['gray192'],
                                                thickness: 0.25,
                                                height: 0,
                                              ),
                                            ),
                                            Text(
                                              clinicName,
                                              style: getTextStyle(
                                                textColor: 'black',
                                                fontFamily: 'Inter',
                                                fontWeight: 600,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 5),
                                              child: Text(
                                                "${address.street}. ${address.subLocality}, ${address.locality}, ${address.administrativeArea}",
                                                maxLines: 2,
                                                style: getTextStyle(
                                                  textColor: 'black',
                                                  fontFamily: 'Inter',
                                                  fontWeight: 400,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 5),
                                              child: Text(
                                                contact,
                                                style: getTextStyle(
                                                  textColor: 'black',
                                                  fontFamily: 'Inter',
                                                  fontWeight: 400,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: SizedBox(
                            height: 48,
                            child: TextFormField(
                              controller: clinicNameController,
                              decoration: InputDecoration(
                                fillColor: appColors['gray217'],
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.only(left: 10),
                                hintText: "Search Clinics...",
                                hintStyle:
                                    theme.textTheme.labelMedium?.copyWith(
                                  color: appColors['gray143'],
                                ),
                              ),
                              onChanged: (value) {
                                searchClinicByName(
                                    name: clinicNameController.text);
                                searchSetState(() {});
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Divider(
                            thickness: 1.5,
                            color: appColors['black'],
                            height: 0,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  //TODO: SEARCH
                                },
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  fixedSize: Size((deviceWidth - 130) / 2, 36),
                                  backgroundColor: appColors['accent'],
                                ),
                                child: Text(
                                  "Search",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: appColors['white'],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Scaffold.of(context).closeEndDrawer();
                                },
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  fixedSize: Size((deviceWidth - 130) / 2, 36),
                                  backgroundColor: appColors['gray145'],
                                ),
                                child: Text(
                                  "Cancel",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: appColors['white'],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
      body: FutureBuilder<Position>(
        future:
            determinePosition(), // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<Position> snapshot) {
          if (snapshot.hasData) {
            var currentLocation = snapshot.data as Position;

            return Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    onMapReady: () {
                      setState(() {
                        mapIsReady = true;
                      });
                    },
                    onPositionChanged: (position, hasGesture) {
                      if ((position.center!.latitude ==
                                  currentLocation.latitude &&
                              position.center!.longitude ==
                                  currentLocation.longitude) &&
                          !onCurrentLocation) {
                        setState(() {
                          onCurrentLocation = true;
                        });
                      } else if ((position.center!.latitude !=
                                  currentLocation.latitude &&
                              position.center!.longitude !=
                                  currentLocation.longitude) &&
                          onCurrentLocation) {
                        setState(() {
                          onCurrentLocation = false;
                        });
                      }
                    },
                    center: LatLng(
                        currentLocation.latitude, currentLocation.longitude),
                    zoom: 17.5,
                    minZoom: 10.0,
                    maxZoom: 18.0,
                  ),
                  nonRotatedChildren: [
                    AttributionWidget.defaultWidget(
                      source: 'OpenStreetMap contributors',
                      onSourceTapped: null,
                      alignment: Alignment.topRight,
                    ),
                    Positioned(
                      left: 0,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15, top: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: Image.asset(
                                  "assets/images/atlas-logo-small.png"),
                            ),
                            Text(
                              "ATLAS",
                              style: TextStyle(
                                  fontFamily: appFonts['Montserrat'],
                                  fontSize: 24.5,
                                  fontWeight: FontWeight.w500,
                                  color: appColors['gray145']),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 27,
                      bottom: 65,
                      child: FloatingActionButton.small(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Saved(),
                            ),
                          ).then((value) {
                            if (value != null) {
                              _mapController.move(
                                  LatLng(value['latitude'], value['longitude']),
                                  17.5);
                              _mapController.rotate(0);
                              setState(() {
                                searchArea = true;
                              });
                            }
                          });
                        },
                        heroTag: "btn4",
                        backgroundColor: appColors['primary'],
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        child: Icon(Icons.bookmark_border,
                            color: appColors['black'], size: 25),
                      ),
                    ),
                    Positioned(
                      right: 27,
                      bottom: 65,
                      child: Column(
                        children: [
                          FloatingActionButton(
                            onPressed: () {
                              setState(() {
                                drawerType = "searchDrawer";
                              });
                              Scaffold.of(context).openEndDrawer();
                            },
                            heroTag: "btn1",
                            backgroundColor: appColors['accent'],
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            child: Icon(Icons.search,
                                color: appColors['primary'], size: 30),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: FloatingActionButton.small(
                              onPressed: () {
                                _mapController.moveAndRotate(
                                    LatLng(currentLocation.latitude,
                                        currentLocation.longitude),
                                    17.5,
                                    0);
                              },
                              heroTag: "btn2",
                              backgroundColor: appColors['primary'],
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              child: Icon(
                                  onCurrentLocation
                                      ? Icons.my_location_outlined
                                      : Icons.location_searching,
                                  color: onCurrentLocation
                                      ? appColors['accent']
                                      : appColors['black'],
                                  size: 25),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: FloatingActionButton.small(
                              onPressed: () {
                                getPreviousFilter();
                                setState(() {
                                  drawerType = "filterDrawer";
                                });
                                Scaffold.of(context).openEndDrawer();
                              },
                              heroTag: "btn3",
                              backgroundColor: appColors['primary'],
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              child: Icon(Icons.filter_alt_outlined,
                                  color: appColors['black'], size: 25),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 65),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appColors['accent'],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.fromLTRB(15, 6, 15, 6),
                            shadowColor: appColors['black'],
                            elevation: 5,
                          ),
                          onPressed: () {
                            findNearbyClinics(_mapController.center);

                            setState(
                              () {
                                searchArea = true;
                                showClinicList = true;
                                showCloseButton = true;
                              },
                            );
                          },
                          child: Text(
                            "Search this area",
                            style: theme.textTheme.labelSmall!
                                .copyWith(color: appColors['primary']),
                          ),
                        ),
                      ),
                    ),
                  ],
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    StreamBuilder(
                        stream: clinicVerificationRequestStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Text('Something went wrong');
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox.expand();
                          }

                          for (int i = 0; i < clinicsInformation.length; i++) {
                            clinicsInformation[i]['requestDetail']
                                    ['verificationStatus'] =
                                snapshot.data!.docs[i]
                                    .data()['verificationStatus'];
                          }

                          return StreamBuilder(
                              stream: doctorClinicVerificationRequestStream,
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return const Text('Something went wrong');
                                }

                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const SizedBox.expand();
                                }

                                for (int i = 0;
                                    i < doctorsInformation.length;
                                    i++) {
                                  doctorsInformation[i]['requestDetail']
                                          ['verificationStatus'] =
                                      snapshot.data!.docs[i]
                                          .data()['verificationStatus'];
                                }

                                nearbyClinicsMarker.clear();

                                return MarkerLayer(
                                  markers: nearbyClinicsMarker.isEmpty ||
                                          searchArea ||
                                          applyFilter ||
                                          clear
                                      ? findNearbyClinics(
                                          mapIsReady
                                              ? _mapController.center
                                              : LatLng(currentLocation.latitude,
                                                  currentLocation.longitude),
                                        )
                                      : nearbyClinicsMarker,
                                );
                              });
                        }),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 15,
                          height: 15,
                          point: LatLng(currentLocation.latitude,
                              currentLocation.longitude),
                          rotate: false,
                          builder: (context) => Container(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: appColors['accent'],
                                border: Border.all(color: appColors['white']!)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                showClinicList && nearbyClinicsInfo.isNotEmpty
                    ? clinicList()
                    : const SizedBox.shrink(),
                showClinicInfo ? clinicInfo() : const SizedBox.shrink(),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: appColors['accent'],
                    size: 60,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text('Error: ${snapshot.error}'),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                        color: appColors['accent'], strokeWidth: 5),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('Awaiting result...'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
