import 'dart:developer';
import 'dart:io';

import 'package:atlas/Classes/Doctor.dart';
import 'package:atlas/query.dart';
import 'package:atlas/styles.dart';
import 'package:atlas/fileHandling.dart';
import 'package:atlas/utils.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import 'package:photo_view/photo_view.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../global.dart';
import '../Setup/setupDone.dart';

import 'package:intl/intl.dart';

class ClinicSetup extends StatefulWidget {
  const ClinicSetup({Key? key}) : super(key: key);

  @override
  State<ClinicSetup> createState() => _ClinicSetupState();
}

class _ClinicSetupState extends State<ClinicSetup> {
  final formKey = GlobalKey<FormState>();
  final doctorFormKey = GlobalKey<FormState>();

  final _mapController = MapController();

  LatLng? newLocation;
  bool locationChanged = false;

  double zoom = 12.0;
  bool zoomChanged = false;

  final addressController = TextEditingController();
  final clinicNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final landlineController = TextEditingController();
  final physicianNameController = TextEditingController();

  bool addressSelected = false;
  bool clinicNameSelected = false;
  bool phoneNumberSelected = false;
  bool landlineSelected = false;
  bool physicianNameSelected = false;

  int step = 1;

  String path = "";

  List<String> clinicAvailableDays = [];

  List<String> clinicAccreditations = [];

  Map<String, bool> accreditations = {
    "DOH": false,
    "PhilHealth": false,
    "LTO": false,
    "POEA": false,
    "Kaiser": false,
    "DMW": false
  };

  List<String> description = [
    "Enter the Clinic's Basic Information",
    "Enter the Clinic's address",
    "Enter the Clinic's Schedule",
    "Enter the Clinic's Services and Accreditations",
    "Enter the Clinic's Physician Information",
    "Verify your Clinic by uploading business permit",
    "Review Clinic Information"
  ];

  List<PlatformFile?>? pickedFiles = [];

  List<String> categories = <String>[
    'Dental',
    'Diagnostic/Imaging',
    'Medical',
  ];

  final _dateTimeNow = DateTime.now();
  DateTime? _openingTime;
  DateTime? _closingTime;

  List<Map<String, dynamic>> clinicServiceHours = [];

  List<DocumentSnapshot> services = [];
  List prev = [];

  List<String> filteredServices = [];

  List<String> dentalServices = [];
  List<String> diagnosticServices = [];
  List<String> medicalServices = [];

  List<String> selectedServices = [];

  List<String> selectedDentalServices = [];
  List<String> selectedDiagnosticServices = [];
  List<String> selectedMedicalServices = [];

  List<Doctor> doctors = [];
  Map<String, bool> doctorAvailableDays = {
    "Monday": false,
    "Tuesday": false,
    "Wednesday": false,
    "Thursday": false,
    "Friday": false,
    "Saturday": false,
    "Sunday": false
  };
  List specializations = [];
  List<Map<String, dynamic>> doctorServiceHours = [];

  bool isSpecializationEmpty = false;
  bool noAvailableDays = false;

  Map<String, dynamic> clinicData = {
    "clinicName": "",
    "phoneNumber": "",
    "landline": "",
    "address": {},
    "serviceHours": [],
    "services": [],
    "accreditations": [],
    "doctors": [],
    "setupDone": false,
  };

  String? category;

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

