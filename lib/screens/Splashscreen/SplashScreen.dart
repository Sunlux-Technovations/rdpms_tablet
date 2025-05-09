import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rdpms_tablet/screens/Loginscreen/Loginscreen.dart';
import 'package:rdpms_tablet/widgets/UiHelper.dart';




class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => SplashscreenState();
}

class SplashscreenState extends State<Splashscreen> {
  static const LOGINKEY = "login";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Loginscreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: UiHelper.customImage(img: "splash.jpg", fit: BoxFit.cover),
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Color.fromRGBO(0, 0, 0, 0.5),
          ),
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 89.r,
                  child: UiHelper.customImage(img: "trail_logo.png"),
                ),
                SizedBox(
                  height: 10.h,
                ),
                UiHelper.customText(
                    text: "RDPMS",
                    color: Colors.white,
                    fontsize: 40.sp,
                    fontFamily: "bold",
                    fontWeight: FontWeight.bold)
              ],
            ),
          )
        ],
      ),
    );
  }
}