import 'package:flutter/material.dart';
import 'package:notification_map/pages/InteractiveMap.dart';
import 'package:notification_map/pages/TestFile.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const InteractiveMap()
    );
  }
}