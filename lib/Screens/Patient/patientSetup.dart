import 'dart:io';

import 'package:atlas/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../fileHandling.dart';
import '../../query.dart';
import '../../styles.dart';
import '../Setup/setupDone.dart';

class PatientSetup extends StatefulWidget {
  const PatientSetup({Key? key}) : super(key: key);

  @override
  State<PatientSetup> createState() => _PatientSetupState();
}

class _PatientSetupState extends State<PatientSetup> {
  final formKey = GlobalKey<FormState>();
  bool addressSelected = false;
  bool physicianNameSelected = false;

  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final contactNumberController = TextEditingController();

  bool firstNameSelected = false;
  bool middleNameSelected = false;
  bool lastNameSelected = false;
  bool birthdateSelected = false;
  bool contactNumberSelected = false;

  var birthDate;
  var isBirthDateInvalid = false;

  int step = 1;

  List<String> description = [
    "Enter your Basic Personal Information",
    "Upload your valid ID/s and a selfie to verify your account",
  ];

  List<PlatformFile?>? validIDs = [];
  List<PlatformFile?>? selfieFiles = [];

  Future<void> pickDate() async {
    await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2030),
    ).then((value) => setState(() {
          birthDate = value;
          validate();
        }));
  }

  validate() {
    formKey.currentState!.validate();
    setState(() {
      isBirthDateInvalid = birthDate == null;
    });

    return formKey.currentState!.validate() && !isBirthDateInvalid;
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
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
                          "First Name",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Focus(
                            onFocusChange: (hasFocus) => setState(() {
                              firstNameSelected = hasFocus;
                            }),
                            child: TextFormField(
                              controller: firstNameController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: appColors['coolGray'],
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none),
                                hintText: "First Name",
                                hintStyle:
                                    theme.textTheme.labelMedium?.copyWith(
                                  color: appColors['gray143'],
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 20),
                              ),
                              style: theme.textTheme.labelMedium?.copyWith(
                                height: 1,
                                color: firstNameSelected
                                    ? appColors['black']
                                    : appColors['gray143'],
                              ),
                              onChanged: (value) {
                                validate();
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (firstName) =>
                                  firstName != null && firstName.trim().isEmpty
                                      ? "First Name is required"
                                      : null,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp(r'[^\w\s^.]'),
                                    replacementString: ""),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Text(
                            "Middle Name",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Focus(
                            onFocusChange: (hasFocus) => setState(() {
                              middleNameSelected = hasFocus;
                            }),
                            child: TextFormField(
                              controller: middleNameController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: appColors['coolGray'],
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none),
                                hintText: "Middle Name",
                                hintStyle:
                                    theme.textTheme.labelMedium?.copyWith(
                                  color: appColors['gray143'],
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 20),
                              ),
                              style: theme.textTheme.labelMedium?.copyWith(
                                height: 1,
                                color: middleNameSelected
                                    ? appColors['black']
                                    : appColors['gray143'],
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp(r'[^\w\s^.]'),
                                    replacementString: ""),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Text(
                            "Last Name",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Focus(
                            onFocusChange: (hasFocus) => setState(() {
                              lastNameSelected = hasFocus;
                            }),
                            child: TextFormField(
                              controller: lastNameController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: appColors['coolGray'],
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none),
                                hintText: "Last Name",
                                hintStyle:
                                    theme.textTheme.labelMedium?.copyWith(
                                  color: appColors['gray143'],
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 20),
                              ),
                              style: theme.textTheme.labelMedium?.copyWith(
                                height: 1,
                                color: lastNameSelected
                                    ? appColors['black']
                                    : appColors['gray143'],
                              ),
                              onChanged: (value) {
                                validate();
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (lastName) =>
                                  lastName != null && lastName.trim().isEmpty
                                      ? "Last Name is required"
                                      : null,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp(r'[^\w\s^.]'),
                                    replacementString: ""),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            "Contact Number",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Focus(
                            onFocusChange: (hasFocus) => setState(() {
                              contactNumberSelected = hasFocus;
                            }),
                            child: TextFormField(
                              controller: contactNumberController,
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
                                    color: contactNumberSelected
                                        ? appColors['black']
                                        : appColors['gray143'],
                                    size: 20,
                                  ),
                                ),
                                hintText: "#### ### ####",
                                hintStyle:
                                    theme.textTheme.labelMedium?.copyWith(
                                  color: appColors['gray143'],
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 8),
                              ),
                              style: theme.textTheme.labelMedium?.copyWith(
                                height: 1,
                                color: contactNumberSelected
                                    ? appColors['black']
                                    : appColors['gray143'],
                              ),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(13),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                setState(() {
                                  contactNumberController.text =
                                      formatPhoneNumber(
                                          contactNumberController.text);

                                  contactNumberController.selection.end;
                                  contactNumberController.selection =
                                      TextSelection.fromPosition(TextPosition(
                                          offset: contactNumberController
                                              .text.length));
                                });

                                validate();
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (contactNumber) =>
                                  contactNumber != null &&
                                          contactNumber.trim().isEmpty
                                      ? "Contact Number is required"
                                      : null,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Text(
                            "Date of Birth",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: GestureDetector(
                            onTap: () => pickDate(),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                  color: appColors['coolGray'],
                                  borderRadius: BorderRadius.circular(15)),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 20, right: 15),
                                    child: Icon(
                                      Icons.calendar_today,
                                      color: appColors['gray143'],
                                    ),
                                  ),
                                  Text(
                                    birthDate == null
                                        ? "MM DD YYYY"
                                        : "${formatTime(birthDate.month)}-${formatTime(birthDate.day)}-${birthDate.year}",
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color: appColors['gray143'],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        isBirthDateInvalid
                            ? Padding(
                                padding:
                                    const EdgeInsets.only(left: 10, top: 5),
                                child: Text(
                                  "Birthdate is required",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: appColors['accent']),
                                ),
                              )
                            : const SizedBox.shrink(),
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Review Information entered, this\ncannot be changed later on",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      color: appColors['gray143'],
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
                  Text(
                    "Valid ID/s",
                    style: theme.textTheme.headlineSmall,
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: validIDs?.length,
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
                                      child: validIDs![index]!.extension ==
                                                  'jpg' ||
                                              validIDs![index]!.extension ==
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
                                                    '${validIDs![index]!.path}'),
                                              ),
                                            )
                                          : SfPdfViewer.file(
                                              File('${validIDs![index]!.path}'),
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
                                      child: Text(validIDs![index]!.name,
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
                                        validIDs?.remove(validIDs![index]);
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
                            validIDs!.addAll(files);
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: appColors['coolGray'],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: validIDs!.isNotEmpty
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
                                      color: appColors['gray143'],
                                    ),
                                  ),
                                  Text(
                                    "Upload files",
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(color: appColors['gray143']),
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
                            "Make sure the details of the ID/s is clearly visible",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: appColors['gray143'],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Icon(
                          Icons.priority_high,
                          size: 24,
                          color: appColors['gray143'],
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      "Selfie/s",
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: selfieFiles?.length,
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
                                      child: selfieFiles![index]!.extension ==
                                                  'jpg' ||
                                              selfieFiles![index]!.extension ==
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
                                                    '${selfieFiles![index]!.path}'),
                                              ),
                                            )
                                          : SfPdfViewer.file(
                                              File(
                                                  '${selfieFiles![index]!.path}'),
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
                                      child: Text(selfieFiles![index]!.name,
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
                                        selfieFiles
                                            ?.remove(selfieFiles![index]);
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
                            selfieFiles!.addAll(files);
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: appColors['coolGray'],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: selfieFiles!.isNotEmpty
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
                                      color: appColors['gray143'],
                                    ),
                                  ),
                                  Text(
                                    "Upload files",
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(color: appColors['gray143']),
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
                            "Hold your Valid ID in the photo",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: appColors['gray143'],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Icon(
                          Icons.priority_high,
                          size: 24,
                          color: appColors['gray143'],
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
                        Text(
                          "Step $step",
                          style: theme.textTheme.headlineSmall,
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
                  !(firstNameSelected ||
                              middleNameSelected ||
                              lastNameSelected ||
                              contactNumberSelected ||
                              birthdateSelected) &&
                          !isKeyboardVisible
                      ? Image.asset("assets/images/atlas-logo-small.png")
                      : const SizedBox.shrink(),
                  isKeyboardVisible
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: SizedBox(
                            width: (deviceWidth - 80),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                              ],
                            ),
                          ),
                        ),
                  isKeyboardVisible
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(
                              left: 10, right: 10, top: 15),
                          child: SizedBox(
                              width: deviceWidth,
                              height: 48,
                              child: Stack(
                                children: [
                                  step == 2
                                      ? Positioned(
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
                                                backgroundColor:
                                                    appColors['gray192'],
                                              ),
                                              child: Icon(
                                                Icons.arrow_back,
                                                color: appColors['white'],
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                  step == 1
                                      ? Positioned(
                                          right: 0,
                                          child: SizedBox(
                                            height: 48,
                                            width: (deviceWidth - 60) / 2,
                                            child: TextButton(
                                              onPressed: () async {
                                                setState(() {
                                                  Navigator.of(context)
                                                      .focusScopeNode
                                                      .unfocus();
                                                  if (step == 1 && validate()) {
                                                    step += 1;
                                                  } else {
                                                    var errorMessage =
                                                        "Please complete your basic information first.";
                                                    showSnackBar(errorMessage);
                                                  }
                                                });
                                              },
                                              style: TextButton.styleFrom(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                                backgroundColor:
                                                    appColors['gray192'],
                                              ),
                                              child: Icon(
                                                Icons.arrow_forward,
                                                color: appColors['white'],
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                  step == 2
                                      ? Positioned(
                                          right: 0,
                                          child: SizedBox(
                                            height: 48,
                                            width: (deviceWidth - 60) / 2,
                                            child: TextButton(
                                              onPressed: () async {
                                                var uid = FirebaseAuth
                                                    .instance.currentUser!.uid;
                                                var path = "users/$uid/";

                                                if (validIDs!.isNotEmpty &&
                                                    selfieFiles!.isNotEmpty) {
                                                  Map<String, dynamic>
                                                      verificationRequest = {
                                                    "feedback": [],
                                                    "verificationStatus":
                                                        "pending",
                                                    "latestVerification":
                                                        DateTime.now()
                                                            .toString(),
                                                    "accountType": "patient",
                                                    "uid": uid,
                                                  };

                                                  int verificationRequestID =
                                                      await addVerificationRequest(
                                                          verificationRequest);

                                                  var patientInformation = {
                                                    "firstName":
                                                        firstNameController
                                                            .text,
                                                    "middleName":
                                                        middleNameController
                                                            .text,
                                                    "lastName":
                                                        lastNameController.text,
                                                    "contactNumber":
                                                        contactNumberController
                                                            .text,
                                                    "birthdate":
                                                        "${formatTime(birthDate.month)}-${formatTime(birthDate.day)}-${birthDate.year}",
                                                    "verificationRequestID":
                                                        verificationRequestID,
                                                    "setupDone": true,
                                                    "savedClinics": [],
                                                  };

                                                  await addNotification(
                                                      uid: 'admin',
                                                      title:
                                                          "New Verification Request",
                                                      body:
                                                          "Hey there! A patient submitted a new Verification request. Review it Now!");

                                                  setupAccount(
                                                      patientInformation,
                                                      "patient");
                                                  uploadFile("$path/Valid IDs",
                                                      validIDs);
                                                  uploadFile("$path/Selfies",
                                                      selfieFiles);

                                                  if (!mounted) return;

                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          const SetupDone(),
                                                    ),
                                                  ).then((value) =>
                                                      Navigator.pop(context));
                                                } else {
                                                  var errorMessage =
                                                      "Please upload the following requirements first.";
                                                  showSnackBar(errorMessage);
                                                }
                                              },
                                              style: TextButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15)),
                                                  backgroundColor:
                                                      appColors['accent'],
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap),
                                              child: Text(
                                                "Finish",
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                        color:
                                                            appColors['white']),
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ],
                              )),
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
