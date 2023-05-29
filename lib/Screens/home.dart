import 'dart:developer';

import 'package:atlas/Screens/Clinic/clinicHome.dart';
import 'package:atlas/Screens/Doctor/doctorHome.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:atlas/query.dart';
import 'Patient/patientHome.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: checkAccountType(currentUser.email),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (currentUser.isAnonymous || snapshot.data == "Patient") {
            log("Account Type [Home]: ${snapshot.data}");

            return const PatientHome();
          } else if (snapshot.data == "Clinic"){
            return const ClinicHome();
          }
          else
            {
              return const DoctorHome();
            }
        } else {
          return const Center();
        }
      },
    );
  }
}
