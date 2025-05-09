import 'dart:async';
import 'dart:convert';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:motion_toast/motion_toast.dart';

import 'package:rdpms_tablet/Apis/Urls.dart';
import 'package:rdpms_tablet/Apis/dioInstance.dart';
import 'package:rdpms_tablet/main.dart';
import 'package:rdpms_tablet/screens/AlertsPage/settings.dart';
import 'package:rdpms_tablet/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';
import 'package:snapping_sheet/snapping_sheet.dart';

import 'package:syncfusion_flutter_charts/charts.dart';

class AlertsHistory extends StatefulWidget {
  final VoidCallback onGoToSettings;
  const AlertsHistory({super.key, required this.onGoToSettings});

  @override
  State<AlertsHistory> createState() => AlertsHistoryState();
}

class AlertsHistoryState extends State<AlertsHistory> {
  String? selectedValues, selectedAssets, selectedDevices, selectedDevice;
  bool isStationDataAvailable = false,
      isLoading = false,
      positive = false,
      isDataAvilable = true;
  List<dynamic> responseData = [];
  List<dynamic> filteredData = [];
  List ackData = [];
  List<dynamic> alertHistoryData = [];
  List<String> stationList = [];
  List<String> assetsList = [];
  List<String> devicesList = [];
  List<dynamic> alertHistoryDataForSearch = [];
  Map<String, dynamic> alertStationData = {};
  Map<String, dynamic> jsonData = {};
  late List<_ChartData> chartData = [], barData;
  final TextEditingController alertSearchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final SnappingSheetController sheetController = SnappingSheetController();
  double currentSheetFactor = 0.37;
  double? oldHeight;
  bool _isFetchingMore = false;
  int displayedItemCount = 10;
  bool renderCompleteState = false, hasError = false;
  bool visiblesetting = false;

