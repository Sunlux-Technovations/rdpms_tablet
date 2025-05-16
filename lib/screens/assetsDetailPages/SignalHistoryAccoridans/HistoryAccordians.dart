import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:rdpms_tablet/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';

class HistoryAccordians extends StatefulWidget {
  final List<dynamic>? maintenanceList;
  final bool? lazyLoading;

  const HistoryAccordians({
    super.key,
    this.maintenanceList,
    this.lazyLoading,
  });

  @override
  HistoryAccordiansState createState() => HistoryAccordiansState();
}

class HistoryAccordiansState extends State<HistoryAccordians> {
  List<dynamic> get history => (widget.maintenanceList?.isNotEmpty ?? false)
      ? (widget.maintenanceList![0]['history'] ?? [])
      : [];

  Widget tableCell(String txt, {double? width, bool header = false}) {
    return SizedBox(
      width: width ?? 70.w,
      child: Center(
        child: header
            ? UiHelper.xsmalltxt_bold(text: txt)
            : UiHelper.xsmalltxt(text: txt),
      ),
    );
  }

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
            fontsize: 10.sp,
            fontWeight: FontWeight.w700,
          ),
          UiHelper.customText(
            text: time,
            color: Appcolors.primary,
            fontsize: 10.sp,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }

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
        SizedBox(
          width: double.infinity,
          height: 45.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              tableCell('Device', header: true),
              tableCell('Control', header: true),
              tableCell('Date & Time', width: 90.w, header: true),
              tableCell('Value', header: true),
            ],
          ),
        ),
        Expanded(
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
                    return Container(
                   padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          tableCell(item['tagid']),
                          tableCell(item['control_type']),
                          dateTimeCell(item['datetime']),
                          tableCell(item['val'].toString()),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
