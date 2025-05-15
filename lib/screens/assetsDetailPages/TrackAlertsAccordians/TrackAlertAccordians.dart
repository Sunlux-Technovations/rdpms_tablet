import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';

import 'package:rdpms_tablet/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TrackAlertsAccordians extends StatefulWidget {
  final List<dynamic>? maintenanceList;
  final VoidCallback onShowAlertsDetailsForTrack;
  const TrackAlertsAccordians(
      {super.key,
      required this.maintenanceList,
      required this.onShowAlertsDetailsForTrack});
  @override
  TrackAlertsAccordiansState createState() => TrackAlertsAccordiansState();
}

class TrackAlertsAccordiansState extends State<TrackAlertsAccordians> {
  bool? alertVisible;
  int? totalRespTime;
  int? totalAckTime;
  Widget buildAlertHeader(BuildContext context) {
    return SizedBox(
      width: 380.w,
      height: 35.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 170.w,
            height: 30.h,
            child: Padding(
              padding: EdgeInsets.only(left: 15.w, top: 9.h),
              child: UiHelper.customText(
                text: "Header Data",
                color: Appcolors.secondary,
                fontsize: 13.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'bold',
              ),
            ),
          ),
          SizedBox(
            width: 100.w,
            height: 30.h,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Center(
                child: Card(
                  elevation: 4.r,
                  child: Container(
                    width: 90.w,
                    height: 30.h,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Center(
                      child: UiHelper.customText(
                        text: "Alert",
                        color: Appcolors.secondary,
                        fontsize: 13.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'bold',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAlertInfo(BuildContext context) {
    if (widget.maintenanceList?[0]['alerts']?.length != 0) {
      alertVisible =
          widget.maintenanceList![0]['alerts'][0]['acknowledged'] != 0;
      DateTime alertTime =
          DateTime.parse(widget.maintenanceList![0]['alerts'][0]['alert_time']);
      DateTime respTime =
          widget.maintenanceList![0]['alerts'][0]['response_time'] != null
              ? DateTime.parse(
                  widget.maintenanceList![0]['alerts'][0]['response_time'])
              : DateTime.now();
      DateTime ackTime =
          widget.maintenanceList![0]['alerts'][0]['acknowledged_time'] != null
              ? DateTime.parse(
                  widget.maintenanceList![0]['alerts'][0]['acknowledged_time'])
              : DateTime.now();
      totalRespTime = respTime.difference(alertTime).inHours;
      totalAckTime = ackTime.difference(alertTime).inHours;
    }
    return Row(
      children: [
        SizedBox(
          width: 200.w,
          height: 124.h,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 200.w,
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
                          text: "Alert Time",
                          color: Appcolors.secondary,
                          fontsize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        SizedBox(height: 6.h),
                        UiHelper.customText(
                          text:
                              widget.maintenanceList?[0]['alerts']?.length != 0
                                  ? DateFormat('yyyy-MM-dd HH:mm').format(
                                      DateTime.parse(widget.maintenanceList?[0]
                                          ['alerts'][0]['alert_time']))
                                  : "",
                          color: Appcolors.secondary,
                          fontsize: 14.sp,
                          fontWeight: FontWeight.w700,
                        )
                      ],
                    )
                  ],
                ),
              ),
              alertVisible == true
                  ? SizedBox(
                      width: 200.w,
                      height: 70.h,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 200.w,
                            height: 42.h,
                            child: Padding(
                              padding: EdgeInsets.only(left: 11.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  UiHelper.customText(
                                    text: "Acknowledge Time",
                                    color: Appcolors.secondary,
                                    fontsize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  UiHelper.customText(
                                    text: widget.maintenanceList?[0]['alerts']
                                                    ?.length !=
                                                0 &&
                                            widget.maintenanceList?[0]['alerts']
                                                    [0]['acknowledged'] ==
                                                1
                                        ? DateFormat('yyyy-MM-dd HH:mm').format(
                                            DateTime.parse(
                                                widget.maintenanceList?[0]
                                                        ['alerts']?[0]
                                                    ['acknowledged_time']))
                                        : "Not Acknowledged",
                                    color: Appcolors.secondary,
                                    fontsize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                  )
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 200.w,
                            height: 24.h,
                            child: Padding(
                              padding: EdgeInsets.only(left: 11.w),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [],
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  : Card(
                      elevation: 7.r,
                      child: Container(
                        width: 200.w,
                        height: 22.h,
                        decoration: BoxDecoration(
                          color: HexColor("#457b9d"),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Center(
                          child: UiHelper.customText(
                            text: "Alert Not Acknowledged",
                            color: Appcolors.secondary,
                            fontsize: 13.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'bold',
                          ),
                        ),
                      ),
                    )
            ],
          ),
        ),
        SizedBox(
          width: 0.3.sw,
          height: 0.15.sh,
          child: SfCircularChart(
            series: <CircularSeries>[
              RadialBarSeries<ChartData, String>(
                dataSource: [
                  ChartData('Category A', (totalRespTime ?? 0).toDouble()),
                  ChartData('Category B', (totalAckTime ?? 0).toDouble()),
                ],
                xValueMapper: (ChartData data, _) => data.category,
                yValueMapper: (ChartData data, _) => data.value,
                trackColor: HexColor("#457b9d"),
                pointColorMapper: (ChartData data, _) {
                  switch (data.category) {
                    case 'Category A':
                      return HexColor("#fb8500");
                    case 'Category B':
                      return HexColor("#e63946");
                    default:
                      return Colors.grey;
                  }
                },
                radius: '80%',
                innerRadius: '40%',
                cornerStyle: CornerStyle.bothCurve,
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget buildChartWidget(BuildContext context) {
    List<ChartData> chartData = [
      ChartData('Category A', (totalRespTime ?? 0).toDouble()),
      ChartData('Category B', (totalAckTime ?? 0).toDouble()),
    ];
    return SizedBox(
      width: 0.3.sw,
      height: 0.15.sh,
      child: SfCircularChart(
        series: <CircularSeries>[
          RadialBarSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.category,
            yValueMapper: (ChartData data, _) => data.value,
            trackColor: HexColor("#457b9d"),
            pointColorMapper: (ChartData data, _) {
              switch (data.category) {
                case 'Category A':
                  return HexColor("#fb8500");
                case 'Category B':
                  return HexColor("#e63946");
                default:
                  return Colors.grey;
              }
            },
            radius: '80%',
            innerRadius: '40%',
            cornerStyle: CornerStyle.bothCurve,
          )
        ],
      ),
    );
  }

  Widget buildShowMoreButton(BuildContext context) {
    return Container(
      width: 400.w,
      height: 28.h,
      margin: EdgeInsets.only(top: 0.h),
      child: Center(
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: widget.onShowAlertsDetailsForTrack,
          child: Container(
            width: 160.w,
            height: 30.h,
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
                Icon(
                  Icons.send,
                  color: Appcolors.secondary,
                  size: 16.r,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Card(
        elevation: 8.r,
        child: widget.maintenanceList?[0]['alerts']?.length != 0
            ? Column(
                children: [
                  buildAlertHeader(context),
                  buildAlertInfo(context),
                  buildChartWidget(context),
                  buildShowMoreButton(context),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  color: Appcolors.backGroundColor,
                  borderRadius: BorderRadius.circular(13.r),
                ),
                child: Center(
                  child: UiHelper.customText(
                    text: "No alerts found.",
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

class ChartData {
  ChartData(this.category, this.value);
  final String category;
  final double value;
}
