import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:rdpms_tablet/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';

class TrackHistoryAccordians extends StatefulWidget {
  final List<dynamic>? maintenanceList;
  final bool? lazyLoading;
  const TrackHistoryAccordians(
      {super.key, this.maintenanceList, this.lazyLoading});

  @override
  State<TrackHistoryAccordians> createState() => TrackHistoryAccordiansState();
}

class TrackHistoryAccordiansState extends State<TrackHistoryAccordians> {
  List<dynamic> get history => (widget.maintenanceList?.isNotEmpty ?? false)
      ? (widget.maintenanceList![0]['history'] ?? [])
      : [];

  Widget cell(String txt, {double? width, bool header = false}) => SizedBox(
        width: width ?? 70.w,
        child: Center(
          child: UiHelper.customText(
            text: txt,
            color: Appcolors.primary,
            fontsize: 12.sp,
            fontWeight: header ? FontWeight.w700 : FontWeight.w600,
            fontFamily: header ? 'bold' : 'regular',
          ),
        ),
      );

  Widget dateTimeCell(String raw, {double width = 80}) {
    final parts = raw.contains('T') ? raw.split('T') : raw.split(' ');
    final date = parts[0];
    final time =
        parts.length > 1 ? parts[1].replaceAll('Z', '').split('.').first : '';
    return SizedBox(
      width: width.w,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UiHelper.customText(
              text: date,
              color: Appcolors.primary,
              fontsize: 11.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'regular'),
          UiHelper.customText(
              text: time,
              color: Appcolors.primary,
              fontsize: 11.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'regular'),
        ],
      ),
    );
  }

  Widget tableHeader() => SizedBox(
        width: double.infinity,
        height: 50.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            cell('Device', header: true),
            cell('Control', header: true),
            cell('Date & Time', width: 90.w, header: true),
            cell('Value', header: true),
          ],
        ),
      );

  Widget tableBody() => Expanded(
        child: history.isEmpty
            ? Center(
                child: UiHelper.customText(
                  text: 'No history data available',
                  color: Colors.grey,
                  fontsize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: history.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (_, i) {
                  final item = history[i];
                  return SizedBox(
                    height: 48.h,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        cell(item['tagid']),
                        cell(item['control_type']),
                        dateTimeCell(item['datetime']),
                        cell(item['val'].toString()),
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
        tableBody(),
      ],
    );
  }
}
