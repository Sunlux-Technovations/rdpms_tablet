import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:rdpms_tablet/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';

class TrackMaintenanceAccordians extends StatefulWidget {
  final List<dynamic> maintenanceList;
  final bool? lazyLoading;
  final Function(Map<String, dynamic> maintenanceData)
      onShowMaintenanceDetailsForTrack;
  const TrackMaintenanceAccordians({
    super.key,
    required this.maintenanceList,
    this.lazyLoading,
    required this.onShowMaintenanceDetailsForTrack,
  });

  @override
  State<TrackMaintenanceAccordians> createState() =>
      _TrackMaintenanceAccordiansState();
}

class _TrackMaintenanceAccordiansState
    extends State<TrackMaintenanceAccordians> {
  bool get hasMaintenanceData =>
      widget.maintenanceList.isNotEmpty &&
      widget.maintenanceList[0]['maintenance'] != null &&
      widget.maintenanceList[0]['maintenance'].isNotEmpty &&
      widget.maintenanceList[0]['maintenance'][0]['tag_id'] != 0;

  Widget buildTagRow() {
    final maintenance = widget.maintenanceList[0]['maintenance'];
    return SizedBox(
      width: 380.w,
      height: 33.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80.w,
            height: 40.h,
            child: Center(
              child: UiHelper.customText(
                text: maintenance.length != 0
                    ? maintenance[0]['tag_id'].toString()
                    : "No Data Found",
                color: Appcolors.secondary,
                fontsize: 14.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'bold',
              ),
            ),
          ),
          SizedBox(
            width: 110.w,
            height: 40.h,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Center(
                child: UiHelper.customText(
                  text: maintenance.length != 0
                      ? maintenance[0]['tags']
                          .toString()
                          .replaceAll(",", " ")
                          .replaceAll('"', "")
                      : " ",
                  color: Appcolors.secondary,
                  fontsize: 14.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'bold',
                ),
              ),
            ),
          ),
          SizedBox(
            width: 100.w,
            height: 40.h,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Center(
                child: UiHelper.customText(
                  text: maintenance.length != 0
                      ? maintenance[0]['status'].toString()
                      : "",
                  color: Appcolors.secondary,
                  fontsize: 14.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'bold',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTimeRow() {
    final maintenance = widget.maintenanceList[0]['maintenance'];
    return Row(
      children: [
        SizedBox(width: 12.w),
        SizedBox(
          width: 230.w,
          height: 120.h,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 230.w,
                height: 55.h,
                child: Row(
                  children: [
                    SizedBox(width: 5.w),
                    Icon(Icons.date_range,
                        color: Appcolors.secondary, size: 33.r),
                    SizedBox(width: 5.w),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UiHelper.customText(
                          text: "Start Time",
                          color: Appcolors.secondary,
                          fontsize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        SizedBox(height: 6.h),
                        UiHelper.customText(
                          text: maintenance.length != 0
                              ? DateTime.parse(maintenance[0]['created_at'])
                                  .toLocal()
                                  .toString()
                              : "",
                          color: Appcolors.secondary,
                          fontsize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 37.w),
                child: Container(
                  width: 190.w,
                  height: 1.h,
                  color: Colors.grey.shade500,
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 7.h),
                width: 230.w,
                height: 55.h,
                child: Row(
                  children: [
                    SizedBox(width: 5.w),
                    Icon(Icons.date_range,
                        color: Appcolors.secondary, size: 33.r),
                    SizedBox(width: 5.w),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UiHelper.customText(
                          text: "End Time",
                          color: Appcolors.secondary,
                          fontsize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        SizedBox(height: 5.h),
                        UiHelper.customText(
                          text: maintenance.length != 0
                              ? DateTime.parse(maintenance[0]['end_at'])
                                  .toLocal()
                                  .toString()
                              : "",
                          color: Appcolors.secondary,
                          fontsize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 15.h),
          child: Column(
            children: [
              Container(
                width: 70.w,
                height: 70.h,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange, width: 5.w),
                  borderRadius: BorderRadius.circular(100.r),
                ),
                child: Center(
                  child: UiHelper.customText(
                    text: maintenance.length != 0
                        ? maintenance[0]['duration'].split(".")[0].toString()
                        : "",
                    color: Appcolors.secondary,
                    fontsize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              UiHelper.customText(
                text: "Hours",
                color: Appcolors.secondary,
                fontsize: 18.sp,
                fontWeight: FontWeight.w700,
              )
            ],
          ),
        )
      ],
    );
  }

  Widget buildShowMoreButton() {
    return SizedBox(
      width: 380.w,
      height: 35.h,
      child: Center(
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () {
            if (widget.maintenanceList.isNotEmpty) {
              widget
                  .onShowMaintenanceDetailsForTrack(widget.maintenanceList[0]);
            }
          },
          child: Container(
            width: 180.w,
            height: 35.h,
            decoration: BoxDecoration(
              color: HexColor("#457b9d"),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                UiHelper.customText(
                  text: "Show More Details",
                  color: Appcolors.secondary,
                  fontsize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
                Icon(Icons.send, color: Appcolors.secondary, size: 16.r),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMaintenanceContent() {
    return Container(
      width: 380.w,
      height: 207.h,
      decoration: BoxDecoration(
        color: Appcolors.backGroundColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          buildTagRow(),
          buildTimeRow(),
          buildShowMoreButton(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.lazyLoading == true
          ? Center(
              child: LoadingAnimationWidget.stretchedDots(
                color: Appcolors.backGroundColor,
                size: 50.r,
              ),
            )
          : Card(
              elevation: 8.r,
              child: hasMaintenanceData
                  ? buildMaintenanceContent()
                  : Container(
                      decoration: BoxDecoration(
                        color: Appcolors.backGroundColor,
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      child: Center(
                        child: UiHelper.customText(
                          text: "No maintenance logs found.",
                          color: Appcolors.secondary,
                          fontsize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
    );
  }
}

class CheckMarkColors {
  final Color content, background;
  const CheckMarkColors({required this.content, required this.background});
}

class CheckMarkStyle {
  final CheckMarkColors loading, success, error;
  const CheckMarkStyle({
    required this.loading,
    required this.success,
    required this.error,
  });
}
