import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Alerts extends StatefulWidget {
  const Alerts({super.key});

  @override
  State<Alerts> createState() => _AlertsState();
}

class _AlertsState extends State<Alerts> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Center(
        child: Text(
          'Welcome to the Alerts Page!',
          style: TextStyle(fontSize: 24.sp),
        ),
      ),
    );
  }
}