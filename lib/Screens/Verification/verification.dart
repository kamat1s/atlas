import 'dart:io';

import 'package:atlas/query.dart';
import 'package:atlas/styles.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../fileHandling.dart';
import '../../global.dart';

class Verification extends StatefulWidget {
  final accountType;
  const Verification({Key? key, required this.accountType}) : super(key: key);

  @override
  State<Verification> createState() => _VerificationState();
}

class _VerificationState extends State<Verification> {
  List<PlatformFile?>? validIDs = [];
  List<PlatformFile?>? selfieFiles = [];
  List<PlatformFile?>? businessPermitFiles = [];
  List<PlatformFile?>? medicalLicenseFiles = [];

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

  showSelectedFiles() {
    List<PlatformFile?> files = [];
    if (widget.accountType == "patient") {
      files.addAll(validIDs!);
      files.addAll(selfieFiles!);
    } else if (widget.accountType == "clinic") {
      files.addAll(businessPermitFiles!);
    } else {
      files.addAll(medicalLicenseFiles!);
    }

    showDialog<bool>(
      useSafeArea: true,
      context: context,
      builder: (BuildContext context) {
        var deviceHeight = MediaQuery.of(context).size.height;

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              clipBehavior: Clip.hardEdge,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              insetPadding: const EdgeInsets.all(15),
              child: SizedBox(
                height: 450,
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50, bottom: 130),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: files.length,
                              itemBuilder: (context, index) {
                                var fileName = files[index]!.name;
                                var fileType = files[index]!.extension;
                                var filePath = files[index]!.path;

                                return Column(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                          top: index == 0 ? 16 : 0,
                                          left: 6,
                                          right: 6),
                                      child: ListTile(
                                        title: Text(fileName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                        leading: Text("${index + 1}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                        visualDensity: VisualDensity.compact,
                                        trailing: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 20),
                                          child: Text(fileType!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600)),
                                        ),
                                        horizontalTitleGap: 0,
                                        onTap: () async {
                                          showDialog<void>(
                                            useSafeArea: true,
                                            context: context,
                                            builder: (BuildContext context) {
                                              return Dialog(
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25)),
                                                insetPadding:
                                                    const EdgeInsets.all(15),
                                                child: Stack(
                                                  children: [
                                                    Positioned(
                                                      top: 15,
                                                      left: 15,
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child: Icon(
                                                          Icons.arrow_back,
                                                          color: appColors[
                                                              'black'],
                                                        ),
                                                      ),
                                                    ),
                                                    Center(
                                                      child: Container(
                                                        clipBehavior:
                                                            Clip.hardEdge,
                                                        height:
                                                            deviceHeight * .60,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: appColors[
                                                              'white'],
                                                        ),
                                                        child: fileType ==
                                                                    'jpg' ||
                                                                fileType ==
                                                                    'png'
                                                            ? PhotoView(
                                                                backgroundDecoration:
                                                                    BoxDecoration(
                                                                  color: appColors[
                                                                      'gray192'],
                                                                ),
                                                                minScale:
                                                                    PhotoViewComputedScale
                                                                            .contained *
                                                                        1,
                                                                imageProvider:
                                                                    FileImage(
                                                                  File(
                                                                      filePath!),
                                                                ),
                                                              )
                                                            : SfPdfViewer.file(
                                                                File(filePath!),
                                                              ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child:
                                          Divider(color: appColors['gray143']),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.maxFinite,
                      color: appColors['white'],
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              "Files",
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            child:
                                Divider(color: appColors['gray143'], height: 0),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 131,
                        decoration: BoxDecoration(
                            color: appColors['accent'],
                            borderRadius: BorderRadius.circular(15)),
                        child: Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(30, 15, 39, 17),
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
                                      "Hey there! Are you satisfied with these files you are uploading?",
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
                              padding:
                                  const EdgeInsets.only(left: 20, right: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                            Navigator.pop(context, false);
                                          },
                                          style: OutlinedButton.styleFrom(
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
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
                                            var path = "users/$uid";

                                            await deleteFiles(
                                                path, widget.accountType);
                                            if (widget.accountType ==
                                                "patient") {
                                              await uploadFile(
                                                  "$path/Valid IDs", validIDs);
                                              await uploadFile(
                                                  "$path/Selfies", selfieFiles);
                                            } else if (widget.accountType ==
                                                "clinic") {
                                              await uploadFile(
                                                  "$path/business permit",
                                                  businessPermitFiles);
                                            } else {
                                              await uploadFile(
                                                  "$path/medical license",
                                                  medicalLicenseFiles);
                                            }

                                            await addNotification(
                                                uid: 'admin',
                                                title:
                                                    "New Re-verification Request",
                                                body:
                                                    "Hey there! A ${widget.accountType} submitted a new Verification request. Review it Now!");
                                            await updateData(
                                                'verificationRequests',
                                                id: userData[
                                                    'verificationRequestID'],
                                                {
                                                  "latestVerification":
                                                      DateTime.now().toString(),
                                                  "verificationStatus":
                                                      "pending",
                                                  "feedback": []
                                                });
                                            if (!mounted) return;

                                            Navigator.pop(context, true);
                                          },
                                          style: OutlinedButton.styleFrom(
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text(
                                            "Yes, Upload Now",
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
      if (value == true) {
        Navigator.pop(context, value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;
    final accountType = widget.accountType;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: appColors['white'],
            ),
            onPressed: () {
              setState(
                () {
                  Navigator.pop(context, false);
                },
              );
            },
          ),
          title: const Text("Re-verification"),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 70),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 30, left: 30, right: 30),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: Icon(
                              Icons.info_outline,
                              color: appColors['gray143'],
                              size: 30,
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount:
                                  userData['requestDetail']['feedback'].length,
                              itemBuilder: (context, index) {
                                var reason = userData['requestDetail']
                                    ['feedback'][index];
                                return Padding(
                                  padding:
                                      EdgeInsets.only(top: index > 0 ? 10 : 0),
                                  child: Text(
                                    "$reason",
                                    style: textTheme.bodyMedium,
                                  ),
                                );
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 30, left: 20, right: 20),
                      child: Divider(color: appColors['gray143']),
                    ),
                    accountType == 'patient'
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(30, 20, 30, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Valid ID/s",
                                  style: textTheme.labelSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
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
                                                borderRadius:
                                                    BorderRadius.circular(25)),
                                            insetPadding:
                                                const EdgeInsets.all(15),
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
                                                    child: validIDs![index]!
                                                                    .extension ==
                                                                'jpg' ||
                                                            validIDs![index]!
                                                                    .extension ==
                                                                'png'
                                                        ? PhotoView(
                                                            backgroundDecoration:
                                                                BoxDecoration(
                                                              color: appColors[
                                                                  'gray192'],
                                                            ),
                                                            minScale:
                                                                PhotoViewComputedScale
                                                                        .contained *
                                                                    1,
                                                            imageProvider:
                                                                FileImage(
                                                              File(
                                                                  '${validIDs![index]!.path}'),
                                                            ),
                                                          )
                                                        : SfPdfViewer.file(
                                                            File(
                                                                '${validIDs![index]!.path}'),
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
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 24, right: 24),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Center(
                                                    child: Text(
                                                        validIDs![index]!.name,
                                                        style: textTheme
                                                            .labelSmall),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  child: Icon(
                                                    Icons.delete_outline,
                                                    color: appColors['black'],
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      validIDs?.remove(
                                                          validIDs![index]);
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
                                    height: 60,
                                    width: double.maxFinite,
                                    child: TextButton(
                                      onPressed: () async {
                                        var files = await selectFile(
                                            allowMultiple: true);
                                        if (files == null || !mounted) return;

                                        setState(() {
                                          validIDs!.addAll(files);
                                        });
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: appColors['coolGray'],
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                        ),
                                      ),
                                      child: validIDs!.isNotEmpty
                                          ? Icon(
                                              Icons.add,
                                              color: appColors['black'],
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 8.0),
                                                  child: Icon(
                                                    Icons.file_upload_outlined,
                                                    size: 24,
                                                    color: appColors['gray143'],
                                                  ),
                                                ),
                                                Text(
                                                  "Upload files",
                                                  style: textTheme.labelMedium
                                                      ?.copyWith(
                                                          color: appColors[
                                                              'gray143']),
                                                )
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(40, 9, 40, 0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Make sure the details of the ID/s is clearly visible",
                                          style: textTheme.bodyMedium?.copyWith(
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
                                    style: textTheme.labelSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
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
                                                borderRadius:
                                                    BorderRadius.circular(25)),
                                            insetPadding:
                                                const EdgeInsets.all(15),
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
                                                    child: selfieFiles![index]!
                                                                    .extension ==
                                                                'jpg' ||
                                                            selfieFiles![index]!
                                                                    .extension ==
                                                                'png'
                                                        ? PhotoView(
                                                            backgroundDecoration:
                                                                BoxDecoration(
                                                              color: appColors[
                                                                  'gray192'],
                                                            ),
                                                            minScale:
                                                                PhotoViewComputedScale
                                                                        .contained *
                                                                    1,
                                                            imageProvider:
                                                                FileImage(
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
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 24, right: 24),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Center(
                                                    child: Text(
                                                        selfieFiles![index]!
                                                            .name,
                                                        style: textTheme
                                                            .labelSmall),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  child: Icon(
                                                    Icons.delete_outline,
                                                    color: appColors['black'],
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      selfieFiles?.remove(
                                                          selfieFiles![index]);
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
                                    height: 60,
                                    width: double.maxFinite,
                                    child: TextButton(
                                      onPressed: () async {
                                        var files = await selectFile(
                                            allowMultiple: true);
                                        if (files == null || !mounted) return;

                                        setState(() {
                                          selfieFiles!.addAll(files);
                                        });
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: appColors['coolGray'],
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                        ),
                                      ),
                                      child: selfieFiles!.isNotEmpty
                                          ? Icon(
                                              Icons.add,
                                              color: appColors['black'],
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 8.0),
                                                  child: Icon(
                                                    Icons.file_upload_outlined,
                                                    size: 24,
                                                    color: appColors['gray143'],
                                                  ),
                                                ),
                                                Text(
                                                  "Upload files",
                                                  style: textTheme.labelMedium
                                                      ?.copyWith(
                                                          color: appColors[
                                                              'gray143']),
                                                )
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(40, 9, 40, 0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Hold your Valid ID in the photo",
                                          style: textTheme.bodyMedium?.copyWith(
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
                          )
                        : accountType == 'clinic'
                            ? Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(30, 20, 30, 20),
                                child: SizedBox(
                                  width: double.maxFinite,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Business Permit",
                                          style: textTheme.headlineSmall,
                                        ),
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount:
                                              businessPermitFiles?.length,
                                          itemBuilder: (context, index) {
                                            return GestureDetector(
                                              onTap: () => showDialog<void>(
                                                useSafeArea: true,
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return Dialog(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        25)),
                                                    insetPadding:
                                                        const EdgeInsets.all(
                                                            15),
                                                    child: Stack(
                                                      children: [
                                                        Positioned(
                                                          top: 15,
                                                          left: 15,
                                                          child:
                                                              GestureDetector(
                                                            onTap: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Icon(
                                                              Icons.arrow_back,
                                                              color: appColors[
                                                                  'black'],
                                                            ),
                                                          ),
                                                        ),
                                                        Center(
                                                          child: Container(
                                                            clipBehavior:
                                                                Clip.hardEdge,
                                                            height:
                                                                deviceHeight *
                                                                    .60,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: appColors[
                                                                  'white'],
                                                            ),
                                                            child: businessPermitFiles![index]!
                                                                            .extension ==
                                                                        'jpg' ||
                                                                    businessPermitFiles![index]!
                                                                            .extension ==
                                                                        'png'
                                                                ? PhotoView(
                                                                    backgroundDecoration:
                                                                        BoxDecoration(
                                                                      color: appColors[
                                                                          'gray192'],
                                                                    ),
                                                                    minScale:
                                                                        PhotoViewComputedScale.contained *
                                                                            1,
                                                                    imageProvider:
                                                                        FileImage(
                                                                      File(
                                                                          '${businessPermitFiles![index]!.path}'),
                                                                    ),
                                                                  )
                                                                : SfPdfViewer
                                                                    .file(
                                                                    File(
                                                                        '${businessPermitFiles![index]!.path}'),
                                                                  ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 15),
                                                child: Container(
                                                  height: 60,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        appColors['coolGray'],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 24,
                                                            right: 24),
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Center(
                                                            child: Text(
                                                                businessPermitFiles![
                                                                        index]!
                                                                    .name,
                                                                style: textTheme
                                                                    .labelSmall),
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          child: Icon(
                                                            Icons
                                                                .delete_outline,
                                                            color: appColors[
                                                                'black'],
                                                          ),
                                                          onTap: () {
                                                            setState(() {
                                                              businessPermitFiles
                                                                  ?.remove(
                                                                      businessPermitFiles![
                                                                          index]);
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
                                          padding:
                                              const EdgeInsets.only(top: 15),
                                          child: SizedBox(
                                            height: 60,
                                            width: double.maxFinite,
                                            child: TextButton(
                                              onPressed: () async {
                                                var files = await selectFile(
                                                    allowMultiple: true);
                                                if (files == null || !mounted)
                                                  return;

                                                setState(() {
                                                  businessPermitFiles!
                                                      .addAll(files);
                                                });
                                              },
                                              style: TextButton.styleFrom(
                                                backgroundColor:
                                                    appColors['coolGray'],
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(25),
                                                ),
                                              ),
                                              child: businessPermitFiles!
                                                      .isNotEmpty
                                                  ? Icon(
                                                      Icons.add,
                                                      color:
                                                          appColors['gray143'],
                                                    )
                                                  : Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  right: 8.0),
                                                          child: Icon(
                                                            Icons
                                                                .file_upload_outlined,
                                                            size: 24,
                                                            color: appColors[
                                                                'gray143'],
                                                          ),
                                                        ),
                                                        Text(
                                                          "Upload files",
                                                          style: textTheme
                                                              .labelMedium
                                                              ?.copyWith(
                                                                  color: appColors[
                                                                      'gray143']),
                                                        )
                                                      ],
                                                    ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              40, 9, 40, 0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  "Make sure the details of the permit is clearly visible",
                                                  textAlign: TextAlign.center,
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
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
                              )
                            : Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(30, 20, 30, 20),
                                child: SizedBox(
                                  width: double.maxFinite,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Medical License",
                                          style: textTheme.headlineSmall,
                                        ),
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount:
                                              medicalLicenseFiles?.length,
                                          itemBuilder: (context, index) {
                                            return GestureDetector(
                                              onTap: () => showDialog<void>(
                                                useSafeArea: true,
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return Dialog(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        25)),
                                                    insetPadding:
                                                        const EdgeInsets.all(
                                                            15),
                                                    child: Stack(
                                                      children: [
                                                        Positioned(
                                                          top: 15,
                                                          left: 15,
                                                          child:
                                                              GestureDetector(
                                                            onTap: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Icon(
                                                              Icons.arrow_back,
                                                              color: appColors[
                                                                  'black'],
                                                            ),
                                                          ),
                                                        ),
                                                        Center(
                                                          child: Container(
                                                            clipBehavior:
                                                                Clip.hardEdge,
                                                            height:
                                                                deviceHeight *
                                                                    .60,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: appColors[
                                                                  'white'],
                                                            ),
                                                            child: medicalLicenseFiles![index]!
                                                                            .extension ==
                                                                        'jpg' ||
                                                                    medicalLicenseFiles![index]!
                                                                            .extension ==
                                                                        'png'
                                                                ? PhotoView(
                                                                    backgroundDecoration:
                                                                        BoxDecoration(
                                                                      color: appColors[
                                                                          'gray192'],
                                                                    ),
                                                                    minScale:
                                                                        PhotoViewComputedScale.contained *
                                                                            1,
                                                                    imageProvider:
                                                                        FileImage(
                                                                      File(
                                                                          '${medicalLicenseFiles![index]!.path}'),
                                                                    ),
                                                                  )
                                                                : SfPdfViewer
                                                                    .file(
                                                                    File(
                                                                        '${medicalLicenseFiles![index]!.path}'),
                                                                  ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 15),
                                                child: Container(
                                                  height: 60,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        appColors['coolGray'],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 24,
                                                            right: 24),
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Center(
                                                            child: Text(
                                                                medicalLicenseFiles![
                                                                        index]!
                                                                    .name,
                                                                style: textTheme
                                                                    .labelSmall),
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          child: Icon(
                                                            Icons
                                                                .delete_outline,
                                                            color: appColors[
                                                                'black'],
                                                          ),
                                                          onTap: () {
                                                            setState(() {
                                                              medicalLicenseFiles
                                                                  ?.remove(
                                                                      medicalLicenseFiles![
                                                                          index]);
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
                                          padding:
                                              const EdgeInsets.only(top: 15),
                                          child: SizedBox(
                                            height: 60,
                                            width: double.maxFinite,
                                            child: TextButton(
                                              onPressed: () async {
                                                var files = await selectFile(
                                                    allowMultiple: true);
                                                if (files == null || !mounted) {
                                                  return;
                                                }

                                                setState(() {
                                                  medicalLicenseFiles!
                                                      .addAll(files);
                                                });
                                              },
                                              style: TextButton.styleFrom(
                                                backgroundColor:
                                                    appColors['coolGray'],
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(25),
                                                ),
                                              ),
                                              child: medicalLicenseFiles!
                                                      .isNotEmpty
                                                  ? Icon(
                                                      Icons.add,
                                                      color:
                                                          appColors['gray143'],
                                                    )
                                                  : Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  right: 8.0),
                                                          child: Icon(
                                                            Icons
                                                                .file_upload_outlined,
                                                            size: 24,
                                                            color: appColors[
                                                                'gray143'],
                                                          ),
                                                        ),
                                                        Text(
                                                          "Upload files",
                                                          style: textTheme
                                                              .labelMedium
                                                              ?.copyWith(
                                                                  color: appColors[
                                                                      'gray143']),
                                                        )
                                                      ],
                                                    ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              40, 9, 40, 0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  "Make sure the details of the permit is clearly visible",
                                                  textAlign: TextAlign.center,
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
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
                              ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(left: 30, right: 30, bottom: 30),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      fixedSize: Size(deviceWidth, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: () async {
                    if ((accountType == "patient" &&
                            validIDs!.isNotEmpty &&
                            selfieFiles!.isNotEmpty) ||
                        (accountType == "clinic" &&
                            businessPermitFiles!.isNotEmpty) ||
                        (accountType == "doctor" &&
                            medicalLicenseFiles!.isNotEmpty)) {
                      showSelectedFiles();
                    } else {
                      var errorMessage =
                          "Please upload the following requirements first.";
                      showSnackBar(errorMessage);
                    }
                  },
                  child: Text("Upload",
                      style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: appColors['white'])),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
