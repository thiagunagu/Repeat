import 'package:flutter/material.dart';

import 'package:repeat/Screens/ForgotPassword.dart';
import 'package:repeat/Screens/Login.dart';
import 'package:repeat/Screens/Register.dart';

class Startup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Register(),
      theme: ThemeData(
        indicatorColor: Colors.white,
        primaryColor: Colors.blue[900], colorScheme: ColorScheme.fromSwatch().copyWith(primary: Colors.blue[900],secondary: Colors.blue[900]),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            primary: Colors.blueAccent, // This is a custom color variable
          ),
        ),
      ),
      routes: {
        '/Login': (context) => Login(),
        '/ForgotPassword': (context) => ForgotPassword(),
      },
    );
  }
}
