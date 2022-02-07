import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

class Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        indicatorColor: Colors.white,
        primaryColor: Colors.blue[900],
        colorScheme: ColorScheme.fromSwatch()
            .copyWith(primary: Colors.blue[900], secondary: Colors.blue[900]),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            primary: Colors.blueAccent, // This is a custom color variable
          ),
        ),
      ),
      home: Scaffold(
        backgroundColor: Colors.blue[900],
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  color: Colors.blue[900],
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Repeat',
                    style: GoogleFonts.baumans(
                        textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 65.0,
                            fontWeight: FontWeight.w400)),
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
