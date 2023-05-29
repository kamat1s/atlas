import 'dart:developer';

import 'package:atlas/global.dart';
import 'package:atlas/query.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:atlas/styles.dart';

class Login extends StatefulWidget {
  final VoidCallback onCreateAccount;
  const Login({Key? key, required this.onCreateAccount}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool emailSelected = false;
  bool passwordSelected = false;

  bool showPassword = false;

  String? validateEmail(String email) {
    if (email.isEmpty) {
      return "Email address is required.";
    } else if (!EmailValidator.validate(email)) {
      return "Enter the email address in the format someone@example.com.";
    }

    return null;
  }

  String? validatePassword(String password) {
    if (password.isEmpty) {
      return "Password is required.";
    }

    return null;
  }

  Future<void> authenticate() async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      )
          .then((value) async {
        String accountType =
            (await checkAccountType(emailController.text)).toLowerCase();
        String uid = FirebaseAuth.instance.currentUser!.uid;

        accountType = accountType == "doctor" ? "independentDoctor" : accountType;

        await getData("${accountType}s", uid: uid, field: "token").then((token) {
          if (token != null && !token.contains(fcmToken)) {
            token.add(fcmToken);
            updateData("${accountType}s", uid: uid, {"token": token});
          } else {
            updateData("${accountType}s", uid: uid, {
              "token": [fcmToken]
            });
          }
        });
      });

      log(name: "FCM TOKEN", fcmToken);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "user-not-found":
        case "wrong-password":
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Invalid Credentials"),
              backgroundColor: Colors.black,
            ),
          );
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;
    final safePadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: appColors['accent'],
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: SafeArea(
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              color: appColors['dirtyWhite'],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -280,
                  left: -300,
                  child: Image.asset(
                    "assets/images/map-bg.png",
                    height: 1000,
                  ),
                ),
                Positioned(
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15, right: 15),
                    child: Text(
                      "powered by OSSÉ",
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: appColors['gray145']),
                    ),
                  ),
                ),
                SizedBox(
                  height: deviceHeight * .40 - safePadding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child:
                            Image.asset("assets/images/atlas-logo-medium.png"),
                      ),
                      Text(
                        "ATLAS",
                        style: TextStyle(
                            fontFamily: appFonts['Montserrat'],
                            fontSize: 55,
                            fontWeight: FontWeight.w500,
                            color: appColors['gray145']),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    height: deviceHeight * .60,
                    width: deviceWidth,
                    decoration: BoxDecoration(
                      color: appColors['white'],
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(35),
                        topLeft: Radius.circular(35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, -5),
                          blurRadius: 20,
                          spreadRadius: 0,
                          color: appColors['black.25']!,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 30),
                            child: Text(
                              "Log in",
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                          Form(
                            key: formKey,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 50, right: 50, top: 20),
                                  child: Focus(
                                    onFocusChange: (hasFocus) => setState(() {
                                      emailSelected = hasFocus;
                                    }),
                                    child: TextFormField(
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        controller: emailController,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: appColors['coolGray'],
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide.none),
                                          prefixIcon: Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8, left: 14),
                                            child: Icon(
                                              Icons.alternate_email,
                                              color: emailSelected
                                                  ? appColors['black']
                                                  : appColors['gray143'],
                                              size: 20,
                                            ),
                                          ),
                                          labelText: "Email address",
                                          labelStyle: theme
                                              .textTheme.labelMedium
                                              ?.copyWith(
                                            color: emailSelected
                                                ? appColors['black']
                                                : appColors['gray143'],
                                          ),
                                          errorMaxLines: 2,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 14, horizontal: 8),
                                        ),
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(height: 1),
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        validator: (email) {
                                          return validateEmail(email!);
                                        }),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 50, right: 50, top: 20),
                                  child: Focus(
                                    onFocusChange: (hasFocus) => setState(() {
                                      passwordSelected = hasFocus;
                                    }),
                                    child: TextFormField(
                                      controller: passwordController,
                                      obscureText: !showPassword,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: appColors['coolGray'],
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            borderSide: BorderSide.none),
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.only(
                                              right: 8, left: 14),
                                          child: Icon(
                                            Icons.lock,
                                            color: passwordSelected
                                                ? appColors['black']
                                                : appColors['gray143'],
                                            size: 20,
                                          ),
                                        ),
                                        suffixIcon: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 14),
                                          child: IconButton(
                                            icon: Icon(
                                              (showPassword)
                                                  ? Icons.remove_red_eye_rounded
                                                  : Icons.visibility_off_sharp,
                                              size: 20,
                                              color: passwordSelected
                                                  ? appColors['black']
                                                  : appColors['gray143'],
                                            ),
                                            onPressed: () => setState(() {
                                              showPassword = !showPassword;
                                            }),
                                          ),
                                        ),
                                        labelText: "Password",
                                        labelStyle: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: passwordSelected
                                              ? appColors['black']
                                              : appColors['gray143'],
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 14, horizontal: 8),
                                      ),
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(height: 1),
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      validator: (password) =>
                                          validatePassword(password!),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 50, right: 50, top: 20),
                            child: SizedBox(
                              width: deviceWidth,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () async {
                                  formKey.currentState!.validate();
                                  await authenticate();
                                },
                                style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    backgroundColor: appColors['accent'],
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap),
                                child: Text(
                                  "Login",
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(color: appColors['white']),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Text(
                              "OR",
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 50, right: 50, top: 20),
                            child: SizedBox(
                              width: deviceWidth,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  FirebaseAuth.instance.signInAnonymously();
                                },
                                style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    backgroundColor: appColors['gray217'],
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap),
                                child: Text(
                                  "Continue as Guest",
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: GestureDetector(
                              onTap: widget.onCreateAccount,
                              child: Text(
                                "Don't have an account? Click here!",
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
