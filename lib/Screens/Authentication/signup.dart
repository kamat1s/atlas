import 'package:atlas/query.dart';
import 'package:atlas/styles.dart';
import 'package:atlas/otpAuth.dart' as otp;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignUp extends StatefulWidget {
  final VoidCallback onLogin;
  const SignUp({Key? key, required this.onLogin}) : super(key: key);

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final formKey1 = GlobalKey<FormState>();
  final formKey2 = GlobalKey<FormState>();
  final formKey3 = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool emailSelected = false;
  bool otpSelected = false;
  bool passwordSelected = false;
  bool confirmPasswordSelected = false;

  bool showSignupOption = true;
  bool showForm1 = false;
  bool showForm2 = false;
  bool showForm3 = false;

  bool showPassword = false;
  bool showConfirmPassword = false;

  bool isOTPSent = false;

  bool emailExist = false;

  String accountType = "";

  var _otp;

  final accountDetails = <String, dynamic>{
    "email": "",
    "password": "",
    "setupDone": false
  };

  String? validateEmail(String email) {
    if (email.isEmpty) {
      return "Email address is required.";
    } else if (!EmailValidator.validate(email)) {
      return "Enter the email address in the format someone@example.com.";
    } else if (emailExist) {
      return "Someone already has this email address.";
    }

    return null;
  }

  String? validateOTP(String OTP) {
    if (!isOTPSent) {
      return "Please send OTP First.";
    } else {
      if (OTP.isEmpty) {
        return "OTP is required.";
      } else if (_otp != OTP && isOTPSent) {
        return "Invalid OTP.";
      }
    }

    return null;
  }

  String? validatePassword(String password) {
    if (password.isEmpty) {
      return "Password is required.";
    }

    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasSpecialCharacters =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    bool hasMinLength = password.length >= 8;

    if (!(hasDigits &
        hasUppercase &
        hasLowercase &
        hasSpecialCharacters &
        hasMinLength)) {
      return "Your password must have at least 8 characters, \n1 uppercase & lowercase character, \n1 number and 1 special character.";
    }

    return null;
  }

  String? matchPassword(String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return "Please confirm your password.";
    }

    if (confirmPassword != passwordController.text) {
      return "Password do not match.";
    }

    return null;
  }

  void sendOTP() async {
    if (!isOTPSent) {
      _otp = otp.generate();
      await otp.send(email: emailController.text, otp: _otp);

      isOTPSent = true;
      formKey2.currentState!.validate();

      if (!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("OTP sent"),
          backgroundColor: appColors['black'],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("OTP is already sent to your email!"),
          backgroundColor: appColors['black'],
        ),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
                  height: accountType.isNotEmpty
                      ? deviceHeight * .40
                      : deviceHeight * .50,
                  width: double.maxFinite,
                  child: accountType.isNotEmpty
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: Image.asset(
                                  "assets/images/atlas-logo-medium.png"),
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
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: Image.asset(
                                  "assets/images/atlas-logo-large.png"),
                            ),
                            Text(
                              "ATLAS",
                              style: TextStyle(
                                  fontFamily: appFonts['Montserrat'],
                                  fontSize: 55,
                                  fontWeight: FontWeight.w500,
                                  color: appColors['gray145']),
                            ),
                            Text(
                              "Find · Clinics · With · Your · Needs ",
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: appColors['black']),
                            ),
                          ],
                        ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    height: accountType.isNotEmpty
                        ? deviceHeight * .60 - safePadding
                        : deviceHeight * .50 - safePadding,
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
                      padding: const EdgeInsets.only(bottom: 30),
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 30),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                showForm1 || showForm2 || showForm3
                                    ? Padding(
                                        padding:
                                            const EdgeInsets.only(left: 23),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: GestureDetector(
                                            onTap: () {
                                              if (showForm1) {
                                                setState(() {
                                                  showForm1 = false;
                                                  accountType = "";
                                                  emailController.clear();
                                                  otpController.clear();
                                                  passwordController.clear();
                                                  confirmPasswordController
                                                      .clear();
                                                  Navigator.of(context)
                                                      .focusScopeNode
                                                      .unfocus();
                                                });
                                              }
                                              if (showForm2) {
                                                setState(() {
                                                  otpSelected = false;
                                                  showForm1 = true;
                                                  showForm2 = false;
                                                });
                                              } else {
                                                if (showForm3) {
                                                  setState(() {
                                                    passwordSelected = false;
                                                    confirmPasswordSelected =
                                                        false;
                                                    showForm2 = true;
                                                    showForm3 = false;
                                                  });
                                                }
                                              }
                                            },
                                            child: const Icon(
                                              Icons.arrow_back,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                                Text(
                                  accountType.isEmpty
                                      ? "Sign up as"
                                      : "Sign up as $accountType",
                                  style: theme.textTheme.headlineSmall,
                                ),
                              ],
                            ),
                          ),
                          showForm1
                              ? Form(
                                  key: formKey1,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 50, right: 50, top: 20),
                                        child: Focus(
                                          onFocusChange: (hasFocus) =>
                                              setState(() {
                                            emailSelected = hasFocus;
                                          }),
                                          child: TextFormField(
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              controller: emailController,
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor:
                                                    appColors['coolGray'],
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15),
                                                    borderSide:
                                                        BorderSide.none),
                                                prefixIcon: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
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
                                                        vertical: 14,
                                                        horizontal: 8),
                                              ),
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                height: 1,
                                                color: emailSelected
                                                    ? appColors['black']
                                                    : appColors['gray143'],
                                              ),
                                              autovalidateMode: AutovalidateMode
                                                  .onUserInteraction,
                                              onChanged: (email) async {
                                                if (showForm1) {
                                                  emailExist =
                                                      await checkAccountType(
                                                              email) !=
                                                          "anonymous";
                                                  formKey1.currentState!
                                                      .validate();
                                                  _otp = "";
                                                  otpController.clear();
                                                  isOTPSent = false;
                                                }
                                              },
                                              validator: (email) {
                                                return validateEmail(email!);
                                              }),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                          showForm2
                              ? Form(
                                  key: formKey2,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 50, right: 50, top: 20),
                                        child: Focus(
                                          onFocusChange: (hasFocus) =>
                                              setState(() {
                                            otpSelected = hasFocus;
                                          }),
                                          child: TextFormField(
                                            controller: otpController,
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
                                                  color: otpSelected
                                                      ? appColors['black']
                                                      : appColors['gray143'],
                                                  size: 20,
                                                ),
                                              ),
                                              suffixIcon: Align(
                                                widthFactor: 1.0,
                                                heightFactor: 1.0,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 14),
                                                  child: GestureDetector(
                                                    onTap: sendOTP,
                                                    child: Text(
                                                      "Send",
                                                      style: theme
                                                          .textTheme.labelMedium
                                                          ?.copyWith(
                                                        color: otpSelected
                                                            ? appColors['black']
                                                            : appColors[
                                                                'gray143'],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              labelText: "Enter OTP",
                                              labelStyle: theme
                                                  .textTheme.labelMedium
                                                  ?.copyWith(
                                                color: otpSelected
                                                    ? appColors['black']
                                                    : appColors['gray143'],
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                      horizontal: 8),
                                            ),
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                              height: 1,
                                              color: otpSelected
                                                  ? appColors['black']
                                                  : appColors['gray143'],
                                            ),
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                  6)
                                            ],
                                            autovalidateMode:
                                                otpController.text.isEmpty
                                                    ? AutovalidateMode
                                                        .onUserInteraction
                                                    : AutovalidateMode.disabled,
                                            validator: (otp) =>
                                                validateOTP(otp!),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                          showForm3
                              ? Form(
                                  key: formKey3,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 50, right: 50, top: 20),
                                        child: Focus(
                                          onFocusChange: (hasFocus) =>
                                              setState(() {
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
                                                padding: const EdgeInsets.only(
                                                    right: 14),
                                                child: IconButton(
                                                  icon: Icon(
                                                    (showPassword)
                                                        ? Icons
                                                            .remove_red_eye_rounded
                                                        : Icons
                                                            .visibility_off_sharp,
                                                    size: 20,
                                                    color: passwordSelected
                                                        ? appColors['black']
                                                        : appColors['gray143'],
                                                  ),
                                                  onPressed: () => setState(() {
                                                    showPassword =
                                                        !showPassword;
                                                  }),
                                                ),
                                              ),
                                              labelText: "Password",
                                              labelStyle: theme
                                                  .textTheme.labelMedium
                                                  ?.copyWith(
                                                color: passwordSelected
                                                    ? appColors['black']
                                                    : appColors['gray143'],
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                      horizontal: 8),
                                            ),
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                              height: 1,
                                              color: passwordSelected
                                                  ? appColors['black']
                                                  : appColors['gray143'],
                                            ),
                                            autovalidateMode: AutovalidateMode
                                                .onUserInteraction,
                                            validator: (password) =>
                                                validatePassword(password!),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 50, right: 50, top: 20),
                                        child: Focus(
                                          onFocusChange: (hasFocus) =>
                                              setState(() {
                                            confirmPasswordSelected = hasFocus;
                                          }),
                                          child: TextFormField(
                                            controller:
                                                confirmPasswordController,
                                            obscureText: !showConfirmPassword,
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
                                                  color: confirmPasswordSelected
                                                      ? appColors['black']
                                                      : appColors['gray143'],
                                                  size: 20,
                                                ),
                                              ),
                                              suffixIcon: Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 14),
                                                child: IconButton(
                                                  icon: Icon(
                                                    (showConfirmPassword)
                                                        ? Icons
                                                            .remove_red_eye_rounded
                                                        : Icons
                                                            .visibility_off_sharp,
                                                    size: 20,
                                                    color:
                                                        confirmPasswordSelected
                                                            ? appColors['black']
                                                            : appColors[
                                                                'gray143'],
                                                  ),
                                                  onPressed: () => setState(() {
                                                    showConfirmPassword =
                                                        !showConfirmPassword;
                                                  }),
                                                ),
                                              ),
                                              labelText: "Confirm Password",
                                              labelStyle: theme
                                                  .textTheme.labelMedium
                                                  ?.copyWith(
                                                color: confirmPasswordSelected
                                                    ? appColors['black']
                                                    : appColors['gray143'],
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                      horizontal: 8),
                                            ),
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                              height: 1,
                                              color: confirmPasswordSelected
                                                  ? appColors['black']
                                                  : appColors['gray143'],
                                            ),
                                            autovalidateMode: AutovalidateMode
                                                .onUserInteraction,
                                            validator: (confirmPassword) =>
                                                matchPassword(confirmPassword!),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                          accountType.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                      left: 50, right: 50, top: 20),
                                  child: SizedBox(
                                    width: deviceWidth,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (showForm1 &&
                                            formKey1.currentState!.validate()) {
                                          setState(
                                            () {
                                              emailSelected = false;
                                              showForm1 = false;
                                              showForm2 = true;
                                            },
                                          );
                                        } else if (showForm2 &&
                                            formKey2.currentState!.validate()) {
                                          setState(() {
                                            otpSelected = false;
                                            showForm2 = false;
                                            showForm3 = true;
                                          });
                                        } else if (showForm3 &&
                                            formKey3.currentState!.validate()) {
                                          setState(
                                            () {
                                              passwordSelected = false;
                                              confirmPasswordSelected = false;

                                              accountDetails['email'] =
                                                  emailController.text;
                                              accountDetails['password'] =
                                                  passwordController.text;
                                            },
                                          );

                                          await createAccount(
                                                  accountDetails, accountType)
                                              .then(
                                                  (value) => widget.onLogin());

                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .removeCurrentSnackBar();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Account created, Welcome to ATLAS!",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: appColors['white'],
                                                    ),
                                              ),
                                              backgroundColor:
                                                  appColors['accent'],
                                              duration:
                                                  const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15)),
                                          backgroundColor: appColors['accent'],
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap),
                                      child: Text(
                                        showForm3 ? "Sign up" : "Continue",
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                                color: appColors['white']),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          accountType.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                      left: 50, right: 50, top: 20),
                                  child: SizedBox(
                                    width: deviceWidth,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          showForm1 = true;
                                          accountType = "Patient";
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15)),
                                          backgroundColor: appColors['accent'],
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap),
                                      child: Text(
                                        "Patient",
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                                color: appColors['white']),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          // DOCTOR
                          accountType.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Text(
                                    "OR",
                                    style: theme.textTheme.labelSmall,
                                  ),
                                )
                              : const SizedBox.shrink(),
                          accountType.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                      left: 50, right: 50, top: 20),
                                  child: SizedBox(
                                    width: deviceWidth,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          showForm1 = true;
                                          accountType = "Doctor";
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15)),
                                          backgroundColor: appColors['gray145'],
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap),
                                      child: Text(
                                        "Doctor",
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                                color: appColors['white']),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          // CLINIC
                          accountType.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Text(
                                    "OR",
                                    style: theme.textTheme.labelSmall,
                                  ),
                                )
                              : const SizedBox.shrink(),
                          accountType.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                      left: 50, right: 50, top: 20),
                                  child: SizedBox(
                                    width: deviceWidth,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          showForm1 = true;
                                          accountType = "Clinic";
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15)),
                                          backgroundColor: appColors['gray217'],
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap),
                                      child: Text(
                                        "Clinic",
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                                color: appColors['black']),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          accountType == "Patient"
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Text(
                                    "OR",
                                    style: theme.textTheme.labelSmall,
                                  ),
                                )
                              : const SizedBox.shrink(),
                          accountType == "Patient"
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                      left: 50, right: 50, top: 20),
                                  child: SizedBox(
                                    width: deviceWidth,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        FirebaseAuth.instance
                                            .signInAnonymously();
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
                                )
                              : const SizedBox.shrink(),
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: GestureDetector(
                              onTap: widget.onLogin,
                              child: Text(
                                "Already have an Account? Click here!",
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          ),
                          accountType.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: theme.textTheme.bodyMedium,
                                      children: const <TextSpan>[
                                        TextSpan(
                                            text:
                                                'By continuing, you agree to ATLAS '),
                                        TextSpan(
                                            text: 'Terms of',
                                            style: TextStyle(
                                                decoration:
                                                    TextDecoration.underline)),
                                        TextSpan(
                                            text: '\nService',
                                            style: TextStyle(
                                                decoration:
                                                    TextDecoration.underline)),
                                        TextSpan(
                                            text:
                                                ' and acknowledge you\'ve read out'),
                                        TextSpan(
                                            text: '\nPrivacy Policy. ',
                                            style: TextStyle(
                                                decoration:
                                                    TextDecoration.underline)),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
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
