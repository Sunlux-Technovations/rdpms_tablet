import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';

import 'package:rdpms_tablet/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Pointalertsaccordian extends StatefulWidget {
  final List<dynamic> maintenanceList;
  final VoidCallback onShowAlertDetails;

  const Pointalertsaccordian({
    super.key,
    required this.maintenanceList,
    required this.onShowAlertDetails,
  });

  @override
  State<Pointalertsaccordian> createState() => _PointalertsaccordianState();
}

class _PointalertsaccordianState extends State<Pointalertsaccordian> {
  bool alertVisible = false;
  int totalRespTime = 0;
  int totalAckTime = 0;

  @override
  Widget build(BuildContext context) {
    
    final List<dynamic> alerts = widget.maintenanceList.isNotEmpty
        ? (widget.maintenanceList[0]['alerts'] as List<dynamic>? ?? [])
        : [];

    
    if (alerts.isNotEmpty) {
      final first = alerts[0];
      alertVisible = first['acknowledged'] == 1;

      final DateTime alertTime =
          DateTime.parse(first['alert_time'] as String);
      final DateTime respTime = first['response_time'] != null
          ? DateTime.parse(first['response_time'] as String)
          : DateTime.now();
      final DateTime ackTime = first['acknowledged_time'] != null
          ? DateTime.parse(first['acknowledged_time'] as String)
          : DateTime.now();

      totalRespTime = respTime.difference(alertTime).inHours;
      totalAckTime = ackTime.difference(alertTime).inHours;
    }

    final List<ChartData> chartData = [
      ChartData('Response', totalRespTime.toDouble()),
      ChartData('Acknowledge', totalAckTime.toDouble()),
    ];

    return Scaffold(
      body: alerts.isNotEmpty
          ? Container(
              width: 380.w,
              height: 220.h,
              decoration: BoxDecoration(
                color: Appcolors.backGroundColor,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(
                children: [
                  
                  SizedBox(
                    width: 380.w,
                    height: 35.h,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        
                        Padding(
                          padding: EdgeInsets.only(left: 15.w, top: 9.h),
                          child: UiHelper.customText(
                            text: alerts.isNotEmpty
                                ? alerts[0]['tagid'].toString()
                                : "No Data Found",
                            color: Appcolors.secondary,
                            fontsize: 13.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'bold',
                          ),
                        ),
                        
                        Card(
                          elevation: 4.r,
                          child: Container(
                            width: 90.w,
                            height: 30.h,
                            decoration: BoxDecoration(
                              color: alerts[0]['alerttype'] == "Warning"
                                  ? Colors.amber
                                  : Colors.red,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            alignment: Alignment.center,
                            child: UiHelper.customText(
                              text: alerts[0]['alerttype'].toString(),
                              color: Appcolors.secondary,
                              fontsize: 13.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'bold',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  
                  Row(
                    children: [
                      
                      SizedBox(
                        width: 200.w,
                        height: 124.h,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            
                            buildTimeRow(
                              label: "Alert Time",
                              value: DateFormat('yyyy-MM-dd HH:mm')
                                  .format(DateTime.parse(
                                      alerts[0]['alert_time'] as String)),
                            ),

                            
                            alertVisible
                                ? Column(
                                    children: [
                                      buildTimeRow(
                                        label: "Acknowledge Time",
                                        value: alerts[0]
                                                    ['acknowledged_time'] !=
                                                null
                                            ? DateFormat('yyyy-MM-dd HH:mm')
                                                .format(DateTime.parse(
                                                    alerts[0]
                                                        ['acknowledged_time']
                                                    as String))
                                            : "Not Acknowledged",
                                      ),
                                      buildTimeRow(
                                        label: "Resolved Time",
                                        value: alerts[0]['response_time'] !=
                                                null
                                            ? DateFormat('yyyy-MM-dd HH:mm')
                                                .format(DateTime.parse(
                                                    alerts[0]
                                                        ['response_time']
                                                    as String))
                                            : "",
                                      ),
                                    ],
                                  )
                                : Card(
                                    elevation: 7.r,
                                    child: Container(
                                      width: 200.w,
                                      height: 22.h,
                                      decoration: BoxDecoration(
                                        color: HexColor("#457b9d"),
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                      ),
                                      alignment: Alignment.center,
                                      child: UiHelper.customText(
                                        text: "Alert Not Acknowledged",
                                        color: Appcolors.secondary,
                                        fontsize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'bold',
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),

                      
                      Expanded(
                        child: alerts[0]['acknowledged_time'] != null ||
                                alerts[0]['response_time'] != null
                            ? SfCircularChart(
                                series: <CircularSeries>[
                                  RadialBarSeries<ChartData, String>(
                                    dataSource: chartData,
                                    xValueMapper: (d, _) => d.category,
                                    yValueMapper: (d, _) => d.value,
                                    trackColor: HexColor("#457b9d"),
                                    pointColorMapper: (d, _) {
                                      switch (d.category) {
                                        case 'Response':
                                          return HexColor("#fb8500");
                                        case 'Acknowledge':
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
                              )
                            : Padding(
                                padding: EdgeInsets.only(left: 20.w),
                                child: Container(
                                  width: 100.w,
                                  height: 100.h,
                                  decoration: BoxDecoration(
                                    color: HexColor("#BAA898"),
                                    borderRadius:
                                        BorderRadius.circular(100.r),
                                  ),
                                  alignment: Alignment.center,
                                  child: UiHelper.customText(
                                    text: "Not Ack",
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

                  
                  SizedBox(
                    width: 400.w,
                    height: 28.h,
                    child: Center(
                      child: InkWell(
                        onTap: widget.onShowAlertDetails,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
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
                  ),
                ],
              ),
            )
          : 
          Container(
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
    );
  }

  
  Widget buildTimeRow({required String label, required String value}) {
    return SizedBox(
      width: 200.w,
      height: 40.h,
      child: Padding(
        padding: EdgeInsets.only(left: 12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UiHelper.customText(
              text: label,
              color: Appcolors.secondary,
              fontsize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
            UiHelper.customText(
              text: value,
              color: Appcolors.secondary,
              fontsize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ],
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
