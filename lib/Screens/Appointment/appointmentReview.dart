import 'dart:developer';

import 'package:flutter/material.dart';

import '../../global.dart';
import '../../query.dart';
import '../../styles.dart';
import '../../utils.dart';

class AppointmentReview extends StatefulWidget {
  final appointmentDetails;
  final accountType;
  const AppointmentReview(
      {Key? key, required this.appointmentDetails, required this.accountType})
      : super(key: key);

  @override
  State<AppointmentReview> createState() => _AppointmentReviewState();
}

class _AppointmentReviewState extends State<AppointmentReview> {
  String accountType = "";

  Map<String, dynamic> appointmentDetails = {};
  List<DateTime> timeSlots = [];
  List<DateTime> takenSlots = [];
  var pickedTime;

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

  generateTimeSlots() async {
    timeSlots = [];
    var date = DateTime.parse(appointmentDetails['date']);
    var weekday = formatWeekday(date.weekday);
    List serviceHours = await getData('${accountType}s',
        id: appointmentDetails['${accountType}ID'], field: 'serviceHours');
    Map<String, dynamic> serviceHour = {};

    log(serviceHours.toString());

    for (var element in serviceHours) {
      if (element['day'] == weekday) {
        serviceHour = element;
      }
    }

    DateTime openingTime = DateTime(date.year, date.month, date.day,
        serviceHour['openingHour'], serviceHour['openingMinute']);
    DateTime closingTime = DateTime(date.year, date.month, date.day,
        serviceHour['closingHour'], serviceHour['closingMinute']);

    int numberOfSlots = closingTime.difference(openingTime).inMinutes ~/ 30;

    DateTime startingTime = openingTime;

    for (int i = 0; i < numberOfSlots; i++) {
      timeSlots.add(startingTime);
      startingTime = startingTime.add(const Duration(minutes: 30));
    }

    takenSlots = await getTakenSlots(
        id: appointmentDetails['${accountType}ID'], accountType: accountType);
    log(name: "SLOTS", takenSlots.toString());
  }

