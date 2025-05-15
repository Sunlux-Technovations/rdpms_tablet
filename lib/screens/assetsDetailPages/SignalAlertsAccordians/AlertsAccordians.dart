import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';

import 'package:rdpms_tablet/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Alertsaccordians extends StatefulWidget {
  final List<dynamic>? maintenanceList;
  final VoidCallback onShowAlertsDetails;
  const Alertsaccordians(
      {super.key,
      required this.maintenanceList,
      required this.onShowAlertsDetails});

  @override
  State<Alertsaccordians> createState() => _AlertsaccordiansState();
}

class _AlertsaccordiansState extends State<Alertsaccordians> {
  bool? alertVisible;
  int? totalRespTime;
  int? totalAckTime;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.maintenanceList?[0]['alerts']?.length != 0) {
      alertVisible =
          widget.maintenanceList![0]['alerts'][0]['acknowledged'] == 0
              ? false
              : true;

      DateTime alertTime =
          DateTime.parse(widget.maintenanceList![0]['alerts'][0]['alert_time']);

      DateTime respTime;
      if (widget.maintenanceList![0]['alerts'][0]['response_time'] != null) {
        respTime = DateTime.parse(
            widget.maintenanceList![0]['alerts'][0]['response_time']);
      } else {
        respTime = DateTime.now();
      }

      DateTime ackTime;
      if (widget.maintenanceList![0]['alerts'][0]['acknowledged_time'] !=
          null) {
        ackTime = DateTime.parse(
            widget.maintenanceList![0]['alerts'][0]['acknowledged_time']);
      } else {
        ackTime = DateTime.now();
      }

      totalRespTime = respTime.difference(alertTime).inHours;
      totalAckTime = ackTime.difference(alertTime).inHours;
    }

    final List<ChartData> chartData = [
      ChartData('Category A', (totalRespTime ?? 0).toDouble()),
      ChartData('Category B', (totalAckTime ?? 0).toDouble()),
    ];

    return Scaffold(
      body: Card(
          elevation: 8.r,
          child: widget.maintenanceList?[0]['alerts']?.length != 0
              ? Container(
                  width: 380.w,
                  height: 210.h,
                  decoration: BoxDecoration(
                      color: Appcolors.backGroundColor,
                      borderRadius: BorderRadius.circular(10.r)),
                  child: Column(
                    children: [
                      SizedBox(
                          width: 380.w,
                          height: 35.h,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                  width: 170.w,
                                  height: 30.h,
                                  child: Padding(
                                    padding:
                                        EdgeInsets.only(left: 15.w, top: 9.h),
                                    child: UiHelper.customText(
                                        text: widget
                                                    .maintenanceList?[0]
                                                        ['alerts']
                                                    ?.length !=
                                                0
                                            ? widget.maintenanceList?[0]
                                                        ['alerts'][0]?['tagid']
                                                    .toString() ??
                                                ""
                                            : "No Data Found",
                                        color: Appcolors.secondary,
                                        fontsize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'bold'),
                                  )),
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
                                              color: widget
                                                              .maintenanceList?[
                                                                  0]['alerts']
                                                              ?.length !=
                                                          0 &&
                                                      widget.maintenanceList?[0]
                                                                  ['alerts'][0]
                                                              ?['alerttype'] ==
                                                          "Warning"
                                                  ? Colors.amber
                                                  : Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(10.r)),
                                          child: Center(
                                            child: UiHelper.customText(
                                                text: widget
                                                            .maintenanceList?[0]
                                                                ['alerts']
                                                            ?.length !=
                                                        0
                                                    ? widget.maintenanceList?[0]
                                                                ['alerts']?[0]
                                                                ['alerttype']
                                                            .toString() ??
                                                        ""
                                                    : "",
                                                color: Appcolors.secondary,
                                                fontsize: 13.sp,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'bold'),
                                          )),
                                    )),
                                  )),
                            ],
                          )),
                      Row(
                        children: [
                          SizedBox(
                            width: 200.w,
                            height: 124.h,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SizedBox(
                                  width: 200.w,
                                  height: 50.h,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 11.w),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        UiHelper.customText(
                                            text: "Alert Time",
                                            color: Appcolors.secondary,
                                            fontsize: 14.sp,
                                            fontWeight: FontWeight.w700),
                                        UiHelper.customText(
                                            text: widget
                                                        .maintenanceList?[0]
                                                            ['alerts']
                                                        ?.length !=
                                                    0
                                                ? DateFormat('yyyy-MM-dd HH:mm')
                                                    .format(DateTime.parse(
                                                        widget.maintenanceList?[
                                                                0]['alerts'][0]
                                                            ['alert_time']))
                                                    .toString()
                                                : "",
                                            color: Appcolors.secondary,
                                            fontsize: 14.sp,
                                            fontWeight: FontWeight.w700)
                                      ],
                                    ),
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
                                                padding:
                                                    EdgeInsets.only(left: 11.w),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    UiHelper.customText(
                                                        text:
                                                            "Acknowledge Time",
                                                        color:
                                                            Appcolors.secondary,
                                                        fontsize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w700),
                                                    UiHelper.customText(
                                                        text: widget.maintenanceList?[0]['alerts']?.length !=
                                                                    0 &&
                                                                widget.maintenanceList?[0]['alerts']
                                                                            [0][
                                                                        'acknowledged'] ==
                                                                    1
                                                            ? DateFormat('yyyy-MM-dd HH:mm')
                                                                .format(DateTime.parse(
                                                                    widget.maintenanceList?[0]
                                                                            ?['alerts']?[0]
                                                                        ['acknowledged_time']))
                                                                .toString()
                                                            : "Not Acknowledged",
                                                        color: Appcolors.secondary,
                                                        fontsize: 13.sp,
                                                        fontWeight: FontWeight.w700)
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 200.w,
                                              height: 24.h,
                                              child: Padding(
                                                padding:
                                                    EdgeInsets.only(left: 11.w),
                                                child: const Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
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
                                              borderRadius:
                                                  BorderRadius.circular(10.r)),
                                          child: Center(
                                            child: UiHelper.customText(
                                                text: "Alert Not Acknowledged",
                                                color: Appcolors.secondary,
                                                fontsize: 13.sp,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'bold'),
                                          ),
                                        ),
                                      )
                              ],
                            ),
                          ),
                          widget.maintenanceList?[0]['alerts']?.length != 0
                              ? Container(
                                  child: widget.maintenanceList?[0]['alerts'][0]
                                                  ['acknowledged_time'] !=
                                              null ||
                                          widget.maintenanceList?[0]['alerts']
                                                  [0]['response_time'] !=
                                              null
                                      ? SizedBox(
                                          width: 0.3.sw,
                                          height: 0.15.sh,
                                          child: SfCircularChart(
                                            series: <CircularSeries>[
                                              RadialBarSeries<ChartData,
                                                  String>(
                                                dataSource: chartData,
                                                xValueMapper:
                                                    (ChartData data, _) =>
                                                        data.category,
                                                yValueMapper:
                                                    (ChartData data, _) =>
                                                        data.value,
                                                trackColor: HexColor("#457b9d"),
                                                pointColorMapper:
                                                    (ChartData data, _) {
                                                  switch (data.category) {
                                                    case 'Category A':
                                                      return HexColor(
                                                          "#fb8500");
                                                    case 'Category B':
                                                      return HexColor(
                                                          "#e63946");
                                                    default:
                                                      return Colors.grey;
                                                  }
                                                },
                                                radius: '80%',
                                                innerRadius: '40%',
                                                cornerStyle:
                                                    CornerStyle.bothCurve,
                                              )
                                            ],
                                          ))
                                      : Padding(
                                          padding: EdgeInsets.only(left: 20.w),
                                          child: Container(
                                            width: 100.w,
                                            height: 100.h,
                                            decoration: BoxDecoration(
                                                color: HexColor("#BAA898"),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        100.r)),
                                            child: Center(
                                              child: UiHelper.customText(
                                                  text: "Not Ack",
                                                  color: Appcolors.secondary,
                                                  fontsize: 14.sp,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'bold'),
                                            ),
                                          ),
                                        ))
                              : const SizedBox()
                        ],
                      ),
                      Container(
                          width: 400.w,
                          height: 28.h,
                          margin: EdgeInsets.only(top: 0.h),
                          child: Center(
                              child: InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () {},
                            child: Container(
                              width: 160.w,
                              height: 30.h,
                              decoration: BoxDecoration(
                                  color: HexColor("#457b9d"),
                                  borderRadius: BorderRadius.circular(12.r)),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  InkWell(
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () {
                                      widget.onShowAlertsDetails();
                                    },
                                    child: UiHelper.customText(
                                        text: "Show More Details",
                                        color: Appcolors.secondary,
                                        fontsize: 13.sp,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  Icon(
                                    Icons.send,
                                    color: Appcolors.secondary,
                                    size: 16.r,
                                  )
                                ],
                              ),
                            ),
                          )))
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                      color: Appcolors.backGroundColor,
                      borderRadius: BorderRadius.circular(13.r)),
                  child: Center(
                    child: UiHelper.customText(
                        text: "No alerts found.",
                        color: Appcolors.secondary,
                        fontsize: 18.sp,
                        fontWeight: FontWeight.w700),
                  ),
                )),
    );
  }
}

class ChartData {
  ChartData(this.category, this.value);
  final String category;
  final double value;
}
