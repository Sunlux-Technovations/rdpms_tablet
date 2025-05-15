import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:rdpms_tablet/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';

class AnalyticsAccordian extends StatefulWidget {
  final List<dynamic>? analyticsList;
  final bool? lazyLoading;
  const AnalyticsAccordian({super.key, this.analyticsList, this.lazyLoading});

  @override
  State<AnalyticsAccordian> createState() => AnalyticsAccordianState();
}

class AnalyticsAccordianState extends State<AnalyticsAccordian> {
  List<dynamic> get rows => (widget.analyticsList?.isNotEmpty ?? false)
      ? widget.analyticsList![0]
      : [];

  Widget cell(
    String txt, {
    double? width,
    bool header = false,
    TextAlign align = TextAlign.center,
  }) {
    return SizedBox(
      width: width ?? 65.w,
      child: Text(
        txt,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: TextStyle(
          color: Appcolors.primary,
          fontSize: 12.sp,
          fontWeight: header ? FontWeight.w700 : FontWeight.w600,
          fontFamily: header ? 'bold' : 'regular',
        ),
      ),
    );
  }

  Widget tableHeader() => SizedBox(
        width: double.infinity,
        height: 45.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            cell('Device', header: true),
            cell('Type', header: true),
            cell('Average', header: true),
            cell('Variance', header: true),
            cell('Standard\nDeviation',
                width: 75.w, header: true, align: TextAlign.center),
          ],
        ),
      );

  Widget tableBody() => Expanded(
        child: rows.isEmpty
            ? Center(
                child: UiHelper.customText(
                  text: 'No analytics data available',
                  color: Colors.grey,
                  fontsize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: rows.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (_, i) {
                  final r = rows[i];
                  return SizedBox(
                    height: 33.h,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        cell(r['Tag ID'].toString()),
                        cell(r['Sensor Type'].toString()),
                        cell(r['Average Value'].toString()),
                        cell(r['Variance'].toString()),
                        cell(r['Standard Deviation'].toString()),
                      ],
                    ),
                  );
                },
              ),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.lazyLoading == true) {
      return Center(
        child: LoadingAnimationWidget.stretchedDots(
          color: Appcolors.backGroundColor,
          size: 50.r,
        ),
      );
    }

    return Column(
      children: [
        tableHeader(),
        SizedBox(height: 5.h),
        tableBody(),
      ],
    );
  }
}