  showRejectDialog() {
    var requestType = appointmentDetails['status'] == 'pending'
        ? "APPOINTMENT"
        : appointmentDetails['status'] == 'rescheduling'
            ? "RESCHEDULE"
            : "CANCELLATION";

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
                                    "Hey Doc! Are you sure you want to reject this $requestType request?",
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
                                          Navigator.pop(context);
                                          if (appointmentDetails['status'] ==
                                              'pending') {
                                            await updateData(
                                                '${accountType}Appointments',
                                                id: appointmentDetails[
                                                    '${accountType}AppointmentID'],
                                                {'status': "rejected"});
                                          } else {
                                            await updateData(
                                                '${accountType}Appointments',
                                                id: appointmentDetails[
                                                    '${accountType}AppointmentID'],
                                                {
                                                  'status': "accepted",
                                                  "rescheduleDate": "",
                                                  "reason": ""
                                                });
                                          }
                                          var patientUID = await getData(
                                              "patients",
                                              id: appointmentDetails[
                                                  'patientID'],
                                              field: "uid");

                                          await addNotification(
                                              uid: patientUID,
                                              title:
                                                  "$requestType Request Rejected",
                                              body:
                                                  "Hey there! Your $requestType Request has been Rejected. Review it Now!");
                                        },
                                        style: OutlinedButton.styleFrom(
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          "Yes, Reject Now",
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
        Navigator.pop(context);
      }
    });
  }

  showAppointmentSummaryDialog() {
    var requestType = appointmentDetails['status'] == 'pending'
        ? "Appointment"
        : appointmentDetails['status'] == 'rescheduling'
            ? "Reschedule"
            : "Cancellation";

    //Preferred Schedule
    DateTime preferredDate = DateTime.parse(appointmentDetails['date']);
    var preferredYear = preferredDate.year;
    var preferredMonth = formatMonth(preferredDate.month).substring(0, 3);
    var preferredDay = formatTime(preferredDate.day);
    var preferredStartHour = formatTime(convertTime(preferredDate.hour));
    var preferredStartMinute = formatTime(preferredDate.minute);
    var preferredStartMeridiem = getMeridiem(convertTime(preferredDate.hour));
    var preferredEndHour = formatTime(
        convertTime(preferredDate.add(const Duration(minutes: 30)).hour));
    var preferredEndMinute =
        formatTime(preferredDate.add(const Duration(minutes: 30)).minute);
    var preferredEndMeridiem = getMeridiem(
        convertTime(preferredDate.add(const Duration(minutes: 30)).hour));

    //Schedule
    var date = appointmentDetails['status'] == 'pending'
        ? pickedTime
        : appointmentDetails['status'] == 'rescheduling'
            ? DateTime.parse(appointmentDetails['rescheduleDate'])
            : preferredDate;
    var year = date.year;
    var month = formatMonth(date.month).substring(0, 3);
    var day = formatTime(date.day);
    var startHour = formatTime(convertTime(date.hour));
    var startMinute = formatTime(date.minute);
    var startMeridiem = getMeridiem(convertTime(date.hour));
    var endHour =
        formatTime(convertTime(date.add(const Duration(minutes: 30)).hour));
    var endMinute = formatTime(date.add(const Duration(minutes: 30)).minute);
    var endMeridiem =
        getMeridiem(convertTime(date.add(const Duration(minutes: 30)).hour));

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
                    appointmentDetails['status'] != 'cancellation'
                        ? Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder(
                                  future: getData("patients",
                                      id: appointmentDetails['patientID']),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.done) {
                                      var patientData = snapshot.data!;

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${patientData['firstName']}${patientData['middleName'].isNotEmpty ? " ${patientData['middleName']} " : " "}${patientData['lastName']}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 15),
                                            child: Text(
                                              "${appointmentDetails['service']}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 15),
                                            child: Text(
                                              appointmentDetails['description']
                                                      .isEmpty
                                                  ? "No Description"
                                                  : "${appointmentDetails['description']}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 15),
                                            child: Text(
                                              "${patientData['contactNumber']}",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ),
                                          accountType == 'clinic'
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 15),
                                                  child: FutureBuilder(
                                                    future: getData(
                                                      "doctors",
                                                      id: appointmentDetails[
                                                          'doctorID'],
                                                      field: "name",
                                                    ),
                                                    builder:
                                                        (context, snapshot) {
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .done) {
                                                        var name =
                                                            snapshot.data;

                                                        return Text(
                                                          "Dr. $name",
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium,
                                                        );
                                                      } else {
                                                        return Container(
                                                          height: 16,
                                                          width: 120,
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
                                                )
                                              : const SizedBox.shrink(),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 5),
                                            child: Column(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 15),
                                                  child: Text(
                                                    appointmentDetails[
                                                                'status'] ==
                                                            'pending'
                                                        ? "Preferred Schedule"
                                                        : "Approved Schedule",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 15),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                right: 20),
                                                        child: Text(
                                                          "$preferredMonth. $preferredDay, $preferredYear",
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium,
                                                        ),
                                                      ),
                                                      Text(
                                                        "$preferredStartHour:$preferredStartMinute ${preferredStartMeridiem.toUpperCase()} - $preferredEndHour:$preferredEndMinute ${preferredEndMeridiem.toUpperCase()}",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium,
                                                      )
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 20),
                                                  child: Divider(
                                                      color: appColors['black'],
                                                      height: 0,
                                                      thickness: 1),
                                                ),
                                                Text(
                                                  appointmentDetails[
                                                              'status'] ==
                                                          "pending"
                                                      ? "Schedule To Be Approved"
                                                      : "New Approved Schedule",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelMedium
                                                      ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 15),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                right: 20),
                                                        child: Text(
                                                          "$month. $day, $year",
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium,
                                                        ),
                                                      ),
                                                      Text(
                                                        "$startHour:$startMinute ${startMeridiem.toUpperCase()} - $endHour:$endMinute ${endMeridiem.toUpperCase()}",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium,
                                                      )
                                                    ],
                                                  ),
                                                ),
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
                                                color: appColors['coolGray'],
                                                borderRadius:
                                                    BorderRadius.circular(15)),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 5),
                                            child: Container(
                                              height: 16,
                                              width: 50,
                                              decoration: BoxDecoration(
                                                  color: appColors['coolGray'],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15)),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 5),
                                            child: Container(
                                              height: 16,
                                              width: 120,
                                              decoration: BoxDecoration(
                                                  color: appColors['coolGray'],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15)),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 5),
                                            child: Container(
                                              height: 16,
                                              width: 110,
                                              decoration: BoxDecoration(
                                                  color: appColors['coolGray'],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15)),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 5),
                                            child: Container(
                                              height: 16,
                                              width: 200,
                                              decoration: BoxDecoration(
                                                  color: appColors['coolGray'],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15)),
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
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
                                    "Hey Doc! Are you sure you want to Approve this $requestType Request?",
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
                                          if (appointmentDetails['status'] ==
                                              "rescheduling") {
                                            await updateData(
                                                '${accountType}Appointments',
                                                id: appointmentDetails[
                                                    '${accountType}AppointmentID'],
                                                {
                                                  "status": "accepted",
                                                  "date": appointmentDetails[
                                                      'rescheduleDate'],
                                                  "rescheduleDate": "",
                                                  "reason": ""
                                                });
                                          } else if (appointmentDetails[
                                                  'status'] ==
                                              "cancellation") {
                                            await updateData(
                                                '${accountType}Appointments',
                                                id: appointmentDetails[
                                                    '${accountType}AppointmentID'],
                                                {
                                                  "status": "cancelled",
                                                  "rescheduleDate": "",
                                                  "reason": ""
                                                });
                                          } else if (appointmentDetails[
                                                  'status'] ==
                                              "pending") {
                                            await updateData(
                                                '${accountType}Appointments',
                                                id: appointmentDetails[
                                                    '${accountType}AppointmentID'],
                                                {
                                                  "status": "accepted",
                                                  "date": pickedTime.toString()
                                                });
                                          }
                                          var patientUID = await getData(
                                              "patients",
                                              id: appointmentDetails[
                                                  'patientID'],
                                              field: "uid");

                                          await addNotification(
                                              uid: patientUID,
                                              title:
                                                  "$requestType Request Approved",
                                              body:
                                                  "Hey there! Your $requestType Request has been Approved. Review it Now!");

                                          if (appointmentDetails['status'] !=
                                              "cancellation") {
                                            var scheduledDate =
                                                appointmentDetails['status'] ==
                                                        "pending"
                                                    ? pickedTime
                                                    : DateTime.parse(
                                                        appointmentDetails[
                                                            'rescheduleDate']);

                                            var morningReminderTime =
                                                "${scheduledDate.toString().split(' ')[0]} 06:00:00.000";
                                            var hourBeforeReminderTime =
                                                "${scheduledDate.subtract(const Duration(hours: 1))}";

                                            await addNotification(
                                                uid: patientUID,
                                                title: "Appointment Reminder",
                                                body:
                                                    "Hey there! You have an Appointment Scheduled today. Get up, get ready, and don’t be late!",
                                                scheduleDate:
                                                    morningReminderTime);

                                            await addNotification(
                                                uid: patientUID,
                                                title: "Appointment Reminder",
                                                body:
                                                    "Hey there! Only 1 Hour left before your appointment. Make sure to be there ahead of time!",
                                                scheduleDate:
                                                    hourBeforeReminderTime);

                                            await addNotification(
                                                uid: uid,
                                                title: "Appointment Reminder",
                                                body:
                                                    "Hey Doc! You have Appointments Scheduled today. Get up, get ready, and don’t be late!",
                                                scheduleDate:
                                                    morningReminderTime);

                                            await addNotification(
                                                uid: uid,
                                                title: "Appointment Reminder",
                                                body:
                                                    "Hey Doc! Only 1 Hour left before your appointment. Be ready to cater for your Appointment!",
                                                scheduleDate:
                                                    hourBeforeReminderTime);
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          "Yes, Approve Now",
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
      if (value != 'back') {
        Navigator.pop(context);
        showApprovalSuccessfulPrompt();
      }
    });
  }

  showApprovalSuccessfulPrompt() {
    var requestType = appointmentDetails['status'] == 'pending'
        ? "Appointment"
        : appointmentDetails['status'] == 'rescheduling'
            ? "Reschedule"
            : "Cancellation";
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
                    Icons.event_available_outlined,
                    size: 84,
                    color: appColors['accent'],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Text(
                      "$requestType successfully approved!",
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
                        appointmentDetails['status'] == 'cancellation'
                            ? "The appointment is now removed from the Appointment Tab"
                            : "${appointmentDetails['status'] == 'pending' ? "Appointment" : "The new Schedule"} can now be viewed in the Appointment Tab",
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

  @override
  void initState() {
    accountType = widget.accountType;
    appointmentDetails = widget.appointmentDetails;
    log(appointmentDetails.toString());

    generateTimeSlots();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    DateTime date = DateTime.parse(appointmentDetails['date']);
    var month = formatMonth(date.month).substring(0, 3);
    var day = formatTime(date.day);
    var year = date.year;

    var startHour = formatTime(convertTime(date.hour));
    var startMinute = formatTime(date.minute);
    var startMeridiem = getMeridiem(convertTime(date.hour));
    var endHour =
        formatTime(convertTime(date.add(const Duration(minutes: 30)).hour));
    var endMinute = formatTime(date.add(const Duration(minutes: 30)).minute);
    var endMeridiem =
        getMeridiem(convertTime(date.add(const Duration(minutes: 30)).hour));

    var rescheduleDate = appointmentDetails['status'] == "rescheduling"
        ? DateTime.parse(appointmentDetails['rescheduleDate'])
        : date;
    var rescheduleDateYear = rescheduleDate.year;
    var rescheduleDateMonth = formatMonth(rescheduleDate.month).substring(0, 3);
    var rescheduleDateDay = formatTime(rescheduleDate.day);
    var rescheduleDateStartHour = formatTime(convertTime(rescheduleDate.hour));
    var rescheduleDateStartMinute = formatTime(rescheduleDate.minute);
    var rescheduleDateStartMeridiem =
        getMeridiem(convertTime(rescheduleDate.hour));
    var rescheduleDateEndHour = formatTime(
        convertTime(rescheduleDate.add(const Duration(minutes: 30)).hour));
    var rescheduleDateEndMinute =
        formatTime(rescheduleDate.add(const Duration(minutes: 30)).minute);
    var rescheduleDateEndMeridiem = getMeridiem(
        convertTime(rescheduleDate.add(const Duration(minutes: 30)).hour));

    var title = appointmentDetails['status'] == "pending"
        ? "Review New Appointment Request"
        : appointmentDetails['status'] == "rescheduling"
            ? "Review Reschedule Request"
            : "Review Cancellation Request";
    var color = appointmentDetails['status'] == "pending"
        ? appColors['accepted']
        : appointmentDetails['status'] == "rescheduling"
            ? appColors['pending']
            : appColors['accent'];

    return Scaffold(
      backgroundColor: appColors['accent'],
      body: SafeArea(
        child: Container(
          color: appColors['primary'],
          child: Column(
            children: [
              Container(
                color: appColors['primary'],
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 15),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Icon(Icons.arrow_back),
                        ),
                      ),
                      Text(
                        title,
                        style: textTheme.bodyMedium?.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(color: appColors['gray143'], height: 0, thickness: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: FutureBuilder(
                          future: getData("patients",
                              id: appointmentDetails['patientID']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              var patientData = snapshot.data!;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${patientData['firstName']}${patientData['middleName'].isNotEmpty ? " ${patientData['middleName']} " : " "}${patientData['lastName']}",
                                        style: textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(
                                      "${appointmentDetails['service']}",
                                      style: textTheme.bodyMedium?.copyWith(
                                          color: appColors['gray143']),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(
                                      appointmentDetails['description'].isEmpty
                                          ? "No Description"
                                          : "${appointmentDetails['description']}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              color: appColors['gray143']),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(
                                      "${patientData['contactNumber']}",
                                      style: textTheme.bodyMedium?.copyWith(
                                          color: appColors['gray143']),
                                    ),
                                  ),
                                  accountType == 'clinic'
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(top: 5),
                                          child: FutureBuilder(
                                            future: getData(
                                              "doctors",
                                              id: appointmentDetails[
                                                  'doctorID'],
                                              field: "name",
                                            ),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.done) {
                                                var name = snapshot.data;

                                                return Text(
                                                  "Dr. $name",
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
                                                          color: appColors[
                                                              'gray143']),
                                                );
                                              } else {
                                                return Container(
                                                  height: 16,
                                                  width: 120,
                                                  decoration: BoxDecoration(
                                                      color:
                                                          appColors['coolGray'],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15)),
                                                );
                                              }
                                            },
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                  Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 15),
                                        child: Text(
                                          appointmentDetails['status'] ==
                                                  'pending'
                                              ? "Preferred Schedule"
                                              : "Approved Schedule",
                                          style: textTheme.labelMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 15),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 20),
                                              child: Text(
                                                "$month. $day, $year",
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color: appColors[
                                                            'gray143']),
                                              ),
                                            ),
                                            Text(
                                              "$startHour:$startMinute ${startMeridiem.toUpperCase()} - $endHour:$endMinute ${endMeridiem.toUpperCase()}",
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                      color:
                                                          appColors['gray143']),
                                            )
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 20),
                                        child: Divider(
                                            color: appColors['black'],
                                            height: 0,
                                            thickness: 1),
                                      ),
                                    ],
                                  ),
                                  appointmentDetails['status'] == "pending"
                                      ? Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Center(
                                                child: Text(
                                                  "Schedule Available",
                                                  style: textTheme.labelMedium
                                                      ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 15),
                                                child: Text(
                                                  "Pick a time",
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600),
                                                ),
                                              ),
                                              StatefulBuilder(
                                                builder: (BuildContext context,
                                                    void Function(
                                                            void Function())
                                                        setState) {
                                                  return Expanded(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 14),

                                                      child: SingleChildScrollView(
                                                        scrollDirection: Axis.vertical,
                                                        child: GridView.builder(
                                                            shrinkWrap: true,
                                                            physics:
                                                                const NeverScrollableScrollPhysics(),
                                                            gridDelegate:
                                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                                              crossAxisCount: 3,
                                                              mainAxisSpacing: 5,
                                                              mainAxisExtent: 36,
                                                              crossAxisSpacing: 5,
                                                            ),
                                                            itemCount:
                                                                timeSlots.length,
                                                            itemBuilder:
                                                                (BuildContext
                                                                        context,
                                                                    int index) {
                                                              int startHour =
                                                                  convertTime(
                                                                      timeSlots[
                                                                              index]
                                                                          .hour);
                                                              int startMinute =
                                                                  timeSlots[index]
                                                                      .minute;

                                                              return GestureDetector(
                                                                onTap: () {
                                                                  setState(() {
                                                                    if (!takenSlots
                                                                        .contains(
                                                                            timeSlots[
                                                                                index])) {
                                                                      pickedTime =
                                                                          timeSlots[
                                                                              index];
                                                                    }
                                                                  });
                                                                },
                                                                child: Container(
                                                                  decoration: BoxDecoration(
                                                                      color: pickedTime == timeSlots[index]
                                                                          ? appColors['accent']
                                                                          : takenSlots.contains(timeSlots[index])
                                                                              ? appColors['gray192']
                                                                              : appColors['coolGray'],
                                                                      borderRadius: BorderRadius.circular(15)),
                                                                  child: Center(
                                                                    child: Text(
                                                                      "${formatTime(startHour)}:${formatTime(startMinute)} ${timeSlots[index].hour < 12 ? "am" : "pm"}",
                                                                      style: Theme.of(
                                                                              context)
                                                                          .textTheme
                                                                          .labelMedium
                                                                          ?.copyWith(
                                                                              color: pickedTime == timeSlots[index]
                                                                                  ? appColors['white']
                                                                                  : takenSlots.contains(timeSlots[index])
                                                                                      ? appColors['gray143']
                                                                                      : appColors['black'],
                                                                              fontWeight: pickedTime == timeSlots[index] ? FontWeight.w600 : FontWeight.w500),
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            }),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        )
                                      : appointmentDetails['status'] ==
                                              'rescheduling'
                                          ? Column(
                                              children: [
                                                Text(
                                                  "Reschedule Request",
                                                  style: textTheme.labelMedium
                                                      ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 15),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                right: 20),
                                                        child: Text(
                                                          "$rescheduleDateMonth. $rescheduleDateDay, $rescheduleDateYear",
                                                          style: textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                  color: appColors[
                                                                      'gray143']),
                                                        ),
                                                      ),
                                                      Text(
                                                        "$rescheduleDateStartHour:$rescheduleDateStartMinute ${rescheduleDateStartMeridiem.toUpperCase()} - $rescheduleDateEndHour:$rescheduleDateEndMinute ${rescheduleDateEndMeridiem.toUpperCase()}",
                                                        style: textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                                color: appColors[
                                                                    'gray143']),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 30),
                                                      child: Text(
                                                        "Reason for Rescheduling:",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelMedium
                                                            ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 15),
                                                      child: Row(
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    right: 15),
                                                            child: Icon(
                                                                Icons
                                                                    .notification_important_outlined,
                                                                color: appColors[
                                                                    'accent']),
                                                          ),
                                                          Text(
                                                            "${appointmentDetails['reason']}",
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  ],
                                                )
                                              ],
                                            )
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Reason for Cancellation:",
                                                  style: textTheme.labelMedium
                                                      ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 15),
                                                  child: Row(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                right: 15),
                                                        child: Icon(
                                                            Icons
                                                                .notification_important_outlined,
                                                            color: appColors[
                                                                'accent']),
                                                      ),
                                                      Text(
                                                        "${appointmentDetails['reason']}",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                ],
                              );
                            } else {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 18,
                                    width: 150,
                                    decoration: BoxDecoration(
                                        color: appColors['coolGray'],
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Container(
                                      height: 16,
                                      width: 50,
                                      decoration: BoxDecoration(
                                          color: appColors['coolGray'],
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Container(
                                      height: 16,
                                      width: 120,
                                      decoration: BoxDecoration(
                                          color: appColors['coolGray'],
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Container(
                                      height: 16,
                                      width: 110,
                                      decoration: BoxDecoration(
                                          color: appColors['coolGray'],
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Container(
                                      height: 16,
                                      width: 200,
                                      decoration: BoxDecoration(
                                          color: appColors['coolGray'],
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: SizedBox(
                          height: 48,
                          child: TextButton(
                            onPressed: () {
                              showRejectDialog();
                            },
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              backgroundColor: appColors['coolGray'],
                            ),
                            child: Text("Reject", style: textTheme.bodyMedium),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: SizedBox(
                          height: 48,
                          child: TextButton(
                            onPressed: () {
                              if (pickedTime != null ||
                                  appointmentDetails['status'] != 'pending') {
                                showAppointmentSummaryDialog();
                              } else {
                                showSnackBar(
                                    "Please pick a schedule to first.");
                              }
                            },
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              backgroundColor: appColors['accent'],
                            ),
                            child: Text(
                              "Approve",
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: appColors['white']),
                            ),
                          ),
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
    );
  }
}
