import 'dart:async';
import 'dart:developer';

import 'package:atlas/Screens/Authentication/authentication.dart';
import 'package:atlas/Screens/home.dart';
import 'package:atlas/Screens/noConnectionScreen.dart';
import 'package:atlas/global.dart';
import 'package:atlas/styles.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'Classes/NotificationControllerFCM.dart';

Future<String> getFirebaseMessagingToken() async {
  String firebaseAppToken = '';
  if (await AwesomeNotificationsFcm().isFirebaseAvailable) {
    try {
      firebaseAppToken =
          await AwesomeNotificationsFcm().requestFirebaseAppToken();
    } catch (exception) {
      debugPrint('$exception');
    }
  } else {
    debugPrint('Firebase is not available on this project');
  }
  return firebaseAppToken;
}

Future main() async {
  await NotificationController.initializeLocalNotifications(debug: true);
  await NotificationController.initializeRemoteNotifications(debug: true);
  await NotificationController.getInitialNotificationAction();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  fcmToken = await getFirebaseMessagingToken();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription internetConnectionStream;

  ConnectivityResult _connectionStatus = ConnectivityResult.none;

  @override
  void initState() {
    internetConnectionStream = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      setState(() {
        _connectionStatus = result;
        log(_connectionStatus.name);
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    internetConnectionStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atlas',
      theme: ThemeData(
        inputDecorationTheme: InputDecorationTheme(
          errorStyle: TextStyle(
              fontFamily: appFonts['Inter'],
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: appColors['accent'],
              letterSpacing: 1),
          errorMaxLines: 5,
        ),
        drawerTheme: DrawerThemeData(scrimColor: appColors['black.25']),
        textTheme: TextTheme(
          labelSmall: TextStyle(
              fontFamily: appFonts['Inter'],
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: appColors['black'],
              letterSpacing: 1),
          labelMedium: TextStyle(
              fontFamily: appFonts['Inter'],
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: appColors['black'],
              letterSpacing: 1),
          bodyMedium: TextStyle(
              fontFamily: appFonts['Inter'],
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: appColors['black'],
              letterSpacing: 1),
          bodyLarge: TextStyle(
              fontFamily: appFonts['Inter'],
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: appColors['black'],
              letterSpacing: 1),
          headlineSmall: TextStyle(
              fontFamily: appFonts['Inter'],
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: appColors['black'],
              letterSpacing: 1),
          headlineMedium: TextStyle(
              fontFamily: appFonts['Inter'],
              fontSize: 35,
              fontWeight: FontWeight.w700,
              color: appColors['black'],
              letterSpacing: 1),
        ),
        colorScheme: Theme.of(context)
            .colorScheme
            .copyWith(primary: appColors['accent']),
      ),
      home: Scaffold(
        body: _connectionStatus != ConnectivityResult.none
            ? StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(child: Text("Something went wrong!"));
                  } else if (snapshot.hasData) {
                    return const Home();
                  } else {
                    return const Authentication();
                    /*return const ClinicSetup();*/
                  }
                },
              )
            : const NoConnectionScreen(),
      ),
    );
  }
}
