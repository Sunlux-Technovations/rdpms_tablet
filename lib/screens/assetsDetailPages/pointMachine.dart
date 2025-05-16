import 'dart:async';
import 'dart:convert';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:rdpms_tablet/Apis/Urls.dart';
import 'package:rdpms_tablet/Apis/dioInstance.dart';
import 'package:rdpms_tablet/screens/constants/socketTopic.dart';
import 'package:rdpms_tablet/widgets/UiHelper.dart';

import 'package:rdpms_tablet/widgets/appColors.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class Pointmachine extends StatefulWidget {
  final Function(bool) onCardsChange;
  final String selectedStationName;
  // final Function(int) onNavigateToAsset;
  // final Function(int) onNavigateToAlerts;
  // final Function(int) onNavigateToMaintenance;
  // final GlobalKey<MaintenanceRoutesState> maintenanceKey;
  // final bool showTutorial;
  const Pointmachine({
    super.key,
    required this.onCardsChange,
    required this.selectedStationName,
    // required this.onNavigateToAsset,
    // required this.onNavigateToAlerts,
    // required this.onNavigateToMaintenance,
    // required this.maintenanceKey,
    // required this.showTutorial,
  });

  @override
  State<Pointmachine> createState() => _PointmachineState();
}

class _PointmachineState extends State<Pointmachine> {
  dynamic responseData = [];
  List<Map<String, dynamic>> filterPointGroupName = [];
  dynamic pointMaintenanceData;
  dynamic analyticsData;
  bool loader = true, loader1 = true;
  bool search = false, isGraphOpen = true;
  bool isRealTimeOpen = false,
      isAlertsOpen = false,
      isMaintenanceOpen = false,
      isAnalyticsOpen = false,
      isHistoryOpen = false;
  bool _renderCompleteState = false, _hasError = false;

  bool get isAnyAccordionOpen =>
      isRealTimeOpen ||
      isAlertsOpen ||
      isMaintenanceOpen ||
      isAnalyticsOpen ||
      isHistoryOpen;
  int analyticsIndex = 0, dataUpdateCounter = 0;
  DateTime? latestTime;
  TextEditingController searchController = TextEditingController();
  PageController? _pageController;
  Timer? socketTimer;
  Map<String, List<SalesData>> socketPMData = {};
  IO.Socket? socket;
   int chartSeconds = 1;
  final checkMarkStyle = const CheckMarkStyle(
    loading:
        CheckMarkColors(content: Colors.white, background: Colors.blueAccent),
    success:
        CheckMarkColors(content: Colors.black, background: Colors.greenAccent),
    error: CheckMarkColors(content: Colors.black, background: Colors.redAccent),
  );

  @override
  void initState() {
    super.initState();
    initSocket();
    getPointData();
  }

