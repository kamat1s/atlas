import 'package:flutter/material.dart';

import '../../styles.dart';

class SetupDone extends StatefulWidget {
  const SetupDone({Key? key}) : super(key: key);

  @override
  State<SetupDone> createState() => _SetupDoneState();
}

class _SetupDoneState extends State<SetupDone> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return true;
      },
      child: Scaffold(
        backgroundColor: appColors['accent'],
        body: SafeArea(
          child: Container(
            width: deviceWidth,
            decoration: BoxDecoration(color: appColors['primary']),
            child: Stack(
              children: [
                Positioned(
                  bottom: -120,
                  right: -250,
                  child: Image.asset("assets/images/clipboard-checked.png"),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 163),
                  child: Center(
                    child: Column(
                      children: [
                        Image.asset("assets/images/atlas-logo-medium.png"),
                        Text(
                          'You\'re all set up and good to go!',
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        )
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
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            backgroundColor: appColors['accent'],
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: Text(
                          "Get Started",
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
      ),
    );
  }
}
