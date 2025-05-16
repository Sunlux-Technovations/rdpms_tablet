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
  // -------- helpers --------
  List<dynamic> get history => (widget.maintenanceList?.isNotEmpty ?? false)
      ? (widget.maintenanceList![0]['history'] ?? [])
      : [];

  /// flexible text cell
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

  /// date + time stacked in one column
  Widget dateTimeCell(String raw, {int flex = 2}) {
    final parts = raw.contains('T') ? raw.split('T') : raw.split(' ');
    final date = parts[0];
    final time =
        parts.length > 1 ? parts[1].replaceAll('Z', '').split('.').first : '';
    return Expanded(
      flex: flex,
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

  // -------- build --------
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
          height: 45.h,
          child: Row(
            children: [
              cell('Device', header: true, flex: 1),
              cell('Control', header: true),
              cell('Date & Time', header: true, flex: 1),
              cell('Value', header: true),
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
                    return SizedBox(
                      height: 44.h,
                      child: Row(
                        children: [
                          cell(item['tagid'], flex: 1),
                          cell(item['control_type']),
                          dateTimeCell(item['datetime'], flex: 1),
                          cell(item['val'].toString()),
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
