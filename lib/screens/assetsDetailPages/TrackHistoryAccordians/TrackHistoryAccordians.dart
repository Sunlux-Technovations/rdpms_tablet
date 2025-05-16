import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:rdpms_tablet/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';

class TrackHistoryAccordians extends StatefulWidget {
  final List<dynamic>? maintenanceList;
  final bool? lazyLoading;
  const TrackHistoryAccordians({
    super.key,
    this.maintenanceList,
    this.lazyLoading,
  });

  @override
  State<TrackHistoryAccordians> createState() => TrackHistoryAccordiansState();
}

class TrackHistoryAccordiansState extends State<TrackHistoryAccordians> {
  
  List<dynamic> get history =>
      (widget.maintenanceList?.isNotEmpty ?? false)
          ? (widget.maintenanceList![0]['history'] ?? [])
          : [];

  
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

  
  Widget dateTimeCell(String raw, {int flex = 2}) {
    final parts = raw.contains('T') ? raw.split('T') : raw.split(' ');
    final date = parts[0];
    final time =
        parts.length > 1 ? parts[1].replaceAll('Z', '').split('.').first : '';
    return Expanded(
      flex: flex,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          UiHelper.customText(
            text: date,
            color: Appcolors.primary,
            fontsize: 11.sp,
            fontWeight: FontWeight.w700,
          ),
          UiHelper.customText(
            text: time,
            color: Appcolors.primary,
            fontsize: 11.sp,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }

  
  Widget tableHeader() => Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            cell('Device', header: true, flex: 1),
            cell('Control', header: true),
            cell('Date & Time', header: true, flex: 1),
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
                    height: 44.h,
                    child: Row(
                      children: [
                        cell(item['tagid'].toString(), flex: 1),
                        cell(item['control_type'].toString()),
                        dateTimeCell(item['datetime'].toString(), flex: 1),
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
