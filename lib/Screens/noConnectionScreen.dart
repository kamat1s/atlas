import 'package:atlas/styles.dart';
import 'package:flutter/material.dart';

class NoConnectionScreen extends StatefulWidget {
  const NoConnectionScreen({Key? key}) : super(key: key);

  @override
  State<NoConnectionScreen> createState() => _NoConnectionScreenState();
}

class _NoConnectionScreenState extends State<NoConnectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColors['accent'],
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(color: appColors['primary']),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 52),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_sharp,
                  size: 84,
                  color: appColors['gray143'],
                ),
                Text(
                  "Hey there! Seems like you lost Internet Connection..",
                  maxLines: 5,
                  textAlign: TextAlign.center,
                  style: getTextStyle(
                    textColor: 'gray143',
                    fontFamily: 'Inter',
                    fontWeight: 600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
