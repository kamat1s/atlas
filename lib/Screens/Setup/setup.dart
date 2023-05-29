import 'package:atlas/Screens/Clinic/clinicSetup.dart';
import 'package:atlas/Screens/Patient/patientSetup.dart';
import 'package:atlas/styles.dart';
import 'package:flutter/material.dart';

import '../Doctor/doctorSetup.dart';

class Setup extends StatefulWidget {
  final accountType;
  final VoidCallback onSetupDone;
  const Setup({Key? key, required this.accountType, required this.onSetupDone})
      : super(key: key);

  @override
  State<Setup> createState() => _SetupState();
}

class _SetupState extends State<Setup> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: appColors['accent'],
      body: SafeArea(
        child: Container(
          width: deviceWidth,
          decoration: BoxDecoration(color: appColors['primary']),
          child: Stack(
            children: [
              Positioned(
                bottom: -80,
                right: -150,
                child: Image.asset("assets/images/clipboard.png"),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 163),
                child: Center(
                  child: Column(
                    children: [
                      Image.asset("assets/images/atlas-logo-medium.png"),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: theme.textTheme.headlineMedium,
                          children: <TextSpan>[
                            const TextSpan(
                              text: 'Let\'s set up your\n',
                            ),
                            TextSpan(
                              text: 'ATLAS',
                              style: TextStyle(
                                  color: appColors['accent'],
                                  fontFamily: appFonts['Montserrat']),
                            ),
                            const TextSpan(
                              text: ' account!',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                child: SizedBox(
                  width: deviceWidth,
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 35, right: 35),
                    child: ElevatedButton(
                      onPressed: () {
                        Widget setupWidget = widget.accountType == "Clinic"
                            ? const ClinicSetup()
                            : widget.accountType == "Doctor"
                                ? const DoctorSetup()
                                : const PatientSetup();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => setupWidget,
                          ),
                        ).then((value) => widget.onSetupDone());
                      },
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          backgroundColor: appColors['accent'],
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text(
                        "Set up now",
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: appColors['white']),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
