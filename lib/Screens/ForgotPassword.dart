import 'package:flutter/material.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:another_flushbar/flushbar.dart';

import 'package:repeat/CustomWidgets/ErrorAlert.dart';

import 'package:repeat/Services/AuthService.dart';

class ForgotPassword extends StatefulWidget {
  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _email = TextEditingController();
  final AuthService _auth = AuthService();
  final _forgotPasswordFormKey = GlobalKey<FormState>();
  final RegExp _validCharacters = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");

  @override
  Widget build(BuildContext context) {
    final ButtonStyle styleRed = ElevatedButton.styleFrom(
        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
        elevation: 4.0,
        primary: Colors.blue[900],
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
            side: BorderSide(color: Colors.blue[900],)));
    return Scaffold(
      appBar:AppBar(
        title: Text('Reset Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _forgotPasswordFormKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      controller: _email,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email),
                        labelText: 'Email',
                      ),
                      validator: (value) {
                        if (!_validCharacters.hasMatch(value)) {
                          return 'Please enter a valid email.';
                        }
                        return null;
                      },
                    ),
                  ),
                  ElevatedButton(
                    child: Text(
                      "Reset password",
                    ),
                   style: styleRed,
                    onPressed: () async {
                      try {
                        if (_forgotPasswordFormKey.currentState.validate()) {
                          await _auth.forgotPassword(email: _email.text.trim());
                          Navigator.of(context).pop(true);
                          Flushbar(
                            flushbarPosition: FlushbarPosition.TOP,
                            message:
                                'We just emailed you a password reset link.',
                            duration: Duration(seconds: 5),
                            margin: EdgeInsets.all(8),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          )..show(context);
                        }
                      } catch (e, s) {
                        await FirebaseCrashlytics.instance
                            .log('Reset password pressed');
                        await FirebaseCrashlytics.instance
                            .recordError(e, s, reason: 'Reset password pressed');
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return ErrorAlert(errorMessage: e.toString());
                            });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
