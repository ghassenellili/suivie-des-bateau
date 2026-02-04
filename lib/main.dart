import 'package:flutter/material.dart';
import 'package:primafish/SplashScreen/SplashScreen.dart';
import 'package:primafish/login_signup/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Home(userEmail: 'default@example.com'),
    );
  }
}
