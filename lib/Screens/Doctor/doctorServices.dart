import 'dart:developer';

import 'package:atlas/query.dart';
import 'package:atlas/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';

import '../../global.dart';
import '../../utils.dart';

class DoctorServices extends StatefulWidget {
  const DoctorServices({Key? key}) : super(key: key);

  @override
  State<DoctorServices> createState() => _DoctorServicesState();
}

class _DoctorServicesState extends State<DoctorServices> {
  Map<String, dynamic> independentDoctorInformation = userData;
  List services = [];
  List offeredServices = [];

  List prev = [];

  final Stream<QuerySnapshot<Map<String, dynamic>>>
      independentDoctorDataStream = FirebaseFirestore.instance
          .collection('independentDoctors')
          .where("uid", isEqualTo: uid)
          .snapshots();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      for (var element in await getServices()) {
        services.add(element.id);
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  stream: independentDoctorDataStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Something went wrong');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.expand();
                    }

                    independentDoctorInformation =
                        snapshot.data!.docs.first.data();

                    offeredServices = independentDoctorInformation['services'];

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: 25, right: 20, top: 50),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: offeredServices.length,
                          itemBuilder: (context, index) {
                            var service = offeredServices[index];

                            return Padding(
                              padding: EdgeInsets.only(top: index == 0 ? 15 : 0),
                              child: ListTile(
                                visualDensity: VisualDensity.compact,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  service,
                                  style: getTextStyle(
                                    textColor: 'black',
                                    fontFamily: 'Inter',
                                    fontWeight: 500,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: GestureDetector(
                                  onTap: () async {
                                    if(offeredServices.length > 1){
                                      setState(() {
                                        offeredServices.remove(service);
                                        prev.remove(service);
                                      });

                                      await updateData('independentDoctors',
                                          {"services": offeredServices},
                                          uid: uid);
                                    }
                                    else{
                                      showSnackBar("You must have at least one service.");
                                    }
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color: appColors['black'],
                                    size: 18,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
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
                          "Services Offered",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: (){
                            showServices(setState);
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

  showServices(var setState) {
    showDialog<void>(
      useSafeArea: true,
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        return WillPopScope(
          onWillPop: () async {
            offeredServices.clear();
            offeredServices.addAll(prev);
            return true;
          },
          child: StatefulBuilder(
            builder: (context, dialogSetState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                insetPadding: const EdgeInsets.all(15),
                child: SizedBox(
                  height: 400,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Services",
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
                                itemCount: services.length,
                                itemBuilder: (BuildContext context, int index) {
                                  String service = services[index];
                                  return SizedBox(
                                    height: 48,
                                    child: TextButton(
                                      onPressed: () {
                                        if (!mounted) return;
                                        dialogSetState(() {
                                          if (offeredServices.contains(service)) {
                                            if(offeredServices.length > 1){
                                              offeredServices.remove(service);
                                            }
                                            else{
                                              showSnackBar("You must have at least one service.");
                                            }
                                          } else {
                                            offeredServices.add(service);
                                          }
                                        });
                                      },
                                      style: TextButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        backgroundColor:
                                        offeredServices.contains(service)
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
                                            color: offeredServices.contains(service)
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
                                  offeredServices.clear();
                                  offeredServices.addAll(prev);
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
                              onTap: () async {
                                setState(() {
                                  prev.clear();
                                  prev.addAll(offeredServices);
                                });

                                await updateData('independentDoctors', {"services": offeredServices}, uid: uid);

                                if(!mounted) return;

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
