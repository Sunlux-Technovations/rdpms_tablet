import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:rdpms_tablet/Apis/Urls.dart';
import 'package:rdpms_tablet/Apis/dioInstance.dart';
import 'package:rdpms_tablet/main.dart';
import 'package:rdpms_tablet/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Homepage extends StatefulWidget {
  final bool alertUpdates;
  const Homepage({super.key, required this.alertUpdates});

  @override
  State<Homepage> createState() => _HomepageState();
}

class PieChartData {
  PieChartData(this.category, this.value, [this.color]);
  final String category;
  final int value;
  final Color? color;
}

class _HomepageState extends State<Homepage> {
  bool renderCompleteState = false;
  final bool hasError = false;
  Map<String, dynamic> totalAlertCounts = {};
  Map<String, dynamic> alertsChartCount = {};
  int activeSensors = 0;
  String avgRespTime = "00m 00s";
  final checkMarkStyle = CheckMarkStyle(
    loading: const CheckMarkColors(content: Colors.white, background: Colors.blueAccent),
    success: CheckMarkColors(content: Appcolors.primary, background: Colors.greenAccent),
    error: CheckMarkColors(content: Appcolors.primary, background: Colors.redAccent),
  );

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void didUpdateWidget(covariant Homepage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.alertUpdates) fetchData();
  }

  Future<void> fetchData() async {
    await Future.wait([
      getAlaramData(),
      getAlertsCount(),
      getAlertsChartsCount(),
    ]);
  }

  Future<void> getAlaramData() async {
    try {
      await dioInstance.get("$getAlaramReport?username=admin");
    } catch (_) {}
  }

  Future<void> getAlertsCount() async {
    try {
      final alertsResponse = await dioInstance.get(getAlertCountForDashboard);
      setState(() => totalAlertCounts = alertsResponse);
    } catch (_) {}
  }

  Future<void> getAlertsChartsCount() async {
    final username = GlobalData().userName;
    final url = "$getAlertsCharts?username=$username";
    try {
      final response = await dioInstance.get(url);
      setState(() {
        alertsChartCount = response;
        activeSensors = int.tryParse(
              alertsChartCount['activeSensorRes']?[0]['count']?.toString() ?? '0',
            ) ??
            0;
        avgRespTime = formatAvgRespTime(
          alertsChartCount['avgRespRes']?[0]['avg_resp_duration']?.toString().trim() ?? "--",
        );
      });
    } catch (_) {}
  }

  Future<void> _onRefresh() async {
    try {
      setState(() {
        totalAlertCounts = {};
        alertsChartCount = {};
        activeSensors = 0;
        avgRespTime = "00m 00s";
      });
      await fetchData();
    } catch (_) {
      MotionToast.error(
        width: 300.w,
        height: 50.h,
        description: Text(
          "Failed to refresh data.",
          style: TextStyle(fontFamily: "bold", fontSize: 14.sp),
        ),
        position: MotionToastPosition.top,
      ).show(context);
    }
  }

  String formatAvgRespTime(String avgRespTime) {
    final parts = avgRespTime.split(':');
    if (parts.length == 3) {
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final s = double.parse(parts[2]).floor();
      return h > 0 ? '${h}h ${m}m' : '${m}m ${s}s';
    }
    return avgRespTime;
  }

  List<PieChartData> buildStatusPieData() {
    final data = <PieChartData>[];
    if (alertsChartCount['alertByStatus'] != null &&
        (alertsChartCount['alertByStatus'] as List).isNotEmpty) {
      data.addAll([
        PieChartData('New Alerts', alertsChartCount['alertByStatus'][0]['count'] ?? 0, HexColor("#9d0208")),
        PieChartData('Ack Alerts', alertsChartCount['alertByStatus'][1]['count'] ?? 0, HexColor("#ff7c00")),
        PieChartData('Resp Alert', alertsChartCount['alertByStatus'][2]['count'] ?? 0, HexColor("#2d6751")),
      ]);
    } else {
      data.add(PieChartData('No data found.', 0, HexColor("#2d6751")));
    }
    return data;
  }

  List<PieChartData> buildCategoryPieData() {
    final data = <PieChartData>[];
    if (alertsChartCount['alertByCategory'] != null &&
        (alertsChartCount['alertByCategory'] as List).length >= 2) {
      data.addAll([
        PieChartData('Critical', int.tryParse(alertsChartCount['alertByCategory'][0]['count'].toString()) ?? 0, HexColor("#9d0208")),
        PieChartData('Warning', int.tryParse(alertsChartCount['alertByCategory'][1]['count'].toString()) ?? 0, HexColor("#ff7c00")),
        PieChartData('Normal', 5, HexColor("#2d6751")),
      ]);
    } else {
      data.add(PieChartData('No data found.', 0, HexColor("#ff7c00")));
    }
    return data;
  }

  Map<String, dynamic>? getDeviceData(String device) {
    if (totalAlertCounts.isNotEmpty && totalAlertCounts['allCountAlerts'] is List) {
      return (totalAlertCounts['allCountAlerts'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((el) => el['device'] == device, orElse: () => {});
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final statusPieData = buildStatusPieData();
    final categoryPieData = buildCategoryPieData();
    final hasStatusData = statusPieData.any((d) => d.value > 0);
    final hasCategoryData = categoryPieData.any((d) => d.value > 0);
    final signalCounts = getDeviceData('Signal');
    final pointCounts = getDeviceData('Pointmachine');
    final trackCounts = getDeviceData('Track');

    return Scaffold(
      body: CustomRefreshIndicator(
        onRefresh: _onRefresh,
        triggerMode: IndicatorTriggerMode.anywhere,
        durations: const RefreshIndicatorDurations(completeDuration: Duration(seconds: 1)),
        onStateChanged: (change) {
          if (change.didChange(to: IndicatorState.complete)) {
            renderCompleteState = true;
          } else if (change.didChange(to: IndicatorState.idle)) {
            renderCompleteState = false;
          }
        },
        builder: (context, child, controller) {
          final style = renderCompleteState
              ? (hasError ? checkMarkStyle.error : checkMarkStyle.success)
              : checkMarkStyle.loading;
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) => Transform.translate(offset: Offset(0, controller.value * 100), child: child),
              ),
              AnimatedBuilder(
                animation: controller,
                builder: (context, _) => Opacity(
                  opacity: controller.isLoading ? 1.0 : controller.value.clamp(0.0, 1.0),
                  child: Container(
                    height: 80.h,
                    alignment: Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(color: style.background, shape: BoxShape.circle),
                      child: Center(
                        child: renderCompleteState
                            ? Icon(hasError ? Icons.close : Icons.check, color: style.content, size: 24.r)
                            : SizedBox(
                                height: 24.h,
                                width: 24.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: style.content,
                                  value: (controller.isDragging || controller.isArmed) ? controller.value.clamp(0.0, 1.0) : null,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              children: [
                SizedBox(height: 10.h),
                InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: fetchData,
                  child: UiHelper.customHeadings(text: "Dashboard"),
                ),
                SizedBox(height: 16.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          SizedBox(height: 70.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: firstThreeCard(title: "Total Alerts", value: totalAlertCounts['totalAlerts']?.toString() ?? "0")),
                              SizedBox(width: 16.w),
                              Expanded(child: firstThreeCard(title: "Active Sensors", value: activeSensors.toString())),
                              SizedBox(width: 16.w),
                              Expanded(child: firstThreeCard(title: "Avg Resp Time", value: avgRespTime, valueFontSize: 22.sp, gapBetweenValueAndTitle: 14.h, isTime: true)),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: DeviceCard(title: "Signal", svgAsset: "assets/images/trafficlights.svg", counts: signalCounts)),
                              SizedBox(width: 16.w),
                              Expanded(child: DeviceCard(title: "PointMachine", svgAsset: "assets/images/sensor (2).svg", counts: pointCounts)),
                              SizedBox(width: 16.w),
                              Expanded(child: DeviceCard(title: "Track", svgAsset: "assets/images/switch.svg", counts: trackCounts)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          AspectRatio(aspectRatio: 1, child: PieChartCard(title: "Alerts By Status", data: statusPieData, hasData: hasStatusData)),
                          SizedBox(height: 16.h),
                          AspectRatio(aspectRatio: 1, child: PieChartCard(title: "Alerts By Category", data: categoryPieData, hasData: hasCategoryData)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget firstThreeCard({
    required String title,
    required String value,
    double valueFontSize = 35,
    double gapBetweenValueAndTitle = 0,
    bool isTime = false,
  }) =>
    SizedBox(
      width: 150.w,
      height: 150.h,
      child: Card(
        elevation: 4.r,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isTime) UiHelper.timenum(number: value) else UiHelper.bigNumber(number: value),
            SizedBox(height: gapBetweenValueAndTitle),
            UiHelper.smallText(text: title, color: Appcolors.primary),
          ],
        ),
      ),
    );
}

class DeviceCard extends StatelessWidget {
  final String title;
  final String svgAsset;
  final Map? counts;

  const DeviceCard({super.key, required this.title, required this.svgAsset, required this.counts});

  @override
  Widget build(BuildContext context) => Card(
    elevation: 4.r,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    child: SizedBox(
      width: 150.w,
      height: 310.h,
      child: Column(
        children: [
          SizedBox(height: 10.h),
          Padding(padding: EdgeInsets.all(8.r), child: SvgPicture.asset(svgAsset, width: 80.w)),
          SizedBox(height: 15.h),
          UiHelper.smallText_bold(text: title),
          SizedBox(height: 12.h),
          buildRow("Active", counts?['alert_status']?['live']),
          buildRow("Acknowledged", counts?['alert_status']?['acknowledged']),
          buildRow("Resolved", counts?['alert_status']?['resolved']),
        ],
      ),
    ),
  );

  Widget buildRow(String label, dynamic value) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        UiHelper.xxsmalltxt_bold(text: label),
        UiHelper.xxsmallnum_bold(number: value?.toString() ?? "0"),
      ],
    ),
  );
}

class PieChartCard extends StatelessWidget {
  final String title;
  final List<PieChartData> data;
  final bool hasData;

  const PieChartCard({super.key, required this.title, required this.data, required this.hasData});

  @override
  Widget build(BuildContext context) => Card(
    elevation: 4.r,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontFamily: "bold", fontSize: 18.sp, fontWeight: FontWeight.w300)),
          SizedBox(height: 8.h),
          Expanded(
            child: hasData
                ? SfCircularChart(
                    legend: const Legend(isVisible: true),
                    series: <CircularSeries>[
                      PieSeries<PieChartData, String>(
                        dataSource: data,
                        xValueMapper: (d, _) => d.category,
                        yValueMapper: (d, _) => d.value,
                        pointColorMapper: (d, _) => d.color,
                        dataLabelSettings: DataLabelSettings(
                          isVisible: true,
                          labelPosition: ChartDataLabelPosition.outside,
                          textStyle: TextStyle(fontSize: 12.sp, color: Appcolors.primary, fontWeight: FontWeight.w600),
                        ),
                      )
                    ],
                  )
                : Center(child: UiHelper.NDF(text: "No alerts available.")),
          ),
        ],
      ),
    ),
  );
}

class CheckMarkColors {
  final Color content;
  final Color background;
  const CheckMarkColors({required this.content, required this.background});
}

class CheckMarkStyle {
  final CheckMarkColors loading;
  final CheckMarkColors success;
  final CheckMarkColors error;
  const CheckMarkStyle({required this.loading, required this.success, required this.error});
}
