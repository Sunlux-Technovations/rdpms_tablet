import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:rdpms_tablet/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';

class Pointanalyticsaccordians extends StatefulWidget {
  final List<dynamic>? analyticsList;
  final bool? lazyLoading;
  const Pointanalyticsaccordians(
      {super.key, this.analyticsList, this.lazyLoading});
  @override
  PointanalyticsaccordiansState createState() =>
      PointanalyticsaccordiansState();
}

class PointanalyticsaccordiansState extends State<Pointanalyticsaccordians> {
  dynamic pointData = [];
  Widget buildHeader(BuildContext context) {
    return SizedBox(
      width: 380.w,
      height: 45.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 10.w),
            child: UiHelper.xsmalltxt_bold(
              text: "Analytics",
              color: Appcolors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTableHeader(BuildContext context) {
    return SizedBox(
      width: 390.w,
      height: 45.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 65,
            height: 45.h,
            child: Center(
              child: UiHelper.xsmalltxt_bold(
                text: "Device",
                color: Appcolors.primary,
              ),
            ),
          ),
          SizedBox(
            width: 65,
            height: 45.h,
            child: Center(
              child: UiHelper.xsmalltxt_bold(
                text: "Type",
                color: Appcolors.primary,
              ),
            ),
          ),
          SizedBox(
            width: 65,
            height: 45.h,
            child: Center(
              child: UiHelper.xsmalltxt_bold(
                text: "Average",
                color: Appcolors.primary,
              ),
            ),
          ),
          SizedBox(
            width: 65,
            height: 45.h,
            child: Center(
              child: UiHelper.xsmalltxt_bold(
                text: "Variance",
                color: Appcolors.primary,
              ),
            ),
          ),
          SizedBox(
            width: 75,
            height: 45.h,
            child: Center(
              child: UiHelper.xsmalltxt_bold(
                text: "Standard Deviation",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTableBody(BuildContext context) {
    return SizedBox(
      width: 400.w,
      height: 155.h,
      child: ListView.separated(
        itemCount: pointData[0]?.length ?? 0,
        separatorBuilder: (context, index) => SizedBox(height: 15.h),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 400.w,
            height: 33.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 60.w,
                  height: 45.h,
                  child: Center(
                    child: UiHelper.customText(
                      text: pointData[0][index]['Tag ID'].toString(),
                      color: Appcolors.primary,
                      fontsize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60.w,
                  height: 45.h,
                  child: Center(
                    child: UiHelper.customText(
                      text: pointData[0][index]['Sensor Type'].toString(),
                      color: Appcolors.primary,
                      fontsize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60.w,
                  height: 45.h,
                  child: Center(
                    child: UiHelper.customText(
                      text: pointData[0][index]['Average Value'].toString(),
                      color: Appcolors.primary,
                      fontsize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60.w,
                  height: 45.h,
                  child: Center(
                    child: UiHelper.customText(
                      text: pointData[0][index]['Variance'].toString(),
                      color: Appcolors.primary,
                      fontsize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 60.w,
                  height: 45.h,
                  child: Center(
                    child: UiHelper.customText(
                      text:
                          pointData[0][index]['Standard Deviation'].toString(),
                      color: Appcolors.primary,
                      fontsize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildContent(BuildContext context) {
    pointData = widget.analyticsList;
    return Column(
      children: [
        buildHeader(context),
        buildTableHeader(context),
        buildTableBody(context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.lazyLoading == true
          ? Center(
              child: LoadingAnimationWidget.stretchedDots(
                  color: Appcolors.backGroundColor, size: 50.r))
          : buildContent(context),
    );
  }
}
