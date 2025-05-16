import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motion_toast/motion_toast.dart';

class UiHelper {
  static customImage({required String img, BoxFit? fit}) {
    return Image.asset("assets/images/$img", fit: fit);
  }

  static Widget customText({
    required String text,
    required Color color,
    required double fontsize,
    required FontWeight fontWeight,
    String? fontFamily,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        color: color,
        fontSize: fontsize.sp,
        fontWeight: fontWeight,
        fontFamily: fontFamily ?? "regular",
      ),
    );
  }

  static customTextFeild(
      {required String hintText,
      required TextEditingController controller,
      suffixIcon,
      Icon? prefixIcon,
      required obscureText,
      required BuildContext context}) {
    return Container(
      width: 0.8.sw,
      height: 0.09.sh,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Align(
        alignment: Alignment.center,
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          style: TextStyle(
              color: Colors.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.w300,
              fontFamily: "regular"),
          decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(vertical: 30.0.h),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  borderSide:
                      BorderSide(color: Colors.orangeAccent, width: 3.w)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  borderSide: BorderSide(color: Colors.white, width: 2.w)),
              hintStyle: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 14.sp,
                  fontFamily: "regular",
                  fontWeight: FontWeight.w600),
              border: InputBorder.none,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon),
        ),
      ),
    );
  }

  static profileTextField(
      {required String hintText,
      required Function(String) onChange,
      required TextEditingController controller,
      required bool obscureText,
      TextAlign? textAlign,
      required BuildContext context}) {
    return Container(
      width: 0.6.sw,
      height: 0.08.sh,
      decoration: const BoxDecoration(),
      child: TextField(
        textAlign: TextAlign.center,
        obscureText: obscureText,
        controller: controller,
        style: TextStyle(
            color: Colors.white,
            fontFamily: "regular",
            fontSize: 18.sp,
            fontWeight: FontWeight.w700),
        decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontFamily: "regular",
                fontSize: 18.sp,
                fontWeight: FontWeight.w700),
            border: InputBorder.none),
        onChanged: onChange,
      ),
    );
  }

  static void showWarningToast(BuildContext context, String message) {
    MotionToast.warning(
      width: 300.w,
      height: 50.h,
      description: Text(
        message,
        style: TextStyle(
          fontFamily: "bold",
          fontSize: 14.sp,
          fontWeight: FontWeight.normal,
        ),
      ),
      position: MotionToastPosition.top,
    ).show(context);
  }

  static void showSuccessToast(BuildContext context, String message) {
    MotionToast.success(
      width: 300.w,
      height: 50.h,
      description: Text(
        message,
        style: TextStyle(
          fontFamily: "bold",
          fontSize: 14.sp,
          fontWeight: FontWeight.normal,
        ),
      ),
      position: MotionToastPosition.top,
    ).show(context);
  }

  static void showErrorToast(BuildContext context, String message) {
    MotionToast.error(
      width: 300.w,
      height: 50.h,
      description: Text(
        message,
        style: TextStyle(
          fontFamily: "bold",
          fontSize: 14.sp,
          fontWeight: FontWeight.normal,
        ),
      ),
      position: MotionToastPosition.top,
    ).show(context);
  }

  static Widget customHeadings({
    required String text,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: 30.sp,
        fontWeight: FontWeight.w700,
        fontFamily: "bold",
      ),
    );
  }

  static Widget bigNumber({
    required String number,
  }) {
    return Text(
      number,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: 36.sp,
        fontWeight: FontWeight.bold,
        fontFamily: "bold",
      ),
    );
  }

  static Widget timenum({
    required String number,
  }) {
    return Text(
      number,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
        fontFamily: "bold",
      ),
    );
  }

  static Widget smallText({
    required String text,
    required Color color,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: 20.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "regular",
      ),
    );
  }

  static Widget smallText_bold({
    required String text,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: 20.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "bold",
      ),
    );
  }

  static Widget button({
    required String text,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white,
        fontSize: 15.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "bold",
      ),
    );
  }

  static Widget xxsmalltxt_bold({
    required String text,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: 18.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "bold",
      ),
    );
  }

  static Widget xxsmallnum_bold({
    required String number,
  }) {
    return Text(
      number,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: 18.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "bold",
      ),
    );
  }

  static Widget NDF({
    required String text,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.grey,
        fontSize: 18.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "regular",
      ),
    );
  }

  static Widget notiFy({
    required String text,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: 20.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "bold",
      ),
    );
  }

  static Widget name({
    required String text,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: 18.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "regular",
      ),
    );
  }

  static Widget deptname({
    required String text,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white,
        fontSize: 18.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "regular",
      ),
    );
  }

  static Widget subHeading({
    required String text,
    required Color color,
    double? fontSize,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: fontSize ?? 18.sp, // Use the provided fontSize or default to 18.sp
        fontWeight: FontWeight.normal,
        fontFamily: "regular",
      ),
    );
  }

  static Widget username({
    required String text,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: 27.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "bold",
      ),
    );
  }

  static Widget button_large({
    required String text,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: 18.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "bold",
      ),
    );
  }

  static Widget heading2({
    required String text,
    required Color color,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: 25.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "bold",
      ),
    );
  }

  static Widget normal_bold({
    required String text,
    required Color color,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: 18.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "bold",
      ),
    );
  }

  static Widget time({
    required String text,
    required Color color,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: 15.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "bold",
      ),
    );
  }

  static Widget normal_txt({
    required String text,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: 16.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "regular",
      ),
    );
  }

  static Widget xsmalltxt({
    required String text,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: 12.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "regular",
      ),
    );
  }

  static Widget xsmalltxt_bold({
    required String text,
    Color? color,
    int? maxLines,
  }) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color ?? Colors.black,
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
        fontFamily: "bold",
      ),
    );
  }

  static Widget Smalltxt_bold({
    required String text,
    Color? color,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color ?? Colors.black,
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
        fontFamily: "bold",
      ),
    );
  }

  static Widget Smalltxt({
    required String text,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: 14.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "regular",
      ),
    );
  }

  static Widget normal({
    required String text,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: 12.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "regular",
      ),
    );
  }

  static Widget xxsmalltxt({
    required String text,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: 10.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "regular",
      ),
    );
  }

  static Widget topic_name({
    required String text,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: 18.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "bold",
      ),
    );
  }

  static Widget tech_name({
    required String text,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black,
        fontSize: 15.sp,
        fontWeight: FontWeight.w800,
        fontFamily: "regular",
      ),
    );
  }

  static Widget card_details({
    required String text,
    Color? color,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color ?? Colors.black,
        fontSize: 15.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "bold",
      ),
    );
  }

  static Widget card_details_time({
    required String text,
    Color? color,
  }) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color ?? Colors.black,
        fontSize: 13.sp,
        fontWeight: FontWeight.normal,
        fontFamily: "bold",
      ),
    );
  }
}