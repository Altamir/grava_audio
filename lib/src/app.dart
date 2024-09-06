import 'package:flutter/material.dart';
import 'package:grava_audio/src/home.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Grava Audio",
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}
