import 'package:flutter/material.dart';
import 'package:video_compress_example/compress/compress_folder.dart';
import 'package:video_compress_example/compress/compress_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CompressFolder(),
    );
  }
}
