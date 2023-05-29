import 'package:atlas/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../global.dart';
import '../utils.dart';

class Notifications extends StatefulWidget {
  const Notifications({Key? key}) : super(key: key);

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  @override
  void initState() {
    super.initState();
  }

  final Stream<QuerySnapshot> notificationStream = FirebaseFirestore.instance
      .collection('notifications')
      .where("uid", isEqualTo: uid)
      .orderBy('date', descending: true)
      .snapshots();

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
                StreamBuilder(
                  stream: notificationStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Something went wrong');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.expand();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 54),
                      child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var notificationDetails = snapshot.data!.docs[index]
                              .data() as Map<String, dynamic>;

                          var date =
                              DateTime.parse(notificationDetails['date']);
                          var year = date.year;
                          var month = formatTime(date.month);
                          var day = formatTime(date.day);
                          var startHour = formatTime(convertTime(date.hour));
                          var startMinute = formatTime(date.minute);
                          var startMeridiem =
                              getMeridiem(convertTime(date.hour));

                          return notificationDetails['scheduleDate'].isEmpty || (notificationDetails['scheduleDate'].isNotEmpty && DateTime.now().compareTo(DateTime.parse(notificationDetails['scheduleDate'])) >= 0)
                              ? Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                    color: appColors['gray192']!,
                                  ))),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 15),
                                        child: Icon(
                                          Icons.notifications,
                                          color: appColors['accent'],
                                          size: 36,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              notificationDetails['title'],
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 10),
                                              child: Text(
                                                notificationDetails['body'],
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color: appColors[
                                                            'gray143']),
                                                overflow: TextOverflow.visible,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 16),
                                              child: Row(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 10),
                                                    child: Icon(
                                                      Icons
                                                          .watch_later_outlined,
                                                      color:
                                                          appColors['gray143'],
                                                      size: 14,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 30),
                                                    child: Text(
                                                      "$month/$day/${year.toString().substring(2)}",
                                                      style: textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                              color: appColors[
                                                                  'gray143']),
                                                    ),
                                                  ),
                                                  Text(
                                                    "$startHour:$startMinute ${startMeridiem.toUpperCase()}",
                                                    style: textTheme.bodyMedium
                                                        ?.copyWith(
                                                            color: appColors[
                                                                'gray143']),
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SizedBox.shrink();
                        },
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
                              Icons.close,
                              color: appColors['black'],
                            ),
                          ),
                        ),
                        Text(
                          "Notifications",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
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
