import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import '../../global.dart';
import '../../query.dart';
import '../../styles.dart';

class Saved extends StatefulWidget {
  const Saved({Key? key}) : super(key: key);

  @override
  State<Saved> createState() => _SavedState();
}

class _SavedState extends State<Saved> {
  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: appColors['accent'],
      body: SafeArea(
        child: Container(
          height: deviceHeight,
          color: appColors['primary'],
          child: FutureBuilder(
            future: getData("patients", uid: uid, field: "savedClinics"),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                List savedClinics = snapshot.data ?? [];

                if (savedClinics.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmarks_outlined,
                          color: appColors['gray145'],
                          size: 77,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 89, right: 89, top: 10),
                          child: Text("No Clinics have been saved yet",
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
                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        children: [
                          Padding(
                              padding: const EdgeInsets.fromLTRB(25, 20, 25, 0),
                              child: ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: savedClinics.length,
                                itemBuilder: (context, index) {
                                  return FutureBuilder(
                                    future: getData("clinics",
                                        id: savedClinics[index]),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        var clinicInformation = snapshot.data;

                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.pop(context,
                                                clinicInformation['address']);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 15),
                                            child: Container(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        15, 10, 15, 10),
                                                decoration: BoxDecoration(
                                                    color: appColors['white'],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                    boxShadow: [
                                                      BoxShadow(
                                                          color: appColors[
                                                              'black.25']!,
                                                          offset: const Offset(
                                                              0, 2),
                                                          blurRadius: 2,
                                                          spreadRadius: 0)
                                                    ]),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "${clinicInformation['clinicName']}",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelMedium
                                                          ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 5),
                                                      child: FutureBuilder(
                                                        future: placemarkFromCoordinates(
                                                            clinicInformation[
                                                                    'address']
                                                                ['latitude'],
                                                            clinicInformation[
                                                                    'address']
                                                                ['longitude']),
                                                        builder: (context,
                                                            snapshot) {
                                                          if (snapshot
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .done) {
                                                            var address =
                                                                snapshot.data!
                                                                    .first;
                                                            return Text(
                                                              "${address.street}. ${address.subLocality}, ${address.locality}, ${address.administrativeArea}",
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyMedium
                                                                  ?.copyWith(
                                                                      color: appColors[
                                                                          'gray143']),
                                                            );
                                                          } else {
                                                            return Container(
                                                              height: 16,
                                                              width:
                                                                  deviceWidth,
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
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 5),
                                                      child: Text(
                                                        "${clinicInformation['phoneNumber']} / ${clinicInformation['landline']}",
                                                        style: Theme.of(context)
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
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    },
                                  );
                                },
                              )),
                        ],
                      ),
                    ),
                  );
                }
              } else {
                return const SizedBox.expand();
              }
            },
          ),
        ),
      ),
    );
  }
}