  editTime(int index, var setState, {String timeOf = "clinic"}) {
    showDialog<void>(
      useSafeArea: true,
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        final deviceWidth = MediaQuery.of(context).size.width;

        List<Map<String, dynamic>> serviceHours = [];

        if (timeOf == "clinic") {
          serviceHours = clinicServiceHours;
        } else {
          log(timeOf);
          serviceHours = doctorServiceHours;
        }

        _openingTime = DateTime(
            _dateTimeNow.year,
            1,
            1,
            serviceHours[index]['openingHour'],
            serviceHours[index]['openingMinute']);
        _closingTime = DateTime(
            _dateTimeNow.year,
            1,
            1,
            serviceHours[index]['closingHour'],
            serviceHours[index]['closingMinute']);

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              insetPadding: const EdgeInsets.all(15),
              child: SizedBox(
                height: 220,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Set Time",
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      height: 48,
                                      width: (deviceWidth * .5) - 50,
                                      decoration: BoxDecoration(
                                        color: appColors['coolGray'],
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    TimePickerSpinner(
                                      time: _openingTime,
                                      is24HourMode: false,
                                      minutesInterval: 30,
                                      normalTextStyle:
                                          theme.textTheme.labelSmall?.copyWith(
                                              color: appColors['gray143']),
                                      highlightedTextStyle:
                                          theme.textTheme.labelSmall,
                                      alignment: Alignment.center,
                                      spacing: 15,
                                      itemHeight: 38,
                                      itemWidth: 20,
                                      isForce2Digits: true,
                                      onTimeChange: (time) {
                                        if (!mounted) return;
                                        setState(() {
                                          _openingTime = time;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                Text(
                                  "to",
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: appColors['gray143']),
                                ),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      height: 48,
                                      width: (deviceWidth * .5) - 50,
                                      decoration: BoxDecoration(
                                        color: appColors['coolGray'],
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    TimePickerSpinner(
                                      time: _closingTime,
                                      is24HourMode: false,
                                      minutesInterval: 30,
                                      normalTextStyle:
                                          theme.textTheme.labelSmall?.copyWith(
                                              color: appColors['gray143']),
                                      highlightedTextStyle:
                                          theme.textTheme.labelSmall,
                                      alignment: Alignment.center,
                                      spacing: 15,
                                      itemHeight: 38,
                                      itemWidth: 20,
                                      isForce2Digits: true,
                                      onTimeChange: (time) {
                                        if (!mounted) return;
                                        setState(() {
                                          _closingTime = time;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 40),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  "Cancel",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: appColors['black'],
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (timeOf == "clinic") {
                                    clinicServiceHours[index]['openingHour'] =
                                        _openingTime!.hour;

                                    clinicServiceHours[index]['openingMinute'] =
                                        _openingTime!.minute;

                                    clinicServiceHours[index]
                                            ['openingMeridiem'] =
                                        _openingTime!.hour < 12 ? "AM" : "PM";

                                    clinicServiceHours[index]['closingHour'] =
                                        _closingTime!.hour;

                                    clinicServiceHours[index]['closingMinute'] =
                                        _closingTime!.minute;

                                    clinicServiceHours[index]
                                            ['closingMeridiem'] =
                                        _closingTime!.hour < 12 ? "AM" : "PM";
                                  } else {
                                    doctorServiceHours[index]['openingHour'] =
                                        _openingTime!.hour;

                                    doctorServiceHours[index]['openingMinute'] =
                                        _openingTime!.minute;

                                    doctorServiceHours[index]
                                            ['openingMeridiem'] =
                                        _openingTime!.hour < 12 ? "AM" : "PM";

                                    doctorServiceHours[index]['closingHour'] =
                                        _closingTime!.hour;

                                    doctorServiceHours[index]['closingMinute'] =
                                        _closingTime!.minute;

                                    doctorServiceHours[index]
                                            ['closingMeridiem'] =
                                        _closingTime!.hour < 12 ? "AM" : "PM";

                                    log(doctorServiceHours[index].toString());
                                  }
                                });

                                Navigator.of(context).pop();
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: Text(
                                  "Apply",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: appColors['accent'],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  updateServices(String day) {
    if (clinicAvailableDays.contains(day)) {
      clinicServiceHours.removeAt(clinicAvailableDays.indexOf(day));
      clinicAvailableDays.remove(day);
    } else {
      var serviceHour = {
        "day": "",
        "openingHour": 7,
        "openingMinute": 0,
        "openingMeridiem": 'AM',
        "closingHour": 17,
        "closingMinute": 0,
        "closingMeridiem": 'PM'
      };

      serviceHour['day'] = day;
      clinicServiceHours.add(serviceHour);
      clinicAvailableDays.add(day);
    }
  }

  showSpecialization(var setState) {
    showDialog<void>(
      useSafeArea: true,
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        return WillPopScope(
          onWillPop: () async {
            specializations.clear();
            specializations.addAll(prev);
            return true;
          },
          child: StatefulBuilder(
            builder: (context, dialogSetState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                insetPadding: const EdgeInsets.all(15),
                child: SizedBox(
                  height: 285,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Specialization",
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 15, bottom: 45),
                            child: GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 10,
                                  mainAxisExtent: 48,
                                  crossAxisSpacing: 20,
                                ),
                                itemCount: selectedServices.length,
                                itemBuilder: (BuildContext context, int index) {
                                  String service = selectedServices[index];
                                  return SizedBox(
                                    height: 48,
                                    child: TextButton(
                                      onPressed: () {
                                        if (!mounted) return;
                                        dialogSetState(() {
                                          if (specializations
                                              .contains(service)) {
                                            specializations.remove(service);
                                          } else {
                                            specializations.add(service);
                                          }

                                          log("Specializations: $specializations");
                                        });
                                      },
                                      style: TextButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        backgroundColor:
                                            specializations.contains(service)
                                                ? appColors['accent']
                                                : appColors['coolGray'],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 10, right: 10),
                                        child: Text(
                                          service,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: specializations
                                                    .contains(service)
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 40),
                              child: GestureDetector(
                                onTap: () {
                                  specializations.clear();
                                  specializations.addAll(prev);
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  "Cancel",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: appColors['black'],
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  prev.clear();
                                  prev.addAll(specializations);

                                  isSpecializationEmpty =
                                      specializations.isEmpty;
                                });
                                Navigator.of(context).pop();
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: Text(
                                  "Apply",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: appColors['accent'],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  showDoctorInformation(int index, {String mode = "add"}) {
    showDialog<void>(
      useSafeArea: true,
      context: context,
      builder: (BuildContext context) {
        if (mode == "edit") {
          physicianNameController.text = doctors[index].name;

          specializations.clear();
          specializations.addAll(doctors[index].specializations);
          doctorServiceHours.clear();
          doctorServiceHours.addAll(doctors[index].serviceHours);
          doctorAvailableDays.clear();
          doctorAvailableDays.addAll(doctors[index].availableDays);

          doctors[index].printDetails();
        }

        return GestureDetector(
          onTap: () {
            Navigator.of(context).focusScopeNode.unfocus();
          },
          child: StatefulBuilder(builder: (context, setState) {
            return Dialog(
              backgroundColor: appColors['primary'],
              insetPadding: const EdgeInsets.all(0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 55, 20, 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 20),
                                child: Icon(Icons.account_circle_outlined),
                              ),
                              Expanded(
                                child: Form(
                                  key: doctorFormKey,
                                  child: SizedBox(
                                    child: Focus(
                                      onFocusChange: (hasFocus) {
                                        if (!mounted) return;
                                        setState(() {
                                          physicianNameSelected = hasFocus;
                                        });
                                      },
                                      child: TextFormField(
                                        controller: physicianNameController,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: physicianNameSelected
                                                  ? appColors['black']
                                                  : appColors['gray145'],
                                            ),
                                        decoration: InputDecoration(
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: appColors['gray231']!),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: appColors['black']!),
                                          ),
                                          hintText: "Physician Name",
                                          hintStyle: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  color: appColors['gray145']),
                                        ),
                                        validator: (name) =>
                                            name!.trim().isEmpty
                                                ? "Physician Name is required"
                                                : null,
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                          ListTile(
                            onTap: () => showSpecialization(setState),
                            contentPadding: EdgeInsets.zero,
                            minLeadingWidth: 24,
                            horizontalTitleGap: 20,
                            leading: Icon(Icons.medical_services_outlined,
                                color: appColors['black']),
                            title: Text(
                              "Add Specialization",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: appColors['gray145'],
                                  ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 44),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Divider(
                                    height: 0,
                                    color: isSpecializationEmpty
                                        ? appColors['accent']
                                        : appColors['gray231'],
                                    thickness: 1),
                                isSpecializationEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 5),
                                        child: Text(
                                          "Doctor must have at least one Specialization",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color: appColors['accent']),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 44),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: specializations.length,
                              itemBuilder: (context, index) {
                                var specialization = specializations[index];

                                return Column(
                                  children: [
                                    ListTile(
                                      title: Text(
                                        specialization,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                color: appColors['gray145'],
                                                fontWeight: FontWeight.w500),
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                      trailing: GestureDetector(
                                        child: Icon(Icons.close,
                                            color: appColors['gray145'],
                                            size: 16),
                                        onTap: () {
                                          setState(() {
                                            specializations
                                                .remove(specialization);
                                            isSpecializationEmpty =
                                                specializations.isEmpty;
                                          });
                                        },
                                      ),
                                    ),
                                    Divider(
                                        height: 0,
                                        color: appColors['gray231'],
                                        thickness: 1),
                                  ],
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Icon(
                                    Icons.watch_later_outlined,
                                    color: appColors['black'],
                                  ),
                                ),
                                Text(
                                  "Days the Doctor is In",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: appColors['black'],
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 44, top: 35),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: doctorServiceHours.length,
                              itemBuilder: (context, index) {
                                var serviceHour = doctorServiceHours[index];
                                String day = serviceHour['day'];

                                return Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            day,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                    color: appColors['gray145'],
                                                    fontWeight:
                                                        FontWeight.w500),
                                          ),
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () {
                                              if (doctorAvailableDays[day]!) {
                                                setState(() {
                                                  editTime(index, setState,
                                                      timeOf: "doctor");
                                                });
                                              }
                                            },
                                            child: Text(
                                              "${formatTime(convertTime(serviceHour['openingHour']))}:${formatTime(serviceHour['openingMinute'])} ${serviceHour['openingMeridiem']} - ${formatTime(convertTime(serviceHour['closingHour']))}:${formatTime(serviceHour['closingMinute'])} ${serviceHour['closingMeridiem']}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                      color:
                                                          appColors['gray145'],
                                                      fontWeight:
                                                          FontWeight.w500),
                                            ),
                                          ),
                                          Checkbox(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5)),
                                            activeColor: appColors['accent'],
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            value: doctorAvailableDays[day],
                                            onChanged: (value) {
                                              setState(() {
                                                doctorAvailableDays[day] =
                                                    value!;
                                                noAvailableDays =
                                                    !doctorAvailableDays
                                                        .containsValue(true);
                                              });
                                            },
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 44, top: 15),
                            child: Column(
                              children: [
                                Divider(
                                    height: 0,
                                    color: noAvailableDays
                                        ? appColors['accent']
                                        : appColors['gray231'],
                                    thickness: 1),
                                noAvailableDays
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 5),
                                        child: Text(
                                          "Doctor must have at least one day in the clinic.",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color: appColors['accent']),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Icon(Icons.close)),
                            ),
                            Text(
                              mode == "edit" ? "Edit" : "New Doctor",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                if (doctorFormKey.currentState!.mounted &&
                                    doctorFormKey.currentState!.validate() &&
                                    specializations.isNotEmpty &&
                                    doctorAvailableDays.containsValue(true)) {
                                  var physicianName =
                                      physicianNameController.text;

                                  var specializations = [];
                                  for (var element in this.specializations) {
                                    specializations.add(element);
                                  }
                                  Map<String, bool> availableDays = {};
                                  doctorAvailableDays.forEach((key, value) {
                                    availableDays[key] = value;
                                  });

                                  List<Map<String, dynamic>> serviceHours = [];
                                  for (var element in doctorServiceHours) {
                                    serviceHours.add(element);
                                  }

                                  Doctor doctor = Doctor(
                                      physicianName,
                                      specializations,
                                      availableDays,
                                      serviceHours);

                                  if (mode == "add") {
                                    doctors.add(doctor);
                                  } else {
                                    doctors[index] = doctor;
                                  }

                                  log(doctors[index].name);

                                  Navigator.pop(context);

                                  this.setState(() {});
                                }

                                setState(() {
                                  isSpecializationEmpty =
                                      specializations.isEmpty;
                                  noAvailableDays =
                                      !doctorAvailableDays.containsValue(true);
                                });
                              },
                              child: const Icon(Icons.check),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                          color: appColors['gray143'], height: 0, thickness: 1),
                    ],
                  ),
                ],
              ),
            );
          }),
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

  @override
  void initState() {
    super.initState();
    category = categories.first;
  }

  @override
  void dispose() {
    super.dispose();
    addressController.dispose();
    phoneNumberController.dispose();
    landlineController.dispose();
    clinicNameController.dispose();
    _mapController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    final progressBarWidth = (deviceWidth - 100) / description.length;

    Widget? getWidget() {
      if (step == 1) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
          child: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Clinic Name",
                          style: theme.textTheme.headlineSmall,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Focus(
                            onFocusChange: (hasFocus) => setState(() {
                              clinicNameSelected = hasFocus;
                            }),
                            child: TextFormField(
                              controller: clinicNameController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: appColors['coolGray'],
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none),
                                hintText: "E.g. Dela Cruz Clinic",
                                hintStyle:
                                    theme.textTheme.labelMedium?.copyWith(
                                  color: appColors['gray143'],
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 20),
                              ),
                              style: theme.textTheme.labelMedium?.copyWith(
                                height: 1,
                                color: clinicNameSelected
                                    ? appColors['black']
                                    : appColors['gray143'],
                              ),
                              onChanged: (value) {
                                formKey.currentState!.validate();
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (clinicName) => clinicName != null &&
                                      clinicName.trim().isEmpty
                                  ? "Clinic Name is required"
                                  : null,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            "Contact Number",
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            "Phone Number",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Focus(
                            onFocusChange: (hasFocus) => setState(() {
                              phoneNumberSelected = hasFocus;
                            }),
                            child: TextFormField(
                              controller: phoneNumberController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: appColors['coolGray'],
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(
                                      right: 15, left: 20),
                                  child: Icon(
                                    Icons.phone_android_rounded,
                                    color: phoneNumberSelected
                                        ? appColors['black']
                                        : appColors['gray143'],
                                    size: 20,
                                  ),
                                ),
                                hintText: "####-###-####",
                                hintStyle:
                                    theme.textTheme.labelMedium?.copyWith(
                                  color: appColors['gray143'],
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 8),
                              ),
                              style: theme.textTheme.labelMedium?.copyWith(
                                height: 1,
                                color: phoneNumberSelected
                                    ? appColors['black']
                                    : appColors['gray143'],
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(13),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                setState(() {
                                  phoneNumberController.text =
                                      formatPhoneNumber(
                                          phoneNumberController.text);

                                  phoneNumberController.selection.end;
                                  phoneNumberController.selection =
                                      TextSelection.fromPosition(TextPosition(
                                          offset: phoneNumberController
                                              .text.length));
                                });

                                formKey.currentState!.validate();
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (phoneNumber) => phoneNumber != null &&
                                      phoneNumber.trim().isEmpty
                                  ? "Phone number is required"
                                  : null,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Text(
                            "Landline",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Focus(
                            onFocusChange: (hasFocus) => setState(() {
                              landlineSelected = hasFocus;
                            }),
                            child: TextFormField(
                              controller: landlineController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: appColors['coolGray'],
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(
                                      right: 15, left: 20),
                                  child: Icon(
                                    Icons.phone,
                                    color: landlineSelected
                                        ? appColors['black']
                                        : appColors['gray143'],
                                    size: 20,
                                  ),
                                ),
                                hintText: "###-####",
                                hintStyle:
                                    theme.textTheme.labelMedium?.copyWith(
                                  color: appColors['gray143'],
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 8),
                              ),
                              style: theme.textTheme.labelMedium?.copyWith(
                                height: 1,
                                color: landlineSelected
                                    ? appColors['black']
                                    : appColors['gray143'],
                              ),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(8),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                setState(() {
                                  landlineController.text =
                                      formatLandline(
                                          landlineController.text);

                                  landlineController.selection.end;
                                  landlineController.selection =
                                      TextSelection.fromPosition(TextPosition(
                                          offset: landlineController
                                              .text.length));
                                });

                                formKey.currentState!.validate();
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (landline) =>
                                  landline != null && landline.trim().isEmpty
                                      ? "Landline is required"
                                      : null,
                            ),
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
      }
      if (step == 2) {
        return Stack(
          children: [
            FutureBuilder<Position>(
              future:
                  determinePosition(), // a previously-obtained Future<String> or null
              builder:
                  (BuildContext context, AsyncSnapshot<Position> snapshot) {
                if (snapshot.hasData) {
                  var currentLocation = snapshot.data as Position;

                  var location = locationChanged
                      ? newLocation
                      : LatLng(
                          currentLocation.latitude, currentLocation.longitude);

                  return FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: location,
                      zoom: zoom,
                      minZoom: 10.0,
                      maxZoom: 18.0,
                      onPositionChanged: (position, hasGesture) {
                        if (locationChanged != true) {
                          locationChanged = true;
                        }
                        setState(() {
                          newLocation = LatLng(position.center!.latitude,
                              position.center!.longitude);
                          zoom = _mapController.zoom;
                        });
                        log("Center ${position.center}");
                      },
                    ),
                    nonRotatedChildren: [
                      const Center(
                        child: Icon(
                          Icons.my_location,
                          size: 20,
                        ),
                      ),
                      AttributionWidget.defaultWidget(
                          source: 'OpenStreetMap contributors',
                          onSourceTapped: null,
                          alignment: Alignment.bottomRight),
                    ],
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
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
                              color: appColors['accent']),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(35, 20, 35, 0),
              child: Focus(
                onFocusChange: (hasFocus) => setState(() {
                  addressSelected = hasFocus;
                }),
                child: TextFormField(
                  controller: addressController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: appColors['coolGray'],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none),
                    suffixIcon: Icon(
                      Icons.pin_drop,
                      color: addressSelected
                          ? appColors['black']
                          : appColors['gray143'],
                      size: 20,
                    ),
                    labelText: "Clinic Address",
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      color: addressSelected
                          ? appColors['black']
                          : appColors['gray143'],
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 14),
                  ),
                  style: theme.textTheme.labelMedium?.copyWith(
                    height: 1,
                    color: addressSelected
                        ? appColors['black']
                        : appColors['gray143'],
                  ),
                  keyboardType: TextInputType.streetAddress,
                  autovalidateMode: addressController.text.isEmpty
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  onEditingComplete: () async {
                    await locationFromAddress(addressController.text)
                        .then((location) {
                      newLocation = LatLng(
                          location.first.latitude, location.first.longitude);

                      if (newLocation != null) {
                        _mapController.center.latitude = newLocation!.latitude;
                        _mapController.center.longitude =
                            newLocation!.longitude;
                        locationChanged = true;
                      }
                    }).onError((error, stackTrace) {
                      log(error.toString());
                    });

                    if (!mounted) return;
                    FocusScope.of(context).unfocus();
                    log("New Location: $newLocation");
                  },
                ),
              ),
            ),
          ],
        );
      } else if (step == 3) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
          child: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Available days",
                    style: theme.textTheme.headlineSmall,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                updateServices('Sunday');
                              }),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: clinicAvailableDays.contains('Sunday')
                                      ? appColors['accent']
                                      : appColors['coolGray'],
                                ),
                                child: Center(
                                  child: Text(
                                    "S",
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color:
                                          clinicAvailableDays.contains('Sunday')
                                              ? appColors['white']
                                              : appColors['black'],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                updateServices('Monday');
                              }),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: clinicAvailableDays.contains('Monday')
                                      ? appColors['accent']
                                      : appColors['coolGray'],
                                ),
                                child: Center(
                                  child: Text(
                                    "M",
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color:
                                          clinicAvailableDays.contains('Monday')
                                              ? appColors['white']
                                              : appColors['black'],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                updateServices('Tuesday');
                              }),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: clinicAvailableDays.contains('Tuesday')
                                      ? appColors['accent']
                                      : appColors['coolGray'],
                                ),
                                child: Center(
                                  child: Text(
                                    "T",
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color: clinicAvailableDays
                                              .contains('Tuesday')
                                          ? appColors['white']
                                          : appColors['black'],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                updateServices('Wednesday');
                              }),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color:
                                      clinicAvailableDays.contains('Wednesday')
                                          ? appColors['accent']
                                          : appColors['coolGray'],
                                ),
                                child: Center(
                                  child: Text(
                                    "W",
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color: clinicAvailableDays
                                              .contains('Wednesday')
                                          ? appColors['white']
                                          : appColors['black'],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                updateServices('Thursday');
                              }),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color:
                                      clinicAvailableDays.contains('Thursday')
                                          ? appColors['accent']
                                          : appColors['coolGray'],
                                ),
                                child: Center(
                                  child: Text(
                                    "T",
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color: clinicAvailableDays
                                              .contains('Thursday')
                                          ? appColors['white']
                                          : appColors['black'],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                updateServices('Friday');
                              }),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: clinicAvailableDays.contains('Friday')
                                      ? appColors['accent']
                                      : appColors['coolGray'],
                                ),
                                child: Center(
                                  child: Text(
                                    "F",
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color:
                                          clinicAvailableDays.contains('Friday')
                                              ? appColors['white']
                                              : appColors['black'],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                updateServices('Saturday');
                              }),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color:
                                      clinicAvailableDays.contains('Saturday')
                                          ? appColors['accent']
                                          : appColors['coolGray'],
                                ),
                                child: Center(
                                  child: Text(
                                    "S",
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color: clinicAvailableDays
                                              .contains('Saturday')
                                          ? appColors['white']
                                          : appColors['black'],
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
                  Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Text(
                      "Time",
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: clinicServiceHours.length,
                    itemBuilder: (context, index) {
                      String day = clinicServiceHours[index]['day'];

                      int openingHour =
                          convertTime(clinicServiceHours[index]['openingHour']);

                      String openingMinute =
                          clinicServiceHours[index]['openingMinute'] < 10
                              ? "0${clinicServiceHours[index]['openingMinute']}"
                              : "${clinicServiceHours[index]['openingMinute']}";
                      String openingMeridiem =
                          clinicServiceHours[index]['openingMeridiem'];

                      int closingHour =
                          convertTime(clinicServiceHours[index]['closingHour']);

                      String closingMinute =
                          clinicServiceHours[index]['closingMinute'] < 10
                              ? "0${clinicServiceHours[index]['closingMinute']}"
                              : "${clinicServiceHours[index]['closingMinute']}";

                      String closingMeridiem =
                          clinicServiceHours[index]['closingMeridiem'];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              day,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: GestureDetector(
                              onTap: () {
                                editTime(index, setState);
                              },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    height: 36,
                                    width: (deviceWidth * .5) - 50,
                                    decoration: BoxDecoration(
                                      color: appColors['coolGray'],
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 10),
                                          child: Text(
                                            "${openingHour < 10 ? "0$openingHour" : openingHour}  :  $openingMinute",
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: appColors['gray143'],
                                            ),
                                          ),
                                        ),
                                        Text(
                                          openingMeridiem,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: appColors['gray143'],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "to",
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(color: appColors['gray143']),
                                  ),
                                  Container(
                                    height: 36,
                                    width: (deviceWidth * .5) - 50,
                                    decoration: BoxDecoration(
                                      color: appColors['coolGray'],
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 10),
                                          child: Text(
                                            "${closingHour < 10 ? "0$closingHour" : closingHour}  :  $closingMinute",
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: appColors['gray143'],
                                            ),
                                          ),
                                        ),
                                        Text(
                                          closingMeridiem,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: appColors['gray143'],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      } else if (step == 4) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Services",
                      style: theme.textTheme.headlineSmall,
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
                              ?.copyWith(overflow: TextOverflow.visible),
                          onChanged: (String? value) async {
                            setState(() {
                              category = value!;
                            });

                            if (dentalServices.isEmpty &&
                                diagnosticServices.isEmpty &&
                                medicalServices.isEmpty) {
                              services = await getServices();

                              for (var element in services) {
                                if (element.get('category') == 'Dental') {
                                  dentalServices.add(element.id);
                                } else if (element.get('category') ==
                                    'Diagnostic/Imaging') {
                                  diagnosticServices.add(element.id);
                                } else if (element.get('category') ==
                                    'Medical') {
                                  medicalServices.add(element.id);
                                }
                              }
                            }

                            setState(() {
                              if (category == 'Dental') {
                                filteredServices = dentalServices;
                              } else if (category == 'Diagnostic/Imaging') {
                                filteredServices = diagnosticServices;
                              } else if (category == 'Medical') {
                                filteredServices = medicalServices;
                              }
                            });

                            log("Filtered Services: $filteredServices");
                          },
                          items: categories
                              .map<DropdownMenuItem<String>>((String value) {
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
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 48,
                        crossAxisSpacing: 20,
                      ),
                      itemCount: filteredServices.length > 6
                          ? 6
                          : filteredServices.length,
                      itemBuilder: (BuildContext context, int index) {
                        String service = filteredServices[index];
                        if (index <= 4) {
                          return SizedBox(
                            height: 48,
                            child: TextButton(
                              onPressed: () => setState(() {
                                if (category == 'Dental') {
                                  selectedServices = selectedDentalServices;
                                } else if (category == 'Diagnostic/Imaging') {
                                  selectedServices = selectedDiagnosticServices;
                                } else if (category == 'Medical') {
                                  selectedServices = selectedMedicalServices;
                                }

                                if (selectedServices.contains(service)) {
                                  selectedServices.remove(service);

                                  if (!(selectedServices.length != index + 1 &&
                                      index + 1 == filteredServices.length)) {
                                    for (int i = index;
                                        i < filteredServices.length - 1;
                                        i++) {
                                      if (selectedServices
                                          .contains(filteredServices[i + 1])) {
                                        filteredServices.remove(service);
                                        filteredServices.insert(i + 1, service);
                                      }
                                    }
                                  }
                                } else {
                                  selectedServices.add(service);
                                  filteredServices.remove(service);
                                  filteredServices.insert(
                                      selectedServices.length - 1, service);
                                }

                                if (category == 'Dental') {
                                  selectedDentalServices = selectedServices;
                                } else if (category == 'Diagnostic/Imaging') {
                                  selectedDiagnosticServices = selectedServices;
                                } else if (category == 'Medical') {
                                  selectedMedicalServices = selectedServices;
                                }

                                selectedServices = [];
                                selectedServices.addAll(selectedDentalServices);
                                selectedServices
                                    .addAll(selectedDiagnosticServices);
                                selectedServices
                                    .addAll(selectedMedicalServices);

                                log("Selected Services: $selectedServices");
                              }),
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
                                padding:
                                    const EdgeInsets.only(left: 10, right: 10),
                                child: Text(
                                  service,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: selectedServices.contains(service)
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
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                backgroundColor: appColors['coolGray'],
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 10, right: 10),
                                child: Text(
                                  "More",
                                  style: theme.textTheme.bodyMedium?.copyWith(
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
                Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Text(
                    "Accreditations",
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: accreditations['DOH'],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                      activeColor: appColors['accent'],
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.standard,
                      onChanged: (value) {
                        setState(() {
                          accreditations['DOH'] = value!;
                        });
                      },
                    ),
                    Text(
                      "DOH",
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: accreditations['PhilHealth'],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                      activeColor: appColors['accent'],
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.standard,
                      onChanged: (value) {
                        setState(
                          () {
                            accreditations['PhilHealth'] = value!;
                          },
                        );
                      },
                    ),
                    Text(
                      "PhilHealth",
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: accreditations['LTO'],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                      activeColor: appColors['accent'],
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.standard,
                      onChanged: (value) {
                        setState(() {
                          accreditations['LTO'] = value!;
                        });
                      },
                    ),
                    Text(
                      "LTO",
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: accreditations['POEA'],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                      activeColor: appColors['accent'],
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.standard,
                      onChanged: (value) {
                        setState(() {
                          accreditations['POEA'] = value!;
                        });
                      },
                    ),
                    Text(
                      "POEA",
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: accreditations['Kaiser'],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                      activeColor: appColors['accent'],
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.standard,
                      onChanged: (value) {
                        setState(() {
                          accreditations['Kaiser'] = value!;
                        });
                      },
                    ),
                    Text(
                      "Kaiser",
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: accreditations['DMW'],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                      activeColor: appColors['accent'],
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.standard,
                      onChanged: (value) {
                        setState(() {
                          accreditations['DMW'] = value!;
                        });
                      },
                    ),
                    Text(
                      "DMW",
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      } else if (step == 5) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
          child: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Physicians",
                    style: theme.textTheme.headlineSmall,
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          isSpecializationEmpty = false;
                          noAvailableDays = false;

                          showDoctorInformation(mode: "edit", index);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: appColors['coolGray'],
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                      padding: const EdgeInsets.all(15),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            doctors[index].name,
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 10),
                                            child: Text(
                                              doctors[index]
                                                  .specializations
                                                  .toString()
                                                  .substring(
                                                      1,
                                                      doctors[index]
                                                              .specializations
                                                              .toString()
                                                              .length -
                                                          1),
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                      color:
                                                          appColors["gray143"]),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 10),
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemBuilder: (context, i) {
                                                var serviceHour = doctors[index]
                                                    .serviceHours[i];

                                                return doctors[index]
                                                                .availableDays[
                                                            serviceHour[
                                                                "day"]] ==
                                                        true
                                                    ? Row(
                                                        children: [
                                                          Text(
                                                            serviceHour["day"],
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                                    color: appColors[
                                                                        'gray145'],
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500),
                                                          ),
                                                          const Spacer(),
                                                          Text(
                                                            "${formatTime(convertTime(serviceHour['openingHour']))}:${formatTime(serviceHour['openingMinute'])} ${serviceHour['openingMeridiem']} - ${formatTime(convertTime(serviceHour['closingHour']))}:${formatTime(serviceHour['closingMinute'])} ${serviceHour['closingMeridiem']}",
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                                    color: appColors[
                                                                        'gray145'],
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500),
                                                          ),
                                                        ],
                                                      )
                                                    : const SizedBox.shrink();
                                              },
                                              itemCount: doctors[index]
                                                  .serviceHours
                                                  .length,
                                            ),
                                          )
                                        ],
                                      )),
                                ),
                                GestureDetector(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 24),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: appColors['black'],
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      doctors.remove(doctors[index]);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: SizedBox(
                      height: doctors.isNotEmpty ? 40 : 96,
                      width: double.maxFinite,
                      child: TextButton(
                        onPressed: () {
                          prev.clear();

                          physicianNameController.clear();
                          specializations.clear();
                          doctorServiceHours.clear();
                          doctorAvailableDays.updateAll((key, value) => false);

                          for (var serviceHour in clinicServiceHours) {
                            doctorServiceHours.add({
                              "day": serviceHour['day'],
                              "openingHour": serviceHour['openingHour'],
                              "openingMinute": serviceHour['openingMinute'],
                              "openingMeridiem": serviceHour['openingMeridiem'],
                              "closingHour": serviceHour['closingHour'],
                              "closingMinute": serviceHour['closingMinute'],
                              "closingMeridiem": serviceHour['closingMeridiem']
                            });
                          }

                          showDoctorInformation(doctors.length);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: appColors['coolGray'],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: doctors.isNotEmpty
                            ? Icon(
                                Icons.add,
                                color: appColors['black'],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      "Tap to add information",
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                              color: appColors['gray143']),
                                    ),
                                  ),
                                  Icon(
                                    Icons.edit,
                                    size: 24,
                                    color: appColors['gray143'],
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else if (step == 6) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
          child: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Business Permit",
                    style: theme.textTheme.headlineSmall,
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pickedFiles?.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => showDialog<void>(
                          useSafeArea: true,
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                              insetPadding: const EdgeInsets.all(15),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 15,
                                    left: 15,
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
                                  Center(
                                    child: Container(
                                      clipBehavior: Clip.hardEdge,
                                      height: deviceHeight * .60,
                                      decoration: BoxDecoration(
                                        color: appColors['white'],
                                      ),
                                      child: pickedFiles![index]!.extension ==
                                                  'jpg' ||
                                              pickedFiles![index]!.extension ==
                                                  'png'
                                          ? PhotoView(
                                              backgroundDecoration:
                                                  BoxDecoration(
                                                color: appColors['gray192'],
                                              ),
                                              minScale: PhotoViewComputedScale
                                                      .contained *
                                                  1,
                                              imageProvider: FileImage(
                                                File(
                                                    '${pickedFiles![index]!.path}'),
                                              ),
                                            )
                                          : SfPdfViewer.file(
                                              File(
                                                  '${pickedFiles![index]!.path}'),
                                            ),
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Container(
                            height: 96,
                            decoration: BoxDecoration(
                              color: appColors['coolGray'],
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 24, right: 24),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: Text(pickedFiles![index]!.name,
                                          style: theme.textTheme.labelSmall),
                                    ),
                                  ),
                                  GestureDetector(
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: appColors['black'],
                                    ),
                                    onTap: () {
                                      setState(() {
                                        pickedFiles
                                            ?.remove(pickedFiles![index]);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: SizedBox(
                      height: 96,
                      width: double.maxFinite,
                      child: TextButton(
                        onPressed: () async {
                          var files = await selectFile(allowMultiple: true);
                          if (files == null || !mounted) return;

                          setState(() {
                            pickedFiles!.addAll(files);
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: appColors['coolGray'],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: pickedFiles!.isNotEmpty
                            ? Icon(
                                Icons.add,
                                color: appColors['black'],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Icon(
                                      Icons.file_upload_outlined,
                                      size: 24,
                                      color: appColors['black'],
                                    ),
                                  ),
                                  Text(
                                    "Upload files",
                                    style: theme.textTheme.labelMedium,
                                  )
                                ],
                              ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 9, 40, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Make sure the details of the permit is clearly visible",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: appColors['gray143'],
                            ),
                          ),
                        ),
                        Icon(
                          Icons.priority_high,
                          size: 24,
                          color: appColors['gray143'],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
          child: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Icon(
                          Icons.home_outlined,
                          size: 36,
                          color: appColors['black'],
                        ),
                      ),
                      Text(
                        clinicNameController.text,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  FutureBuilder(
                    future: placemarkFromCoordinates(
                        _mapController.center.latitude,
                        _mapController.center.longitude),
                    builder: (BuildContext context,
                        AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.hasData) {
                        var address = snapshot.data.first;

                        return Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 6, right: 16),
                                child: Icon(
                                  Icons.location_on_outlined,
                                  size: 24,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "${address.street}. ${address.subLocality}, ${address.locality}, ${address.administrativeArea}",
                                  style: theme.textTheme.labelMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 6, right: 16),
                          child: Icon(
                            Icons.phone_android_rounded,
                            size: 24,
                            color: appColors['black'],
                          ),
                        ),
                        Text(
                          phoneNumberController.text,
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 6, right: 16),
                          child: Icon(
                            Icons.phone,
                            size: 24,
                            color: appColors['black'],
                          ),
                        ),
                        Text(
                          landlineController.text,
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: clinicServiceHours.length,
                    itemBuilder: (context, index) {
                      var serviceHour = clinicServiceHours[index];
                      var day = serviceHour['day'];

                      return Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 20 : 15),
                        child: Row(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 6, right: 16),
                              child: Icon(
                                Icons.watch_later_outlined,
                                size: 24,
                                color: index == 0
                                    ? appColors['black']
                                    : appColors['primary'],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  day,
                                  style: theme.textTheme.labelMedium,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    "${formatTime(convertTime(serviceHour['openingHour']))}:${formatTime(serviceHour['openingMinute'])} ${serviceHour['openingMeridiem']} - ${formatTime(convertTime(serviceHour['closingHour']))}:${formatTime(serviceHour['closingMinute'])} ${serviceHour['closingMeridiem']}",
                                    style: theme.textTheme.labelMedium,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 6, right: 16),
                          child: Icon(
                            Icons.medical_services_outlined,
                            size: 24,
                            color: appColors['black'],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            selectedServices.toString().substring(
                                1, selectedServices.toString().length - 1),
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: clinicAccreditations.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 20 : 15),
                        child: Row(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 6, right: 16),
                              child: Icon(
                                Icons.handshake_outlined,
                                size: 24,
                                color: index == 0
                                    ? appColors['black']
                                    : appColors['primary'],
                              ),
                            ),
                            Text(
                              clinicAccreditations[index],
                              style: theme.textTheme.labelMedium,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      var doctor = doctors[index];

                      return Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 20 : 15),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 6, right: 16),
                              child: Icon(
                                Icons.account_circle_outlined,
                                size: 24,
                                color: index == 0
                                    ? appColors['black']
                                    : appColors['primary'],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctor.name,
                                    style: theme.textTheme.labelMedium,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(
                                      doctors[index]
                                          .specializations
                                          .toString()
                                          .substring(
                                              1,
                                              doctors[index]
                                                      .specializations
                                                      .toString()
                                                      .length -
                                                  1),
                                      style: theme.textTheme.labelMedium,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, i) {
                                        var serviceHour =
                                            doctors[index].serviceHours[i];

                                        return doctors[index].availableDays[
                                                    serviceHour["day"]] ==
                                                true
                                            ? Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 10),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      serviceHour["day"],
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelMedium,
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 5),
                                                      child: Text(
                                                        "${formatTime(convertTime(serviceHour['openingHour']))}:${formatTime(serviceHour['openingMinute'])} ${serviceHour['openingMeridiem']} - ${formatTime(convertTime(serviceHour['closingHour']))}:${formatTime(serviceHour['closingMinute'])} ${serviceHour['closingMeridiem']}",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelMedium,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : const SizedBox.shrink();
                                      },
                                      itemCount:
                                          doctors[index].serviceHours.length,
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).focusScopeNode.unfocus();
      },
      child: Scaffold(
        backgroundColor: appColors['accent'],
        body: SafeArea(
          child: Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              color: appColors['primary'],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 30, 15, 20),
              child: Column(
                children: [
                  Center(
                    child: Column(
                      children: [
                        Visibility(
                          visible: step < 7,
                          child: Text(
                            "Step $step",
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Text(
                            textAlign: TextAlign.center,
                            description[step - 1],
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 24),
                      child: Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: appColors['coolGray']!, width: 1.5),
                        ),
                        child: getWidget(),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      children: [
                        Visibility(
                          visible: !(addressSelected ||
                              clinicNameSelected ||
                              phoneNumberSelected ||
                              landlineSelected),
                          child:
                              Image.asset("assets/images/atlas-logo-small.png"),
                        ),
                        Visibility(
                          visible: step < 7,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: SizedBox(
                              width: (deviceWidth - 80),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    width: progressBarWidth,
                                    height: step == 1 ? 5 : 1,
                                    color: step == 1
                                        ? appColors['accent']
                                        : appColors['black'],
                                  ),
                                  Container(
                                    width: progressBarWidth,
                                    height: step == 2 ? 5 : 1,
                                    color: step == 2
                                        ? appColors['accent']
                                        : appColors['black'],
                                  ),
                                  Container(
                                    width: progressBarWidth,
                                    height: step == 3 ? 5 : 1,
                                    color: step == 3
                                        ? appColors['accent']
                                        : appColors['black'],
                                  ),
                                  Container(
                                    width: progressBarWidth,
                                    height: step == 4 ? 5 : 1,
                                    color: step == 4
                                        ? appColors['accent']
                                        : appColors['black'],
                                  ),
                                  Container(
                                    width: progressBarWidth,
                                    height: step == 5 ? 5 : 1,
                                    color: step == 5
                                        ? appColors['accent']
                                        : appColors['black'],
                                  ),
                                  Container(
                                    width: progressBarWidth,
                                    height: step == 6 ? 5 : 1,
                                    color: step == 6
                                        ? appColors['accent']
                                        : appColors['black'],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 10, right: 10, top: 15),
                          child: SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: Stack(
                              children: [
                                Visibility(
                                  visible: step > 1,
                                  child: Positioned(
                                    left: 0,
                                    child: SizedBox(
                                      height: 48,
                                      width: (deviceWidth - 60) / 2,
                                      child: TextButton(
                                        onPressed: () => setState(() {
                                          Navigator.of(context)
                                              .focusScopeNode
                                              .unfocus();
                                          if (step > 1) {
                                            step -= 1;
                                          }
                                        }),
                                        style: TextButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          backgroundColor: appColors['gray192'],
                                        ),
                                        child: Icon(
                                          Icons.arrow_back,
                                          color: appColors['white'],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: step < 6,
                                  child: Positioned(
                                    right: 0,
                                    child: SizedBox(
                                      height: 48,
                                      width: (deviceWidth - 60) / 2,
                                      child: TextButton(
                                        onPressed: () async {
                                          services = await getServices();

                                          setState(() {
                                            Navigator.of(context)
                                                .focusScopeNode
                                                .unfocus();
                                            if (step < 6) {
                                              if (step == 1 &&
                                                      formKey.currentState!
                                                          .validate() ||
                                                  step == 2 &&
                                                      locationChanged ||
                                                  step == 3 &&
                                                      clinicAvailableDays
                                                          .isNotEmpty ||
                                                  step == 4 &&
                                                      selectedServices
                                                          .isNotEmpty ||
                                                  step == 5) {
                                                step += 1;
                                              } else {
                                                String errorMessage = "";

                                                if (step == 1) {
                                                  errorMessage =
                                                      "Please complete your basic information first.";
                                                } else if (step == 2) {
                                                  errorMessage =
                                                      "Please setup your Clinic's address first.";
                                                } else if (step == 3) {
                                                  errorMessage =
                                                      "Please select your Clinic's available days and service hours first.";
                                                } else if (step == 4) {
                                                  errorMessage =
                                                      "Please select your Clinic's offered services first.";
                                                }

                                                showSnackBar(errorMessage);
                                              }
                                              if (step == 4 &&
                                                  filteredServices.isEmpty) {
                                                for (var element in services) {
                                                  if (element.get('category') ==
                                                      category) {
                                                    setState(() {
                                                      filteredServices
                                                          .add(element.id);
                                                    });
                                                  }
                                                }
                                              }
                                            }
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          backgroundColor: appColors['gray192'],
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward,
                                          color: appColors['white'],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: step >= 6,
                                  child: Positioned(
                                    right: 0,
                                    child: SizedBox(
                                      height: 48,
                                      width: (deviceWidth - 60) / 2,
                                      child: TextButton(
                                        onPressed: () async {
                                          var uid = FirebaseAuth
                                              .instance.currentUser!.uid;

                                          if (step == 6) {
                                            if (pickedFiles!.isNotEmpty) {
                                              clinicAccreditations.clear();

                                              accreditations
                                                  .forEach((key, value) {
                                                if (value) {
                                                  clinicAccreditations.add(key);
                                                }
                                              });

                                              setState(() {
                                                step += 1;
                                              });
                                            } else {
                                              var errorMessage =
                                                  "Please upload business permit first.";
                                              showSnackBar(errorMessage);
                                            }
                                          } else {
                                            path =
                                                "users/$uid/business permit/";

                                            List<Map<String, dynamic>> doctors =
                                                [];
                                            for (Doctor doctor
                                                in this.doctors) {
                                              var serviceHours = [];
                                              for (var serviceHour
                                                  in doctor.serviceHours) {
                                                if (doctor.availableDays[
                                                        serviceHour["day"]] ==
                                                    true) {
                                                  serviceHours.add(serviceHour);
                                                }
                                              }

                                              doctors.add({
                                                "name": doctor.name,
                                                "specializations":
                                                    doctor.specializations,
                                                "availableDays":
                                                    doctor.availableDays,
                                                "serviceHours": serviceHours
                                              });
                                            }

                                            List<int> doctorsID = [];
                                            doctorsID = await addDoctors(
                                                doctors, userData["clinicID"]);

                                            clinicData["clinicName"] =
                                                clinicNameController.text;
                                            clinicData['address'] = {
                                              "latitude": _mapController
                                                  .center.latitude,
                                              "longitude": _mapController
                                                  .center.longitude,
                                            };

                                            Map<String, dynamic>
                                                verificationRequest = {
                                              "feedback": [],
                                              "verificationStatus": "pending",
                                              "latestVerification":
                                                  DateTime.now().toString(),
                                              "accountType": "clinic",
                                              "uid": uid,
                                            };

                                            int verificationRequestID =
                                                await addVerificationRequest(
                                                    verificationRequest);

                                            clinicData['phoneNumber'] =
                                                phoneNumberController.text;
                                            clinicData['landline'] =
                                                landlineController.text;
                                            clinicData['serviceHours'] =
                                                clinicServiceHours;
                                            clinicData['services'] =
                                                selectedServices;
                                            clinicData['accreditations'] =
                                                clinicAccreditations;
                                            clinicData['doctors'] = doctorsID;
                                            clinicData['setupDone'] = true;
                                            clinicData[
                                                    'verificationRequestID'] =
                                                verificationRequestID;

                                            log(clinicData.toString());

                                            await addNotification(
                                                uid: 'admin',
                                                title:
                                                    "New Verification Request",
                                                body:
                                                    "Hey there! A clinic submitted a new Verification request. Review it Now!");

                                            setupAccount(clinicData, "clinic");
                                            uploadFile(path, pickedFiles);

                                            if (!mounted) return;

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const SetupDone(),
                                              ),
                                            ).then((value) =>
                                                Navigator.pop(context));
                                          }
                                        },
                                        style: TextButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          backgroundColor: appColors['accent'],
                                        ),
                                        child: Text(
                                          step == 6 ? "Finish" : "Confirm",
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: appColors['white'],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
