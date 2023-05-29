import 'package:flutter/material.dart';
import 'package:atlas/Screens/Authentication/signup.dart';
import 'package:atlas/Screens/Authentication/login.dart';

class Authentication extends StatefulWidget {
  const Authentication({Key? key}) : super(key: key);

  @override
  State<Authentication> createState() => _AuthenticationState();
}

class _AuthenticationState extends State<Authentication> {
  bool haveAccount = false;

  void toggle() {
    setState(() {
      haveAccount = !haveAccount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return haveAccount
        ? Login(onCreateAccount: toggle)
        : SignUp(onLogin: toggle);
  }
}
