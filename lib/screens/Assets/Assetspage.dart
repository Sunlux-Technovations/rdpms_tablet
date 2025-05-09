import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Assetspage extends StatefulWidget {
  const Assetspage({super.key});

  @override
  State<Assetspage> createState() => _AssetspageState();
}

class _AssetspageState extends State<Assetspage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
  
      body: Center(
        child: Text(
          'Welcome to the Assets Page!',
          style: TextStyle(fontSize: 24.sp),
        ),
      ),
    );
  }
}