  @override
  void dispose() {
    searchController.dispose();
    socket?.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  void initSocket() {
    socket = IO.io(assetpagessocket, {
      'transports': ['websocket'],
      'autoConnect': false,
 
    });
    socket!.connect();
    socket!.onConnect((_) {
      socket!.emit('subscribe', {'topic': assetpageTopic});
    });
    socket!.on('update', (data) {
    
      if (data is Map<String, dynamic>) {
        var message = data['message'];
        if (message is String) {
          try {
            message = jsonDecode(message);
          } catch (_) {
            return;
          }
        }
        if (message is! Map<String, dynamic> ||
            !message.containsKey('datetime') ||
            !message.containsKey('tagid') ||
            !message.containsKey('message')) {
          return;
        }

        DateTime parsedTime;
        try {
          parsedTime =
              DateFormat("dd-MM-yyyy HH:mm:ss").parse(message['datetime']);
        } catch (_) {
          parsedTime = DateTime.now();
        }

        final now = DateTime.now();
        Duration rawLatency = now.difference(parsedTime);

        Duration displayLatency =
            rawLatency.isNegative ? Duration.zero : rawLatency;


        var rawMsg = message['message'];
        Map<String, dynamic> msgData;
        if (rawMsg is String) {
          try {
            msgData = jsonDecode(rawMsg);
          } catch (_) {
            return;
          }
        } else if (rawMsg is Map<String, dynamic>) {
          msgData = rawMsg;
        } else {
          return;
        }

        String valueKey = msgData.keys.first;
        double value =
            double.tryParse(msgData[valueKey]?.toString() ?? "0.0") ?? 0.0;

        var tag = message['tagid'];
        socketPMData.update(
          tag,
          (existing) => [...existing, SalesData(parsedTime, value)],
          ifAbsent: () => [SalesData(parsedTime, value)],
        );

        if (latestTime == null || parsedTime.isAfter(latestTime!)) {
          latestTime = parsedTime;
        }
        handleSocketUpdate();
        if (mounted) {
          setState(() {});
        }
      }
    });

    socket!.onDisconnect((_) => print('Socket disconnected'));
    socket!.onError((err) => print('Socket error: $err'));
  }

  void handleSocketUpdate() {
    if (socketTimer?.isActive ?? false) return;
    socketTimer = Timer(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          dataUpdateCounter++;
        });
      }
    });
  }
  Future<void> getPointData() async {
    String locationName = widget.selectedStationName;
    String sensorName = "Pointmachine";
    try {
      var response = await dioInstance.get(
          "$getSensorValuesByStation?name=$sensorName&station=$locationName");
      setState(() {
        responseData = response;

        if (responseData is List) {
          filterPointGroupName =
              (responseData as List).cast<Map<String, dynamic>>();
        } else if (responseData is Map) {
          filterPointGroupName = (responseData as Map)
              .values
              .toList()
              .cast<Map<String, dynamic>>();
        }
        loader = false;
      });
      if (filterPointGroupName.isNotEmpty) {
        getPointMaintenanceData(0);
      }
      if (filterPointGroupName.isNotEmpty) {
        for (var group in filterPointGroupName) {
          latestTimeForAPI(group);
        }
        getPointMaintenanceData(filterPointGroupName.first);
      }
    } catch (err) {
      print(err);
      setState(() => loader = false);
    }
  }

  void latestTimeForAPI(Map<String, dynamic> groupData) {
    List<dynamic> dataArray = groupData['data'] ?? [];
    for (var ele in dataArray) {
      if (ele is Map) {
        ele.forEach((key, value) {
          for (var point in value) {
            try {
              DateTime time = DateTime.parse(point['reading_time']).toLocal();
              if (latestTime == null || time.isAfter(latestTime!)) {
                latestTime = time;
              }
            } catch (_) {}
          }
        });
      }
    }
  }

  Future<void> getPointMaintenanceData(dynamic value) async {
    String grpName;
    if (value is int) {
      grpName = filterPointGroupName[value]['groupname'];
    } else if (value is Map<String, dynamic>) {
      grpName = value['groupname'];
    } else {
      throw ArgumentError('Unexpected error');
    }

    String location = widget.selectedStationName;
    String assets = "Pointmachine";

    try {
      var maintenanceResponse = await dioInstance.get(
          "$getAllAlertsMaintenance?station=$location&assets=$assets&group_name=$grpName");

      if (!mounted) return;
      setState(() {
        pointMaintenanceData = maintenanceResponse;
        analyticsData = pointMaintenanceData['analytics'];
        loader1 = false;
      });
    } catch (err) {
      print(err);

      if (!mounted) return;
      setState(() => loader1 = false);
    }
  }

  void onSearchChanged(String value) {
    if (value.isEmpty) {
      filterPointGroupName =
          (responseData as List).cast<Map<String, dynamic>>();
    } else {
      filterPointGroupName = (responseData as List)
          .where((grp) {
            final name = grp['groupname']?.toString().toLowerCase() ?? '';
            return name.contains(value.toLowerCase());
          })
          .toList()
          .cast<Map<String, dynamic>>();
    }
    setState(() {});
  }

  Future<void> onRefresh() async {
    setState(() {
      loader = true;
      loader1 = true;
      responseData = [];
      pointMaintenanceData = [];
      analyticsData = null;
    });
    try {
      await getPointData();
      if (filterPointGroupName.isNotEmpty) {
        await getPointMaintenanceData(analyticsIndex);
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  Widget buildAppBar() {
    return SizedBox(
      height: 60.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
              padding: EdgeInsets.only(left: 10.w),
              child: InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () => widget.onCardsChange(false),
                  child: Icon(Icons.arrow_back_rounded,
                      size: 30.r, weight: 50.r))),
          search
              ? SizedBox(
                  width: 250.w,
                  child: TextField(
                      controller: searchController,
                      style: const TextStyle(fontSize: 16, fontFamily: 'bold'),
                      decoration: InputDecoration(
                        hintText: "Search...",
                        hintStyle: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'bold',
                            color: Colors.grey),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(left: 10),
                      ),
                      onChanged: onSearchChanged),
                )
              : InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    getPointData();
                    getPointMaintenanceData(0);
                  },
                  child: UiHelper.customText(
                      text: "Point Machine",
                      color: Colors.black,
                      fontsize: 25.r,
                      fontWeight: FontWeight.w700,
                      fontFamily: "bold")),
          Padding(
                  padding: EdgeInsets.only(right: 85.w),
              child: InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    setState(() => search = !search);
                  },
                  child: search
                      ? Icon(Icons.close_outlined, size: 30.r, weight: 800.r)
                      : Icon(Icons.search_rounded, size: 30.r, weight: 800.r)))
        ],
      ),
    );
  }

  Widget buildPointCard(int index, Map<String, dynamic> groupData) {
    var dataArray = groupData['data'] ?? [];
    if (dataArray.isEmpty || dataArray[0].keys.isEmpty) {
      return const Center(child: Text("Invalid data"));
    }
    String firstKey = dataArray[0].keys.first;
    var sortedData = dataArray[0][firstKey][0];
    var tagKeys = List<String>.from(groupData['tag_keys'] ?? []);
    List<Map<String, dynamic>> rank1Point = [];
    for (var item in dataArray) {
      if (item is Map) {
        item.forEach((key, value) {
          if (tagKeys.contains(key) && value is List) {
            for (var point in value) {
              rank1Point.add(point);
            }
          }
        });
      }
    }
return Card(
    elevation: 12.r,
    child: SizedBox(
      height: 500.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),
                  buildHeader(sortedData, groupData['groupname'], index),
                  SizedBox(height: 30.h),
                  buildGraph(groupData),
                ],
              ),
            ),

            SizedBox(width: 10.w),

            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 30.h),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: buildAccordions(rank1Point),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget buildHeader(dynamic sortedData, dynamic groupName, int index) {
    return Card(
      elevation: 3.r,
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () => setState(() => isGraphOpen = !isGraphOpen),
        child: Container(
          width: 480.w,
          height: 80.h,
          decoration: BoxDecoration(
            color: HexColor("#457b9d"),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              SizedBox(width: 15.w),
              SvgPicture.asset("assets/images/antenna.svg",
                  width: 50.w,
                  colorFilter:
                      const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
              SizedBox(width: 14.w),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UiHelper.customText(
                      text: groupName.toString(),
                      color: Colors.white,
                      fontsize: 28.r,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'bold'),
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled,
                          color: Colors.white, size: 20),
                      SizedBox(width: 4.w),
                      UiHelper.customText(
                          text: sortedData['reading_time']
                              .toString()
                              .replaceAll("T", "  "),
                          color: Colors.white,
                          fontsize: 14.r,
                          fontWeight: FontWeight.w700),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfoRow(dynamic sortedData) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: Row(
        children: [
          SizedBox(
              width: 170.w,
              child: Row(
                children: [
                  SizedBox(width: 15.w),
                  UiHelper.customText(
                      text: sortedData['device'].toString(),
                      color: Appcolors.backGroundColor,
                      fontsize: 12.r,
                      fontWeight: FontWeight.w700),
                  const Text(" :"),
                  SizedBox(width: 10.w),
                  UiHelper.customText(
                      text: sortedData['tagid'].toString(),
                      color: Colors.black,
                      fontsize: 12.r,
                      fontWeight: FontWeight.w700),
                ],
              )),
          SizedBox(
              width: 190.w,
              child: Row(
                children: [
                  const Spacer(),
                  SizedBox(width: 5.w),
                  UiHelper.customText(
                      text: sortedData['description'].toString(),
                      color: Appcolors.backGroundColor,
                      fontsize: 12.r,
                      fontWeight: FontWeight.w700),
                  SizedBox(width: 10.w),
                  UiHelper.customText(
                      text: sortedData['value'].toString(),
                      color: Colors.black,
                      fontsize: 12.r,
                      fontWeight: FontWeight.w700),
                ],
              ))
        ],
      ),
    );
  }

  Widget buildGraph(Map<String, dynamic> groupData) {
    List<LineSeries<SalesData, DateTime>> seriesList = lineSeries(groupData);
    if (seriesList.isEmpty) {
      return SizedBox(
        height: 270.h,
        child: Center(
          child: UiHelper.customText(
            text: "No data available",
            color: Colors.grey,
            fontsize: 16.r,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    DateTime? apiMinTimeValue;
    DateTime? apiMaxTimeValue;
    List<SalesData> apiDataPoints = [];
    List<dynamic> apiDataArray = groupData['data'] ?? [];
    for (var ele in apiDataArray) {
      if (ele is Map) {
        ele.forEach((key, value) {
          for (var point in value) {
            try {
              DateTime t = DateTime.parse(point['reading_time']).toLocal();
              apiDataPoints.add(SalesData(
                  t, double.tryParse(point['value'].toString()) ?? 0));
              if (apiMinTimeValue == null || t.isBefore(apiMinTimeValue!)) {
                apiMinTimeValue = t;
              }
              if (apiMaxTimeValue == null || t.isAfter(apiMaxTimeValue!)) {
                apiMaxTimeValue = t;
              }
            } catch (_) {}
          }
        });
      }
    }


    apiMinTimeValue ??= DateTime.now();
    apiMaxTimeValue ??= DateTime.now();

    DateTime combinedMax = apiMaxTimeValue!;
    for (var series in seriesList) {
      for (var data in series.dataSource!) {
        if (data.time.isAfter(combinedMax)) {
          combinedMax = data.time;
        }
      }
    }

    if (DateTime.now().isAfter(combinedMax)) {
      combinedMax = DateTime.now();
    }


if (apiMinTimeValue!.isAtSameMomentAs(apiMaxTimeValue!)) {
  
  apiMaxTimeValue = apiMaxTimeValue!.add(
    Duration(seconds: chartSeconds), 
  );

  
  if (combinedMax.isBefore(apiMaxTimeValue!)) {
    combinedMax = apiMaxTimeValue!;
  }
}
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 450.h,
      width: 510.w,
      child: Offstage(
        offstage: ( !isGraphOpen),
        child: RepaintBoundary(
          child: SfCartesianChart(
            key: ValueKey("chart_${groupData['groupname']}_$dataUpdateCounter"),
            primaryXAxis: DateTimeAxis(
              minimum: apiMinTimeValue,
              maximum: combinedMax,
              desiredIntervals: 6,
              intervalType: DateTimeIntervalType.seconds,
              edgeLabelPlacement: EdgeLabelPlacement.shift,
              dateFormat: DateFormat('HH:mm:ss'),
      labelStyle:  TextStyle(color: Colors.grey,fontSize: 12.sp),
            ),
            primaryYAxis: const NumericAxis(
              labelStyle: TextStyle(color: Colors.grey),
            ),
            legend:
                 Legend(isVisible: true, position: LegendPosition.bottom,textStyle: TextStyle(fontSize: 12.sp)),
            tooltipBehavior: TooltipBehavior(textStyle: TextStyle(fontSize: 12.sp),
                enable: isGraphOpen && !isAnyAccordionOpen,
                format: 'point.x: point.y'),
            zoomPanBehavior:
                ZoomPanBehavior(enablePinching: true, enablePanning: true),
            series: seriesList,
          ),
        ),
      ),
    );
  }


  List<LineSeries<SalesData, DateTime>> lineSeries(
      Map<String, dynamic> groupData) {
    List<dynamic> tagKeys = groupData['tag_keys'] ?? [];
    return tagKeys.map<LineSeries<SalesData, DateTime>>((tag) {
      List<SalesData> apiDataList = [];
      for (var ele in groupData['data'] ?? []) {
        if (ele is Map && ele.containsKey(tag)) {
          for (var point in ele[tag] ?? []) {
            double value = double.tryParse(point['value'].toString()) ?? 0;
            DateTime time;
            try {
              time = DateTime.parse(point['reading_time']).toLocal();
            } catch (_) {
              time = DateTime.now();
            }
            apiDataList.add(SalesData(time, value));
          }
        }
      }
      List<SalesData> combinedData = [
        ...apiDataList,
        ...?socketPMData[tag]
      ];
   combinedData.sort(
      (SalesData earlier, SalesData later) =>
          earlier.time.compareTo(later.time),
    );
      return LineSeries<SalesData, DateTime>(
        name: tag.toString(),
        dataSource: combinedData,
        xValueMapper: (SalesData s, _) => s.time,
        yValueMapper: (SalesData s, _) => s.value,
        markerSettings: MarkerSettings(
          isVisible: true,
          shape: DataMarkerType.circle,
          color: Appcolors.primary,
          borderWidth: 2,
          height: 6,
          width: 6,
        ),
      );
    }).toList();
  }

  Widget buildAccordion({
    required bool isOpen,
    required VoidCallback onToggle,
    required String title,
    required Widget content,
    double collapsedHeight = 48,
    double expandedHeight = 310,
  }) {
    return Card(
      elevation: 4,
      child: AnimatedContainer(
        duration: const Duration(seconds: 1),
        width: MediaQuery.of(context).size.width * 0.94,
        height: isOpen ? expandedHeight.h : collapsedHeight.h,
        curve: Curves.fastEaseInToSlowEaseOut,
        child: Stack(
          children: [
            InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: onToggle,
              child: Container(
                width: 375.w,
                height: collapsedHeight.h,
                decoration: BoxDecoration(
                  color: HexColor("#457b9d"),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 10.w),
                    UiHelper.customText(
                        text: title,
                        color: Colors.white,
                        fontsize: 18.r,
                        fontWeight: FontWeight.w700),
                    Icon(
                        isOpen
                            ? Icons.arrow_drop_up_outlined
                            : Icons.arrow_drop_down_outlined,
                        color: Colors.white,
                        size: 32.r),
                  ],
                ),
              ),
            ),
            if (isOpen)
              Positioned(
                top: collapsedHeight.h,
                child: SizedBox(
                  width: 375.w,
                  height: (expandedHeight - collapsedHeight).h,
                  child: content,
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget buildAccordions(List<Map<String, dynamic>> rank1Signals) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isAnyAccordionOpen ? (325 + 150).h : 325.h,
      child: ListView(
        physics: isAnyAccordionOpen
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        children: [
          buildAccordion(
            isOpen: isRealTimeOpen,
            onToggle: () => setState(() => isRealTimeOpen = !isRealTimeOpen),
            title: "RealTime",
            collapsedHeight: 48,
            expandedHeight: 190,
            content: Column(
              children: [
                SizedBox(
                  width: 351.w,
                  height: 39.h,
                  child: Row(
                    children: [
                      SizedBox(width: 7.w),
                      SizedBox(
                          width: 50.w,
                          height: 30.h,
                          child: Center(
                              child: UiHelper.customText(
                                  text: "Name",
                                  color: Colors.black,
                                  fontsize: 12.r,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: "bold"))),
                      SizedBox(width: 20.w),
                      SizedBox(
                          width: 50.w,
                          height: 30.h,
                          child: Center(
                              child: UiHelper.customText(
                                  text: "Current",
                                  color: Colors.black,
                                  fontsize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: "bold"))),
                      SizedBox(width: 28.w),
                      SizedBox(
                          width: 51.w,
                          height: 30.h,
                          child: Center(
                              child: UiHelper.customText(
                                  text: "Voltage",
                                  color: Colors.black,
                                  fontsize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: "bold"))),
                    ],
                  ),
                ),
                SizedBox(
                  width: 360.w,
                  height: 90.h,
                  child: Scrollbar(
                    child: ListView.separated(
                      itemCount: rank1Signals.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 5.h),
                      itemBuilder: (context, index) {
                        final pointM = rank1Signals[index];
                        final doubleColor =
                            pointM['tagid'].toString().contains("HHG");
                        final sig = pointM['description']
                            .toString()
                            .replaceAll("Double", "")
                            .replaceAll(":", "")
                            .trim();
                        Color backColor;
                        switch (sig) {
                          case 'Yellow':
                            backColor = HexColor("#FF9D23");
                            break;
                          case 'Red':
                            backColor = Colors.red;
                            break;
                          case 'Green':
                            backColor = Colors.green;
                            break;
                          default:
                            backColor = Colors.transparent;
                        }
                        return SizedBox(
                          width: 360.w,
                          height: 30.h,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SizedBox(
                                  width: 50.w,
                                  height: 30.h,
                                  child: Center(
                                      child: UiHelper.customText(
                                          text: pointM['tagid'].toString(),
                                          color: Colors.black,
                                          fontsize: 12,
                                          fontWeight: FontWeight.w700))),
                              SizedBox(
                                  width: 50.w,
                                  height: 30.h,
                                  child: Center(
                                      child: UiHelper.customText(
                                          text: pointM['type'] == "Current"
                                              ? pointM['value'].toString()
                                              : 0.toString(),
                                          color: Colors.black,
                                          fontsize: 12,
                                          fontWeight: FontWeight.w700))),
                              SizedBox(
                                  width: 50.w,
                                  height: 30.h,
                                  child: Center(
                                      child: UiHelper.customText(
                                          text: pointM['type'] == "Voltage"
                                              ? pointM['value'].toString()
                                              : 0.toString(),
                                          color: Colors.black,
                                          fontsize: 12,
                                          fontWeight: FontWeight.w700))),
                              Container(
                                width: 130.w,
                                height: 30.h,
                                padding: EdgeInsets.symmetric(horizontal: 5.w),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: UiHelper.customText(
                                          text:
                                              pointM['description'].toString(),
                                          color: Colors.black,
                                          fontsize: 12.r,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    CircleAvatar(
                                        radius: 8.r,
                                        backgroundColor: backColor),
                                    if (doubleColor)
                                      Padding(
                                        padding: EdgeInsets.only(left: 4.w),
                                        child: CircleAvatar(
                                            radius: 8.r,
                                            backgroundColor: backColor),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          buildAccordion(
            isOpen: isAlertsOpen,
            onToggle: () => setState(() => isAlertsOpen = !isAlertsOpen),
            title: "Alerts",
            expandedHeight: 310,
            content: Column(
              children: [
                SizedBox(
                  width: 375.w,
                  height: 45.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                          padding: EdgeInsets.only(left: 10.w),
                          child: UiHelper.customText(
                              text: "Recent Alerts",
                              fontFamily: 'bold',
                              color: Colors.black,
                              fontsize: 16,
                              fontWeight: FontWeight.w800)),
                      Padding(
                        padding: EdgeInsets.only(right: 10.w),
                        child: Card(
                          elevation: 4.r,
                          child: Container(
                            width: 100.w,
                            height: 45.h,
                            decoration: BoxDecoration(
                                color: Appcolors.backGroundColor,
                                borderRadius: BorderRadius.circular(7)),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              // onTap: () => widget.onNavigateToAlerts(2),
                              child: Center(
                                  child: UiHelper.customText(
                                      text: "More Logs",
                                      fontFamily: 'bold',
                                      color: Colors.white,
                                      fontsize: 12.r,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 340.w,
                  height: 210.h,
                  child: loader1
                      ? Center(
                          child: LoadingAnimationWidget.stretchedDots(
                              color: Appcolors.backGroundColor, size: 50))
                      : (pointMaintenanceData == null ||
                              (pointMaintenanceData is List &&
                                  pointMaintenanceData.isEmpty))
                          ? const SizedBox()
                          :Text("pointalerts")
                          
                          //  Pointalertsaccordian(
                          //     maintenanceList: pointMaintenanceData is List
                          //         ? pointMaintenanceData
                          //         : [pointMaintenanceData],
                          //     onShowAlertDetails: () =>
                          //         widget.onNavigateToAsset(2),
                          //   ),
                ),
              ],
            ),
          ),
          buildAccordion(
            isOpen: isMaintenanceOpen,
            onToggle: () =>
                setState(() => isMaintenanceOpen = !isMaintenanceOpen),
            title: "Maintenance",
            expandedHeight: 310,
            content: Column(
              children: [
                SizedBox(
                  width: 375.w,
                  height: 45.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                          padding: EdgeInsets.only(left: 10.w),
                          child: UiHelper.customText(
                              text: "Recent Maintenance",
                              fontFamily: 'bold',
                              color: Colors.black,
                              fontsize: 16,
                              fontWeight: FontWeight.w800)),
                      Padding(
                        padding: EdgeInsets.only(right: 10.w),
                        child: Card(
                          elevation: 4.r,
                          child: Container(
                            width: 100.w,
                            height: 45.h,
                            decoration: BoxDecoration(
                                color: Appcolors.backGroundColor,
                                borderRadius: BorderRadius.circular(7)),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              // onTap: () {
                              //   widget.maintenanceKey.currentState
                              //       ?.setMaintenanceDataForHistory(
                              //           pointMaintenanceData ?? {});
                              //   widget.onNavigateToMaintenance(1);
                              // },
                              child: Center(
                                  child: UiHelper.customText(
                                      text: "More Logs",
                                      fontFamily: 'bold',
                                      color: Colors.white,
                                      fontsize: 12.r,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 340.w,
                  height: 210.h,
                  child: Text("maintenance"),
                  
                  // MaintenanceAccordian(
                  //   maintenanceList: pointMaintenanceData != null
                  //       ? [pointMaintenanceData]
                  //       : [],
                  //   onShowMaintenanceDetails: (detail) {
                  //     widget.maintenanceKey.currentState
                  //         ?.setMaintenanceDataFromSignal(detail);
                  //     widget.onNavigateToMaintenance(2);
                  //   },
                  // ),
                ),
              ],
            ),
          ),
          buildAccordion(
            isOpen: isAnalyticsOpen,
            onToggle: () {
              setState(() {
                isAnalyticsOpen = !isAnalyticsOpen;
                if (analyticsIndex >= 0 &&
                    analyticsIndex < filterPointGroupName.length) {
                  getPointMaintenanceData(analyticsIndex);
                }
              });
            },
            title: "Analytics",
            expandedHeight: 310,
            content: Text("analytics"),
            // Pointanalyticsaccordians(
            //   analyticsList: analyticsData != null ? [analyticsData] : [],
            //   lazyLoading: loader1,
            // ),
          ),
          buildAccordion(
            isOpen: isHistoryOpen,
            onToggle: () => setState(() => isHistoryOpen = !isHistoryOpen),
            title: "History",
            expandedHeight: 310,
            content: Text("history"),
            // PointhistoryAccordian(
            //   maintenanceList:
            //       pointMaintenanceData != null ? [pointMaintenanceData] : [],
            // ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (searchController.text.isEmpty) {
      filterPointGroupName =
          (responseData as List).cast<Map<String, dynamic>>();
    } else {
      filterPointGroupName = (responseData as List)
          .where((grp) {
            final name = grp['groupname']?.toString().toLowerCase() ?? '';
            return name.contains(searchController.text.toLowerCase());
          })
          .toList()
          .cast<Map<String, dynamic>>();
      if (filterPointGroupName.isNotEmpty) {
        getPointMaintenanceData(analyticsIndex);
      }
    }
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: CustomRefreshIndicator(
          onRefresh: onRefresh,
          triggerMode: IndicatorTriggerMode.anywhere,
          durations: const RefreshIndicatorDurations(
              completeDuration: Duration(seconds: 1)),
          onStateChanged: (change) {
            if (change.didChange(to: IndicatorState.complete)) {
              _renderCompleteState = true;
            } else if (change.didChange(to: IndicatorState.idle))
              // ignore: curly_braces_in_flow_control_structures
              _renderCompleteState = false;
          },
          builder: (context, child, controller) {
            final style = _renderCompleteState
                ? (_hasError ? checkMarkStyle.error : checkMarkStyle.success)
                : checkMarkStyle.loading;
            return Stack(
              alignment: Alignment.topCenter,
              children: [
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => Transform.translate(
                      offset: Offset(0, controller.value * 100), child: child),
                ),
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => Opacity(
                    opacity: controller.isLoading
                        ? 1.0
                        : controller.value.clamp(0.0, 1.0),
                    child: Container(
                      height: 80.h,
                      alignment: Alignment.center,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 40.r,
                        height: 40.r,
                        decoration: BoxDecoration(
                            color: style.background, shape: BoxShape.circle),
                        child: Center(
                          child: _renderCompleteState
                              ? Icon(_hasError ? Icons.close : Icons.check,
                                  color: style.content, size: 24.r)
                              : SizedBox(
                                  height: 24.r,
                                  width: 24.r,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: style.content,
                                    value: controller.isDragging ||
                                            controller.isArmed
                                        ? controller.value.clamp(0.0, 1.0)
                                        : null,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            );
          },
          child: SingleChildScrollView(
            child: Column(
              children: [       SizedBox(height: 20.h,),
                buildAppBar(),
                SizedBox(
                  height: 715.h,
                  child: loader
                      ? Center(
                          child: LoadingAnimationWidget.stretchedDots(
                              color: Appcolors.backGroundColor, size: 50))
                      : (filterPointGroupName.isEmpty)
                          ? Center(
                              child: Text("No Pointmachine Devices Found.",
                                  style: TextStyle(
                                      fontSize: 20.r,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)),
                            )
                          : PageView.builder(
                              controller: _pageController,
                              onPageChanged: (value) {
                                analyticsIndex = value;
                                getPointMaintenanceData(value);
                              },
                              itemCount: filterPointGroupName.length,
                              itemBuilder: (context, index) => buildPointCard(
                                  index, filterPointGroupName[index]),
                            ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SalesData {
  final DateTime time;
  final double value;
  SalesData(this.time, this.value);
  @override
  String toString() => 'SalesData(time: $time, value: $value)';
}

class CheckMarkColors {
  final Color content, background;
  const CheckMarkColors({required this.content, required this.background});
}

class CheckMarkStyle {
  final CheckMarkColors loading, success, error;
  const CheckMarkStyle(
      {required this.loading, required this.success, required this.error});
}