  final checkMarkStyle = CheckMarkStyle(
    loading: CheckMarkColors(
        content: Appcolors.secondary, background: Colors.blueAccent),
    success: CheckMarkColors(
        content: Appcolors.primary, background: Colors.greenAccent),
    error: CheckMarkColors(
        content: Appcolors.primary, background: Colors.redAccent),
  );

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListener);
    initializeData();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      loadMore();
    }
  }

  Future<void> initializeData() async {
    await Future.wait([
      getAlertsOnly(),
      getStationOnly(),
      getAlertsHistory(),
      getAlertsForDashboard(),
      loadJsonData(),
      showAcknowledgeAlert(),
    ]);
    setState(() {
      barData = [
        _ChartData('Track', 30),
        _ChartData('PM', 45),
        _ChartData('Signal', 60),
      ];
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newHeight = MediaQuery.of(context).size.height;
    if (oldHeight != null && (oldHeight! - newHeight).abs() > 0.5) {
      sheetController.snapToPosition(
        const SnappingPosition.factor(
          positionFactor: 0.37,
          snappingCurve: Curves.linear,
          snappingDuration: Duration(milliseconds: 200),
        ),
      );
    }
    oldHeight = newHeight;
  }

  @override
  void dispose() {
    scrollController.dispose();
    alertSearchController.dispose();
    super.dispose();
  }

  void resetDropdowns() {
    if (!mounted) return;
    setState(() {
      selectedValues = null;
      selectedAssets = null;
      selectedDevices = null;
    });
  }

  Future<void> onRefresh() async {
    setState(() {
      isLoading = true;

      selectedValues = null;
      selectedAssets = null;
      selectedDevices = null;
      isDataAvilable = true;

      responseData.clear();
      filteredData.clear();
      alertHistoryData.clear();
      ackData.clear();
      alertSearchController.clear();
      positive = false;
    });
    try {
      await Future.wait([
        getStationOnly(),
        sendingStationValue(selectedValues ?? ''),
        getAlertsOnly(),
        getAlertsForDashboard(),
        getAlertsHistory(),
      ]);
      sheetController.snapToPosition(
        const SnappingPosition.factor(
          positionFactor: 0.37,
          snappingCurve: Curves.linear,
          snappingDuration: Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      MotionToast.error(
        width: 300.w,
        height: 50.h,
        description: Text("Failed to refresh data",
            style: TextStyle(
              fontFamily: "bold",
              fontSize: 14.sp,
            )),
        position: MotionToastPosition.top,
      ).show(context);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  double get backgroundOpacity {
    const double minSheet = 0.33;
    const double maxSheet = 0.45;
    double normalized =
        ((currentSheetFactor - minSheet) / (maxSheet - minSheet))
            .clamp(0.0, 0.50);
    return (1 - normalized);
  }

  Future getAlertsForDashboard() async {
    try {
      var alerts = await dioInstance.get(alertDashboard);
      setState(() {
        alertStationData = alerts;
      });
    } catch (e) {
      print("Error fetching dashboard alerts: $e");
    }
  }

  int parseTimePart(String value) => double.tryParse(value)?.toInt() ?? 0;

  String formatDuration(String duration) {
    if (duration.contains(':')) {
      List<String> parts = duration.split(':');
      if (parts.length >= 3) {
        int hours = parseTimePart(parts[0]);
        int minutes = parseTimePart(parts[1]);
        int seconds = parseTimePart(parts[2]);
        return hours == 0
            ? "${minutes}M ${seconds}S"
            : "${hours}H ${minutes}M ${seconds}S";
      }
    }
    return "00H 00M 00S";
  }

  String getAverageResponseDuration() {
    final avgRespRes = alertStationData["avgRespRes"];
    if (avgRespRes is List && avgRespRes.isNotEmpty) {
      String? duration = avgRespRes[0]["avg_resp_duration"];
      if (duration != null) return formatDuration(duration);
    }
    return "00H 00M 00S";
  }

  String getAverageAckDuration() {
    final avgAckRes = alertStationData["avgAckRes"];
    if (avgAckRes is List && avgAckRes.isNotEmpty) {
      String? duration = avgAckRes[0]["avg_ack_duration"];
      if (duration != null) return formatDuration(duration);
    }
    return "00H 00M 00S";
  }

  Color alertColor(String? alertType) {
    if (alertType == 'Major') return Colors.orange;
    if (alertType == 'Minor') return Colors.yellow;
    return Colors.red;
  }

  void sortAlerts(String filter) {
    setState(() {
      List<dynamic> sortedData = List.from(filteredData);
      switch (filter) {
        case 'Oldest To Newest':
          sortedData.sort((older, newer) =>
              (older['alert_time'] ?? '').compareTo(newer['alert_time'] ?? ''));
          break;
        case 'Newest To Oldest':
          sortedData.sort((older, newer) =>
              (newer['alert_time'] ?? '').compareTo(older['alert_time'] ?? ''));
          break;
        case 'Task Name : A-Z':
          sortedData.sort(
              (firstTask, nextTask) => (firstTask['message'] ?? '').compareTo(nextTask['message'] ?? ''));
          break;
        case 'Task Name : Z-A':
          sortedData.sort(
              (firstTask, nextTask) => (nextTask['message'] ?? '').compareTo(firstTask['message'] ?? ''));
          break;
      }
      filteredData = sortedData;
    });
  }

  Future<void> showAcknowledgeAlert() async {
      final String username = GlobalData().userName;
  final String url      = '$showAckAlert?username=$username';
    try {

      final response =
          await dioInstance.get(url);
      if (response is List && response.isNotEmpty) {
        setState(() {
          ackData = List<Map<String, dynamic>>.from(response);
        });
        print("Ack data updated with ${ackData.length} acknowledged alerts.");
      } else {
        print("No acknowledged alerts found.");
      }
    } catch (e) {
      print("No acknowledge alerts error: $e");
    }
  }

  Future loadJsonData() async {
    String jsonString = await rootBundle.loadString('assets/instruction.json');
    setState(() {
      jsonData = jsonDecode(jsonString);
    });
  }

  Future getAlertsOnly() async {
    try {
      final response = await dioInstance.get(getAlerts);
      setState(() {
        responseData = List.from(response.map((alert) {
          alert['acknowledged'] = (alert['acknowledged'] ?? 0) == 1;
          return alert;
        }));
        filteredData = List.from(
            responseData.where((alert) => alert['acknowledged'] != true));
      });
    } catch (e) {
      print("Error fetching alerts: $e");
    }
  }

  Future<bool> getAck(String alertId) async {
    try {
      final response = await dioInstance.post(getAckAlerts,
          {"alertid": alertId, 'username': GlobalData().userName});
      print(response);
      return true;
    } catch (e) {
      print("Error acknowledging alert: $e");
      return false;
    }
  }

  Future getAlertsHistory() async {
    setState(() {
      isLoading = true;
    });
    final String url=  "$getAlertHistory?station=${selectedValues ?? ''}&assets=${selectedAssets ?? ''}&tag_id=${selectedDevices ?? ''}";
    try {
      final response = await dioInstance.get(url);
        
      if (response != null && response.isNotEmpty) {
        response.forEach((alert) {
          alert['acknowledged'] =
              (alert['acknowledged'] == 1 || alert['acknowledged'] == "1");
        });
        List nonAcknowledged = [];
        List acknowledged = [];
        for (var alert in response) {
          if (alert['acknowledged'] == true) {
            acknowledged.add(alert);
          } else {
            nonAcknowledged.add(alert);
          }
        }
        setState(() {
          responseData = response;
          alertHistoryDataForSearch = nonAcknowledged
              .where((alert) => !ackData.any((ack) => ack['id'] == alert['id']))
              .toList();
          alertHistoryData = alertHistoryDataForSearch;
          ackData = acknowledged;
          filteredData =
              positive ? List.from(ackData) : List.from(alertHistoryData);
        });
      } else {
        setState(() {
          alertHistoryData.clear();
          ackData.clear();
          filteredData.clear();
        });
      }
    } catch (e) {
      print("Error fetching alert history: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future getStationOnly() async {
    try {
      final response = await dioInstance.get(getStationValues);
      setState(() {
        stationList = response != null ? List<String>.from(response) : [];
      });
    } catch (e) {
      print("Error fetching stations: $e");
    }
  }

  Future<void> sendingStationValue(String selectedStation) async {
    setState(() {
      isLoading = true;
      ackData.clear();
    });
    try {
      final response = await dioInstance
          .post(getMaintenanceByStationDetails, {'station': selectedStation});
      if (response != null) {
        List<String> assetLists = [];
        const values = ['Signal', 'Pointmachine', 'Track'];
        assetLists.addAll(
            values.where((key) => response[key]?.isNotEmpty ?? false).toList());
        isStationDataAvailable = assetLists.isNotEmpty;

        setState(() {
          assetsList = assetLists;
          selectedDevices = null;
          devicesList = [];
        });
        devicesList = selectedAssets != null
            ? List<String>.from(response[selectedAssets] ?? [])
            : [];
        selectedDevice = devicesList.contains(selectedDevice)
            ? selectedDevice
            : devicesList.isNotEmpty
                ? devicesList.first
                : null;
        await getAlertsHistory();
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void searchAlerts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredData = positive
            ? List.from(ackData)
            : (isDataAvilable
                ? List.from(responseData)
                : List.from(alertHistoryData));
      } else {
        final source = positive
            ? ackData
            : (isDataAvilable ? responseData : alertHistoryData);
        filteredData = source.where((alert) {
          return alert.entries.any((entry) {
            final value = entry.value?.toString().toLowerCase() ?? "";
            return value.contains(query.toLowerCase());
          });
        }).toList();
      }
    });
  }

  void loadMore() async {
    int totalCount = filteredData.length;
    if (displayedItemCount < totalCount && !_isFetchingMore) {
      setState(() {
        _isFetchingMore = true;
      });
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        displayedItemCount = (displayedItemCount + 10) > totalCount
            ? totalCount
            : displayedItemCount + 10;
        _isFetchingMore = false;
      });
    }
  }

  List<String> parseDateTime(String alertTime) {
    if (alertTime.contains(' ') || alertTime.contains('T')) {
      List<String> parts =
          alertTime.contains(' ') ? alertTime.split(' ') : alertTime.split('T');
      String date = parts.isNotEmpty ? parts[0] : "N/A";
      String time = parts.length > 1
          ? parts[1].replaceAll('Z', '').split('.').first
          : "N/A";
      return [date, time];
    }
    return ["N/A", "N/A"];
  }

  Future<void> showAllinfoDialog(
      BuildContext context, Map<String, dynamic> alertData) async {
    bool isAcknowledged = alertData['acknowledged'] == true;
    final String alertTime = (alertData['alert_time'] as String?) ?? "No Data";
    List<String> dateTime = parseDateTime(alertTime);
    List<String> ackDateTime = ["N/A", "N/A"];
    if (isAcknowledged && alertData['acknowledged_time'] != null) {
      ackDateTime = parseDateTime(alertData['acknowledged_time']);
    }
    final String alertMessage =
        (alertData['message'] as String?) ?? "No Message";

    Future<void> acknowledgeButton() async {
      if (!isAcknowledged) {
        final alertId = alertData['id']?.toString() ?? "";
        bool success = await getAck(alertId);
        if (success) {
          setState(() {
            isAcknowledged = true;
            if (isDataAvilable) {
              filteredData
                  .removeWhere((element) => element['id'] == alertData['id']);
            } else {
              alertHistoryData
                  .removeWhere((element) => element['id'] == alertData['id']);
            }
            final responseIndex =
                responseData.indexWhere((a) => a['id'] == alertData['id']);
            if (responseIndex != -1) {
              responseData[responseIndex]['acknowledged'] = true;
            }
            ackData.add(alertData);
          });
          Navigator.of(context).pop();
          MotionToast.success(
            width: 300.w,
            height: 50.h,
            description: Text("Notification Acknowledged",
                style: TextStyle(
                  fontFamily: "bold",
                  fontSize: 14.sp,
                )),
            position: MotionToastPosition.top,
          ).show(context);
        } else {
          MotionToast.error(
            width: 300.w,
            height: 50.h,
            description: Text("Failed to acknowledge alert. Please try again.",
                style: TextStyle(
                  fontFamily: "bold",
                  fontSize: 14.sp,
                )),
            position: MotionToastPosition.top,
          ).show(context);
        }
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0E4375),
              content: SingleChildScrollView(
                child: ListBody(
                  children: [
                    buildDialogHeader(alertData, isAcknowledged),
                    Divider(thickness: 1.h, color: Colors.grey.shade400),
                    buildDialogInfo(
                        dateTime, ackDateTime, isAcknowledged, alertData),
                    SizedBox(height: 10.h),
                    Divider(thickness: 1.h, color: Colors.grey.shade400),
                    Text(alertMessage,
                        style: TextStyle(fontSize: 12.sp, color: Colors.white)),
                    SizedBox(height: 10.h),
                    Divider(thickness: 1.h, color: Colors.grey.shade400),
                    SizedBox(
                      width: 320.w,
                      height: 45.h,
                      child: Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAcknowledged
                                ? Colors.grey.shade300
                                : Colors.yellow,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r)),
                          ),
                          onPressed: isAcknowledged ? null : acknowledgeButton,
                          child: Text(
                            isAcknowledged ? 'Acknowledged' : "Acknowledge",
                            style: TextStyle(
                                fontFamily: "bold",
                                fontSize: 14.sp,
                                color: isAcknowledged
                                    ? Colors.red
                                    : Appcolors.primary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildDialogHeader(
      Map<String, dynamic> alertData, bool isAcknowledged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        UiHelper.heading2(text: "Alerts", color: Appcolors.secondary),
        Row(
          children: [
            Material(
              elevation: 1.r,
              borderRadius: BorderRadius.circular(10.r),
              child: SizedBox(
                width: 105.w,
                height: 35.h,
                child: Container(
                  decoration: BoxDecoration(
                    color: alertColor(alertData['alerttype']),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: Text(alertData['alerttype']?.toString() ?? "",
                        style: TextStyle(
                            fontFamily: "bold",
                            fontSize: 17.sp,
                            color: Appcolors.primary)),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close, color: Appcolors.secondary, size: 30.r),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildDialogInfo(List<String> dateTime, List<String> ackDateTime,
      bool isAcknowledged, Map<String, dynamic> alertData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alertData['topic']?.toString().split('_').last ?? "N/A",
                style: TextStyle(
                    color: Appcolors.secondary,
                    fontFamily: "bold",
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: isAcknowledged ? 24.h : 8.h),
              Text(isAcknowledged ? "Acknowledged" : "Not Acknowledged",
                  style: TextStyle(
                      color: Appcolors.secondary,
                      fontFamily: "bold",
                      fontSize: 14.sp)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            UiHelper.xsmalltxt_bold(
              text: dateTime[0],
            ),
            SizedBox(height: 5.h),
            UiHelper.xsmalltxt_bold(
              text: dateTime[1],
            ),
            if (isAcknowledged && alertData['acknowledged_time'] != null)
              Padding(
                padding: EdgeInsets.only(top: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    UiHelper.xsmalltxt_bold(
                      text: ackDateTime[0],
                    ),
                    SizedBox(height: 5.h),
                    UiHelper.xsmalltxt_bold(
                      text: ackDateTime[1],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget buildDropdown(String? value, String hint, List<String> items,
      Function(String?) onChanged) {
    return SizedBox(
      width: 110.w,
      height: 90.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            hint == "Station"
                ? "assets/images/stations.svg"
                : hint == "Assets"
                    ? "assets/images/sensor (2).svg"
                    : "assets/images/chip.svg",
            width: 35.w,
          ),
          Expanded(
            flex: 2,
            child: DropdownButtonHideUnderline(
              child: DropdownButton2<String>(
                value: value,
                hint: Padding(
                  padding: EdgeInsets.only(left: 5.w),
                  child: Text(value ?? hint,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: "regular",
                        fontSize: 14.sp,
                        color: Appcolors.primary,
                      )),
                ),
                onChanged: onChanged,
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item ?? '',
                    child: Text(item,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.sp,
                            color: Appcolors.primary,
                            fontFamily: "bold")),
                  );
                }).toList(),
                buttonStyleData: ButtonStyleData(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    height: 60.h,
                    width: 200.w),
                dropdownStyleData: DropdownStyleData(
                    maxHeight: 200.h,
                    width: 140.w,
                    decoration: BoxDecoration(
                        color: hint == "Station"
                            ? const Color(0xFFFEF7FF)
                            : Appcolors.secondary,
                        borderRadius: BorderRadius.circular(10.r)),
                    elevation: 12),
                isExpanded: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchSortRow(double screenHeight) {
    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      alignment: Alignment.center,
      child: Row(
        children: [
          Expanded(
            child: Container(
              width: 160.w,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Appcolors.primary,
                ),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: TextField(
                controller: alertSearchController,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: "Search Alerts...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  suffixIcon:
                      Icon(Icons.search, color: Appcolors.primary, size: 25.r),
                ),
                onChanged: searchAlerts,
              ),
            ),
          ),
          SizedBox(width: 5.w),
          TextButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Container(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text("SORT BY",
                              style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "Assistant")),
                        ),
                        SizedBox(height: 10.h),
                        Divider(
                            color: Colors.grey.shade300,
                            thickness: 2.h,
                            height: 0.01.sh),
                        ListTile(
                          title: Text("Oldest To Newest",
                              style: TextStyle(
                                  fontFamily: "Assistant", fontSize: 16.sp)),
                          onTap: () {
                            sortAlerts('Oldest To Newest');
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: Text("Newest To Oldest",
                              style: TextStyle(
                                  fontFamily: "Assistant", fontSize: 16.sp)),
                          onTap: () {
                            sortAlerts('Newest To Oldest');
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: Text("Task Name : A-Z",
                              style: TextStyle(
                                  fontFamily: "Assistant", fontSize: 16.sp)),
                          onTap: () {
                            sortAlerts('Task Name : A-Z');
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: Text("Task Name : Z-A",
                              style: TextStyle(
                                  fontFamily: "Assistant", fontSize: 16.sp)),
                          onTap: () {
                            sortAlerts('Task Name : Z-A');
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            icon: Icon(Icons.sort_rounded,
                size: 25.r, color: Appcolors.backGroundColor),
            label: Text("Sort",
                style: TextStyle(
                    fontSize: 14.sp,
                    color: Appcolors.backGroundColor,
                    fontWeight: FontWeight.w700)),
          ),
          Row(
            children: [
              SizedBox(
                width: 55.w,
                height: 25.h,
                child: AnimatedToggleSwitch.dual(
                  animationCurve: Curves.linear,
                  current: positive,
                  first: false,
                  second: true,
                  onChanged: (value) async {
                    setState(() {
                      positive = value;
                    });
                    if (positive) {
                      await showAcknowledgeAlert();
                    }
                    setState(() {
                      filteredData = positive
                          ? List.from(ackData)
                          : responseData
                              .where((alert) => alert['acknowledged'] != true)
                              .toList();
                    });
                  },
                  styleBuilder: (b) => ToggleStyle(
                    borderColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                          color: const Color.fromRGBO(0, 0, 0, 0.259),
                          spreadRadius: 1.r,
                          blurRadius: 2.r,
                          offset: const Offset(0, 1.5))
                    ],
                    indicatorColor: Colors.transparent,
                  ),
                  iconBuilder: (value) => value
                      ? CircleAvatar(
                          radius: 20.r,
                          backgroundColor: Colors.green,
                          child: Icon(Icons.done_all, size: 18.r))
                      : ClipOval(
                          child: Container(
                              width: 15.w, height: 15.h, color: Colors.grey),
                        ),
                ),
              ),
              SizedBox(width: 10.w),
              Text("Show\nAck Alerts",
                  style: TextStyle(
                      color: Appcolors.backGroundColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildAlertList() {
    final int totalCount = filteredData.length;
    final int itemsToDisplay =
        displayedItemCount < totalCount ? displayedItemCount : totalCount;
    if (filteredData.isEmpty) {
      return Center(
        child: isLoading
            ? LoadingAnimationWidget.stretchedDots(
                color: Colors.blue, size: 50.r)
            : Padding(
                padding: EdgeInsets.all(30.r),
                child: Text("No alerts found.",
                    style: TextStyle(
                        fontFamily: "bold",
                        fontSize: 18.sp,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold)),
              ),
      );
    }
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemsToDisplay,
          itemBuilder: (context, index) {
            final alert = filteredData[index];
            final String alertTime = positive
                ? (alert['acknowledged_time'] ?? alert['alert_time'] ?? "N/A")
                : (alert['alert_time'] ?? "N/A");
            List<String> dt = parseDateTime(alertTime);
            final String alertMessage = alert['message'] ?? "";
            String messageAfter = alertMessage.length > 35
                ? '${alertMessage.substring(0, 35)}...'
                : alertMessage;
            return InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () => showAllinfoDialog(context, alert),
              child: Column(
                children: [
                  Container(
                    color: Colors.white24,
                    margin:
                        EdgeInsets.symmetric(vertical: 8.h, horizontal: 15.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  alert['topic']?.toString().split('_').last ??
                                      "N/A",
                                  style: TextStyle(
                                      fontSize: 17.sp, fontFamily: "bold")),
                              SizedBox(height: 5.h),
                              Text(messageAfter,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Appcolors.primary,
                                  )),
                              SizedBox(height: 10.h),
                              Material(
                                elevation: 1.r,
                                borderRadius: BorderRadius.circular(10.r),
                                child: SizedBox(
                                  width: 90.w,
                                  height: 30.h,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: alertColor(alert['alerttype']),
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: Center(
                                      child: Text(alert['alerttype'],
                                          style: TextStyle(
                                            fontFamily: "bold",
                                            fontSize: 17.sp,
                                            color: Appcolors.primary,
                                          )),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Padding(
                          padding: EdgeInsets.all(5.r),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(dt[0],
                                  style: TextStyle(
                                    fontFamily: "bold",
                                    fontSize: 12.sp,
                                    color: Appcolors.primary,
                                  )),
                              SizedBox(height: 5.h),
                              Text(dt[1],
                                  style: TextStyle(
                                    fontFamily: "bold",
                                    fontSize: 12.sp,
                                    color: Appcolors.primary,
                                  )),
                              SizedBox(height: 10.h),
                              if (positive)
                                Icon(Icons.done_all,
                                    size: 30.r, color: Colors.green),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                      color: Colors.grey.shade400,
                      height: 15.h,
                      thickness: 1.h),
                ],
              ),
            );
          },
        ),
        if (_isFetchingMore)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: const CircularProgressIndicator(),
          )
      ],
    );
  }

  Widget buildStationChart() {
    List<_ChartData> localChartData = [];
    print(alertStationData);
    if (alertStationData.isNotEmpty) {
      for (var i in alertStationData["AlertsByStation"]) {
        localChartData
            .add(_ChartData(i["name"].toString(), double.parse(i["count"])));
      }
    }
    return SizedBox(
      width: 200.w,
      height: 170.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SfCircularChart(
            legend: const Legend(
                isVisible: true,
                alignment: ChartAlignment.center,
                itemPadding: 10),
            tooltipBehavior: TooltipBehavior(enable: true),
            series: <CircularSeries>[
              DoughnutSeries<_ChartData, String>(
                dataSource: localChartData,
                xValueMapper: (_ChartData data, _) => data.x,
                yValueMapper: (_ChartData data, _) => data.y,
                strokeWidth: 0.3.w,
                radius: '105%',
                innerRadius: '45',
                groupMode: CircularChartGroupMode.point,
                groupTo: 4,
              )
            ],
          ),
          Positioned(
            bottom: 60.h,
            child: Text(
              '${(alertStationData["AlertsByStation"] is List && (alertStationData["AlertsByStation"] as List).isNotEmpty) ? alertStationData["AlertsByStation"][0]["count"] : 0}',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Appcolors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDeviceChart() {
    List<_ChartData> barGraph = [];
    if (alertStationData.isNotEmpty) {
      var devicesListData = alertStationData['alertsbyDevice'] as List;
      var signalData = devicesListData
          .firstWhere((el) => el['name'] == 'Signal', orElse: () => null);
      var pointData = devicesListData
          .firstWhere((el) => el['name'] == 'Pointmachine', orElse: () => null);
      var trackData = devicesListData.firstWhere((el) => el['name'] == 'Track',
          orElse: () => null);

      barGraph.add(_ChartData('Signal',
          signalData != null ? double.parse(signalData['count']) : 0.0));
      barGraph.add(_ChartData(
          'Point', pointData != null ? double.parse(pointData['count']) : 0.0));
      barGraph.add(_ChartData(
          'Track', trackData != null ? double.parse(trackData['count']) : 0.0));
    }

    return SizedBox(
      width: 270.w,
      height: 270.h,
      child: Card(
        elevation: 4.r,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Padding(
              padding: EdgeInsets.all(5.r),
              child: Center(
                child: UiHelper.smallText_bold(
                  text: "Alerts by Device Types",
                ),
              ),
            ),
            Expanded(
              child: barGraph.every((d) => d.y == 0.0)
                  ? Center(child: UiHelper.NDF(text: "No alerts avliable."))
                  : Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: SfCartesianChart(
                        isTransposed: true,
                        primaryXAxis: const CategoryAxis(),
                        primaryYAxis: const NumericAxis(
                            minimum: 0, maximum: 100, interval: 25),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <CartesianSeries<_ChartData, String>>[
                          BarSeries<_ChartData, String>(
                            dataSource: barGraph,
                            xValueMapper: (data, _) => data.x,
                            yValueMapper: (data, _) => data.y,
                            width: 0.3.w,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10.r),
                              topRight: Radius.circular(10.r),
                            ),
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                              labelAlignment: ChartDataLabelAlignment.outer,
                            ),
                          )
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: visiblesetting
            ? SettingPage(
                onChange: (value) => setState(() => visiblesetting = value))
            : Material(
                elevation: 10.r,
                borderRadius: BorderRadius.circular(10.r),
                child: SnappingSheet(
                  controller: sheetController,
                  onSheetMoved: (pos) {
                    setState(() {
                      currentSheetFactor = pos.relativeToSnappingPositions;
                    });
                  },
                  lockOverflowDrag: true,
                  grabbingHeight: 50.h,
                  grabbing: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            blurRadius: 30.r,
                            color: Appcolors.primary.withAlpha(25))
                      ],
                      color: const Color(0xFFFEF7FF),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30.r),
                          topRight: Radius.circular(30.r)),
                    ),
                    child: Center(
                      child: Container(
                        width: 55.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                  ),
                  sheetBelow: SnappingSheetContent(
                    draggable: true,
                    child: Container(
                      color: const Color(0xFFFEF7FF),
                      child: Column(
                        children: [
                          UiHelper.customHeadings(
                            text: "Alerts History",
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              buildDropdown(
                                  selectedValues, "Station", stationList,
                                  (newValue) async {
                                setState(() {
                                  selectedValues = newValue ?? '';
                                  isDataAvilable = false;
                                  selectedAssets = selectedDevices = null;
                                });
                                await sendingStationValue(selectedValues!);
                                await getAlertsHistory();
                              }),
                              buildDropdown(
                                  selectedAssets, "Assets", assetsList,
                                  (newValue) async {
                                setState(() {
                                  selectedAssets = newValue ?? '';
                                  selectedDevices = null;
                                  isDataAvilable = false;
                                });
                                if (selectedAssets != null &&
                                    selectedAssets!.isNotEmpty) {
                                  await sendingStationValue(selectedValues!);
                                }
                                await getAlertsHistory();
                              }),
                              buildDropdown(
                                  selectedDevices, "Devices", devicesList,
                                  (newValue) async {
                                setState(() {
                                  selectedDevices = newValue ?? '';
                                  isDataAvilable = false;
                                });
                                if (selectedValues != null) {
                                  await getAlertsHistory();
                                }
                              }),
                            ],
                          ),
                          buildSearchSortRow(screenHeight),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: buildAlertList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  snappingPositions: const [
                    SnappingPosition.factor(
                        positionFactor: 0.37,
                        snappingCurve: Curves.linear,
                        snappingDuration: Duration(milliseconds: 10)),
                    SnappingPosition.factor(
                        positionFactor: 0.85,
                        snappingCurve: Curves.linear,
                        snappingDuration: Duration(milliseconds: 10)),
                  ],
                  initialSnappingPosition: const SnappingPosition.factor(
                      positionFactor: 0.37,
                      snappingCurve: Curves.linear,
                      snappingDuration: Duration(milliseconds: 200)),
                  child: CustomRefreshIndicator(
                    onRefresh: onRefresh,
                    triggerMode: IndicatorTriggerMode.anywhere,
                    durations: const RefreshIndicatorDurations(
                        completeDuration: Duration(seconds: 1)),
                    onStateChanged: (change) {
                      if (change.didChange(to: IndicatorState.complete)) {
                        renderCompleteState = true;
                      } else if (change.didChange(to: IndicatorState.idle)) {
                        renderCompleteState = false;
                      }
                    },
                    builder: (BuildContext context, Widget child,
                        IndicatorController controller) {
                      final CheckMarkColors style = renderCompleteState
                          ? (hasError
                              ? checkMarkStyle.error
                              : checkMarkStyle.success)
                          : checkMarkStyle.loading;
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          AnimatedBuilder(
                            animation: controller,
                            builder: (context, _) {
                              return Transform.translate(
                                  offset: Offset(0, controller.value * 100),
                                  child: child);
                            },
                            child: child,
                          ),
                          AnimatedBuilder(
                            animation: controller,
                            builder: (context, _) {
                              return Opacity(
                                opacity: controller.isLoading
                                    ? 1.0
                                    : controller.value.clamp(0.0, 1.0),
                                child: Container(
                                  height: 80.h,
                                  alignment: Alignment.center,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 40.w,
                                    height: 40.h,
                                    decoration: BoxDecoration(
                                        color: style.background,
                                        shape: BoxShape.circle),
                                    child: Center(
                                      child: renderCompleteState
                                          ? Icon(
                                              hasError
                                                  ? Icons.close
                                                  : Icons.check,
                                              color: style.content,
                                              size: 24.r)
                                          : SizedBox(
                                              height: 24.h,
                                              width: 24.w,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: style.content,
                                                value: controller.isDragging ||
                                                        controller.isArmed
                                                    ? controller.value
                                                        .clamp(0.0, 1.0)
                                                    : null,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                    child: RepaintBoundary(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 100),
                          opacity: backgroundOpacity,
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 60.h,
                                child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10.h),
                                  child: Center(
                                    child: Row(
                                         mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(width: 40.w),
                                        InkWell(
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () => getAlertsForDashboard(),
                                          child: Center(
                                            child: UiHelper.customHeadings(
                                              text: "Alerts Dashboard",
                                            ),
                                          ),
                                        ),    SizedBox(width: 8.w),
                                        IconButton(
                                          onPressed: () => widget.onGoToSettings(),
                                          icon: Icon(Icons.settings, size: 30.r),
                                        ),
                                        SizedBox(width: 10.w),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: SizedBox(
                                width: double.infinity,
                                  height: 100.h,
                                  child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Card(
                                        elevation: 2.r,
                                        child: SizedBox(
                                          width: 195.w,
                                          height: 90.h,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              UiHelper.xsmalltxt_bold(
                                                  text: "Avg Ack Time"),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  SvgPicture.asset(
                                                      'assets/images/clock.svg',
                                                      width: 20.w),
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 20.w),
                                                    child: UiHelper.normal_bold(
                                                      text:
                                                          getAverageAckDuration(),
                                                      color: Appcolors.primary,
                                                    ),
                                                  )
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ),   SizedBox(width: 50.w),
                                      Card(
                                        elevation: 4.r,
                                        child: SizedBox(
                                          width: 195.w,
                                          height: 90.h,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              UiHelper.xsmalltxt_bold(
                                                  text: "Avg Resp Time"),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  SvgPicture.asset(
                                                      'assets/images/clock.svg',
                                                      width: 20.w),
                                                  Padding(
                                                      padding: EdgeInsets.only(
                                                          right: 20.w),
                                                      child: UiHelper.normal_bold(
                                                          text:
                                                              getAverageResponseDuration(),
                                                          color: Colors.black))
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                 padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 270.h,
                                  child: Row(   
                                     mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Card(
                                        elevation: 4.r,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            UiHelper.smallText_bold(
                                              text: "Alerts by Station",
                                            ),      
                                            // SizedBox(width: 50.w),
                                            buildStationChart(),
                                          ],
                                        ),
                                      ),      SizedBox(width: 50.w),
                                      buildDeviceChart(),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y);
  final String x;
  final double y;
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
  const CheckMarkStyle(
      {required this.loading, required this.success, required this.error});
}
