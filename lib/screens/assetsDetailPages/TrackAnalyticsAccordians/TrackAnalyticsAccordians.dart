import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:rdpms_tablet/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';

class TrackAnalyticsAccordians extends StatefulWidget {
  final List<dynamic>? analyticsList;
  final bool? lazyLoading;
  const TrackAnalyticsAccordians({
    super.key,
    this.analyticsList,
    this.lazyLoading,
  });

  @override
  State<TrackAnalyticsAccordians> createState() =>
      TrackAnalyticsAccordiansState();
}

class TrackAnalyticsAccordiansState extends State<TrackAnalyticsAccordians> {
  
  List<dynamic> get rows =>
      (widget.analyticsList?.isNotEmpty ?? false) ? widget.analyticsList![0] : [];

  
  Widget cell(
    String txt, {
    int flex = 1,
    bool header = false,
    TextAlign align = TextAlign.center,
  }) {
    return Expanded(
      flex: flex,
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
        height: 50.h,
        child: Row(
          children: [
            cell('Device', header: true, flex: 1),
            cell('Type', header: true),
            cell('Average', header: true),
            cell('Variance', header: true),
            cell('Standard\nDeviation', header: true, flex: 1),
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
                    height: 40.h,
                    child: Row(
                      children: [
                        cell(r['Tag ID'].toString(), flex: 1),
                        cell(r['Sensor Type'].toString()),
                        cell(r['Average Value'].toString()),
                        cell(r['Variance'].toString()),
                        cell(r['Standard Deviation'].toString(), flex: 1),
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
