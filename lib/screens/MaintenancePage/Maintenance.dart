import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Maintenance extends StatefulWidget {
  const Maintenance({super.key});

  @override
  State<Maintenance> createState() => _MaintenanceState();
}

class _MaintenanceState extends State<Maintenance> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
  
      body: Center(
        child: Text(
          'Welcome to the Maintenance Page! hiiiiii',
          style: TextStyle(fontSize: 24.sp),
        ),
      ),
    );
  }
}