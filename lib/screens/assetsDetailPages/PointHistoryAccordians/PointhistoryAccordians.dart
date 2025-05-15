import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:rdpms_tablet/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';

class PointhistoryAccordian extends StatefulWidget {
  final List<dynamic>? maintenanceList;
  final bool? lazyLoading;
  const PointhistoryAccordian(
      {super.key, this.maintenanceList, this.lazyLoading});
  @override
  PointhistoryAccordianState createState() => PointhistoryAccordianState();
}

class PointhistoryAccordianState extends State<PointhistoryAccordian> {
  dynamic historyData;
  Widget buildHeaderRow(BuildContext context) {
    return SizedBox(
      width: 375.w,
      height: 45.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 10.w),
            child: UiHelper.customText(
              text: "History",
              fontFamily: 'bold',
              color: Appcolors.primary,
              fontsize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHistoryItem(BuildContext context, int index) {
    return SizedBox(
      width: 375.w,
      height: 200.h,
      child: Column(
        children: [
          SizedBox(
            width: 375.w,
            height: 50.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  "Device \n  ${widget.maintenanceList![0]['history'][index][0]['tagid'].toString()}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: "bold",
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  "Control \n  ${widget.maintenanceList![0]['history'][index][0]["control_type"].toString()}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: "bold",
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child: Text(
                    "Date & Time \n  ${widget.maintenanceList![0]['history'][index][0]["datetime"].toString()}",
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      color: Appcolors.primary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            width: 375.w,
            height: 150.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 21.w),
                  child: Text(
                    "Values:",
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 13.sp),
                  ),
                ),
                SizedBox(
                  width: 375.w,
                  height: 120.h,
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      mainAxisSpacing: 10.0,
                      crossAxisSpacing: 10.0,
                      childAspectRatio: 4.0,
                      crossAxisCount: 4,
                    ),
                    itemCount:
                        widget.maintenanceList![0]['history'][index].length,
                    itemBuilder: (context, itemIndex) {
                      return Center(
                        child: Text(
                          widget.maintenanceList![0]['history'][index]
                                  [itemIndex]['val']
                              .toStringAsFixed(3),
                          style: TextStyle(
                            color: Appcolors.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12.sp,
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget buildContent(BuildContext context) {
    historyData = widget.maintenanceList;
    return Column(
      children: [
        buildHeaderRow(context),
        SizedBox(
          width: 390.w,
          height: 210.h,
          child: ListView.separated(
            itemCount: widget.maintenanceList![0]['history'].length,
            separatorBuilder: (context, index) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              return buildHistoryItem(context, index);
            },
          ),
        )
      ],
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
          : buildContent(context),
    );
  }
}
