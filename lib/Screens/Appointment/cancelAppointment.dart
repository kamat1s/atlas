import 'package:flutter/material.dart ';

import '../../query.dart';
import '../../styles.dart';

class CancelAppointment extends StatefulWidget {
  final appointmentDetails;
  final appointmentType;
  const CancelAppointment(
      {Key? key,
      required this.appointmentDetails,
      required this.appointmentType})
      : super(key: key);

  @override
  State<CancelAppointment> createState() => _CancelAppointmentState();
}

class _CancelAppointmentState extends State<CancelAppointment> {
  String appointmentType = "";
  var reason;

  var otherReasonController = TextEditingController();

  List<String> reasons = [
    "Unavailable this day/time",
    "Financial problem",
    "Emergency",
    "Change of Service",
    "Change of Mind",
    "Others:"
  ];

  @override
  void dispose() {
    otherReasonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    reason = reasons.first;
    appointmentType = widget.appointmentType;
    super.initState();
  }

  showCancellationSubmittedPrompt() {
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
                      "Your Cancellation Request is Successfully Submitted!",
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
                        "Kindly wait for the ${appointmentType == "clinicAppointment" ? "clinic" : "doctor"} to review your request, be posted for updates",
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

  showCancellationDialog(var reason) {
    var appointmentDetails = widget.appointmentDetails;

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
                                    "Hey there! Are you sure you want to submit this CANCELLATION request?",
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

                                          var accountType = appointmentType ==
                                                  "clinicAppointment"
                                              ? "clinic"
                                              : "independentDoctor";

                                          var UID = await getData(
                                              "${accountType}s",
                                              id: appointmentDetails[
                                                  '${accountType}ID'],
                                              field: "uid");

                                          await addNotification(
                                              uid: UID,
                                              title: "New Cancellation Request",
                                              body:
                                                  "Hey Doc! A Patient submitted a Cancellation Request. Review it Now!");
                                          await updateData(
                                              '${accountType}Appointments',
                                              id: appointmentDetails[
                                                  '${accountType}AppointmentID'],
                                              {
                                                'status': "cancellation",
                                                "reason": reason
                                              });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          "Yes, Submit Now",
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
        showCancellationSubmittedPrompt();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                  padding: const EdgeInsets.only(top: 74, left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Reason for Cancellation:",
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reasons.length,
                          itemBuilder: (context, index) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Radio<String>(
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    fillColor: MaterialStateColor.resolveWith(
                                        (states) => appColors['accent']!),
                                    value: reasons[index],
                                    groupValue: reason,
                                    onChanged: (value) {
                                      setState(() {
                                        reason = value;
                                      });
                                    },
                                  ),
                                ),
                                Text(
                                  reasons[index],
                                  style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: reasons[index] == reason
                                          ? appColors['black']
                                          : appColors['gray143']),
                                ),
                                index == reasons.length - 1
                                    ? Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              right: 20, left: 5),
                                          child: SizedBox(
                                            height: 22,
                                            child: TextFormField(
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: reasons[index] ==
                                                              reason
                                                          ? appColors['black']
                                                          : appColors[
                                                              'gray143']),
                                              controller: otherReasonController,
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      color: appColors['gray143'],
                                    ),
                                children: const <TextSpan>[
                                  TextSpan(
                                      text: 'Cancellation request may or may '),
                                  TextSpan(
                                      text: 'NOT',
                                      style: TextStyle(
                                          decoration:
                                              TextDecoration.underline)),
                                  TextSpan(text: ' be\naccepted. '),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Icon(
                              Icons.priority_high,
                              color: appColors['gray143'],
                            )
                          ],
                        ),
                      ),
                    ],
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
                              Icons.close,
                              color: appColors['black'],
                            ),
                          ),
                        ),
                        Text(
                          "Cancellation Request",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            if (reason == reasons[reasons.length - 1]) {
                              showCancellationDialog(
                                  otherReasonController.text);
                            } else {
                              showCancellationDialog(reason);
                            }
                          },
                          child: Icon(
                            Icons.check,
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
}
