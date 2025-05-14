// lib/screens/Loginscreen/Loginscreen.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rdpms_tablet/Apis/Urls.dart';
import 'package:rdpms_tablet/Apis/auth.dart';
import 'package:rdpms_tablet/main.dart';
import 'package:rdpms_tablet/screens/Dashboard/Dashboard.dart';
import 'package:rdpms_tablet/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  final TextEditingController userName = TextEditingController();
  final TextEditingController password = TextEditingController();
  final Dio dio = Dio();
  bool isLoading = false;
  bool showPassword = true;

  void login() async {
    if (userName.text.isNotEmpty && password.text.isNotEmpty) {
      setState(() => isLoading = true);

      Response response = await dio.post(
        loginUrl,
        data: {"email": userName.text, "password": password.text},
      );

      setState(() => isLoading = false);

      if (response.data['status'] == 1) {
  

        List<String> headers =
            response.headers['authorization'] as List<String>;
        auth.jwt = headers[0];
        auth.username = response.data['data']['username'];
final prefs = await SharedPreferences.getInstance();
await prefs.setBool('isLoggedIn', true);

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Dashboard()));
        GlobalData().name = response.data['data']['username'].toString();
        GlobalData().department =
            response.data['data']['entitlement'].toString();
        GlobalData().userName = auth.username;
        GlobalData().stations = response.data['data']['stations'].toList();
      } else {
        MotionToast.error(
          description: UiHelper.customText(
              text: "Invalid Username or Password",
              color: Colors.white,
              fontsize: 14.r,
              fontWeight: FontWeight.normal,
              fontFamily: "bold"),
          width: 300.w,
          height: 50.h,
          position: MotionToastPosition.top,
        ).show(context);
      }
    } else {
      MotionToast.error(
        description: UiHelper.customText(
            text: "Please fill the details",
            color: Colors.white,
            fontsize: 14.r,
            fontWeight: FontWeight.normal,
            fontFamily: "bold"),
        width: 300.w,
        height: 50.h,
        position: MotionToastPosition.top,
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Appcolors.backGroundColor,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 40.h),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 300.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 100.h),
                      CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 65.r,
                        child: UiHelper.customImage(img: "trail_logo.png"),
                      ),
                      SizedBox(height: 20.h),
                      UiHelper.customTextFeild(
                        hintText: "Username",
                        controller: userName,
                        obscureText: false,
                        prefixIcon: const Icon(Icons.people),
                        context: context,
                      ),
                      SizedBox(height: 20.h),
                      UiHelper.customTextFeild(
                        hintText: "Password",
                        controller: password,
                        obscureText: showPassword,
                        prefixIcon: const Icon(Icons.password_sharp),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() => showPassword = !showPassword);
                          },
                          child: Icon(
                            showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black,
                          ),
                        ),
                        context: context,
                      ),
                      SizedBox(height: 20.h),
                      SizedBox(
                        width: 150.h,
                        height: 55.h,
                        child: InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: login,
                          borderRadius: BorderRadius.circular(10.r),
                          child: Material(
                            elevation: 4.r,
                            borderRadius: BorderRadius.circular(10.r),
                            color: Appcolors.buttonColor,
                            child: Center(
                              child: UiHelper.customText(
                                text: "Log In",
                                color: Colors.white,
                                fontsize: 15.sp,
                                fontWeight: FontWeight.w500,
                                fontFamily: "bold",
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 130.h),
                      Container(
                        margin: EdgeInsets.only(bottom: 30.h),
                        width: 200.w,
                        height: 50.h,
                        child: UiHelper.customImage(img: "Awards (1).png"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
