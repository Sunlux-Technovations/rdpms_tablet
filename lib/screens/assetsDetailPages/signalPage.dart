import 'dart:async';
import 'dart:convert';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:rdpms_tablet/Apis/Urls.dart';
import 'package:rdpms_tablet/Apis/dioInstance.dart';
import 'package:rdpms_tablet/screens/assetsDetailPages/SignalAnalyticsAccordian/AnalyticsAccordian.dart';
import 'package:rdpms_tablet/screens/assetsDetailPages/SignalHistoryAccoridans/HistoryAccordians.dart';
import 'package:rdpms_tablet/screens/constants/socketTopic.dart';

import 'package:rdpms_tablet/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class Signalpage extends StatefulWidget {
  final Function(bool) onCardsChange;
  final String selectedStationName;
  // final Function(int) onNavigateToAlerts;
  // final Function(int) onNavigateToMaintenance;
  final bool showTutorial;
  // final GlobalKey<MaintenanceRoutesState> maintenanceKey;

  const Signalpage({
    super.key,
    required this.onCardsChange,
    required this.selectedStationName,
    // required this.onNavigateToAlerts,
    // required this.onNavigateToMaintenance,
    required this.showTutorial,
    // required this.maintenanceKey,
  });

  @override
  State<Signalpage> createState() => _SignalpageState();
}

class _SignalpageState extends State<Signalpage> {
  dynamic responseData = [];
  bool loader = true, loader1 = true;
  bool search = false, isGraphOpen = true;
  bool isRealTimeOpen = false,
      isAlertsOpen = false,
      isMaintenanceOpen = false,
      isAnalyticsOpen = false,
      isHistoryOpen = false;
  bool renderCompleteState = false;
  final bool hasError = false;
  List<Map<String, dynamic>> filterGroupName = [];
  TextEditingController searchController = TextEditingController();
  int analyticsIndex = 0, dataUpdateCounter = 0;
  DateTime? latestTime;
  dynamic maintenanceData, analyticsData;
  List<GlobalKey> groupHeaderKeys = [];
  bool isDataLoaded = false;
  TutorialCoachMark? tutorial;
  List<TargetFocus> targets = [];
  int activeFetchId = 0;
  int currentPageIndex = 0;
  Timer? searchF;
  Map<String, List<SalesData>> socketSignalData = {};
  IO.Socket? socket;
  PageController? pageController;
  final checkMarkStyle = CheckMarkStyle(
    loading: CheckMarkColors(
        content: Appcolors.secondary, background: Colors.blueAccent),
    success: CheckMarkColors(
        content: Appcolors.primary, background: Colors.greenAccent),
    error: CheckMarkColors(
        content: Appcolors.primary, background: Colors.redAccent),
  );
  Timer? socketTimer;
   int chartSeconds = 1;
  @override
  void initState() {
    super.initState();
    initSocket();
    pageController = PageController(initialPage: 0);
    searchController.addListener(() {
      onSearchChanged(searchController.text);
    });
    getSignalData().then((_) {
      if (filterGroupName.isNotEmpty) {
        fetchForPage(0);
      }
      setState(() => isDataLoaded = true);
      initTutorialTargets();
      checkTutorialStatus();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    socket?.dispose();
    pageController?.dispose();
    super.dispose();
    socketTimer?.cancel();
  }

  void initSocket() {
    socket = IO.io(assetpagessocket, {
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket!.connect();
    socket!.onConnect((_) {
      socket!.emit('subscribe', {'topic': assetpageTopic,});
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
        socketSignalData.update(
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

  Future<void> getSignalData() async {
    String locationName = widget.selectedStationName;
    String sensorName = "Signal";
    final String url= "$getSensorValuesByStation?name=$sensorName&station=$locationName";
    try {
      var response = await dioInstance.get(
       url);

      setState(() {
        responseData = response;
        loader = false;
        if (responseData is Map) {
          filterGroupName = (responseData as Map)
              .values
              .toList()
              .cast<Map<String, dynamic>>();
        } else {
          filterGroupName = (responseData as List).cast<Map<String, dynamic>>();
        }
        groupHeaderKeys =
            List.generate(filterGroupName.length, (_) => GlobalKey());
print("responseData: $responseData");
        if (filterGroupName.isNotEmpty) {
          for (var group in filterGroupName) {
            latestTimeForAPI(group);
          }
          getMaintenanceData(filterGroupName.first, 0, 0);
        }
      });
   
    } catch (err) {
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

Future<void> getMaintenanceData(
  Map<String, dynamic>? data,
  int fetchId,
  int pageIndex,
) async {
  if (data == null || data['groupname'] == null) return;

  final String location = widget.selectedStationName;
  const String assets = 'Signal';
  final String groupName = data['groupname'];
  final String url= '$getAllAlertsMaintenance'
      '?station=$location&assets=$assets&group_name=$groupName';

  try {
    final response = await dioInstance.get(
  url
    );

    if (!mounted || activeFetchId != fetchId || currentPageIndex != pageIndex) {
      return;
    }

    setState(() {
      maintenanceData = response;
      analyticsData = response['analytics'] ?? {};
      loader1 = false;
    });
  } catch (error) {
    if (!mounted || activeFetchId != fetchId || currentPageIndex != pageIndex) {
      return;
    }
    setState(() {
      analyticsData = {};
      loader1 = false;
    });
 
  }
}


  void onSearchChanged(String query) {
    if (searchF?.isActive ?? false) searchF!.cancel();
    searchF = Timer(const Duration(milliseconds: 300), () async {
      final queries = query.trim().toLowerCase();
      List<Map<String, dynamic>> results;

      if (queries.isEmpty) {
        results = List<Map<String, dynamic>>.from(responseData as List);
      } else {
        results = (responseData as List)
            .where((grp) {
              final name = grp['groupname']?.toString().toLowerCase() ?? '';
              return name.contains(queries);
            })
            .cast<Map<String, dynamic>>()
            .toList();
      }

      setState(() {
        filterGroupName = results;
        currentPageIndex = 0;
          analyticsIndex   = 0; 
        loader1 = true;
      });

      if (results.isNotEmpty) {
        pageController?.jumpToPage(0);
        await fetchForPage(0);
      } else {
        setState(() => loader1 = false);
      }
    });
  }

  Future<void> fetchForPage(int pageIndex) async {
    final fetchId = ++activeFetchId;
    final data = filterGroupName[pageIndex];
    await getMaintenanceData(data, fetchId, pageIndex);
    if (!mounted || fetchId != activeFetchId) return;
    setState(() => loader1 = false);
  }

  void initTutorialTargets() {
    targets.clear();
    if (groupHeaderKeys.isNotEmpty) {
      targets.add(TargetFocus(
        identify: "GroupHeader",
        keyTarget: groupHeaderKeys[0],
        shape: ShapeLightFocus.RRect,
        radius: 10.0,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Swipe left or right to navigate",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Appcolors.secondary,
                    )),
                SizedBox(height: 20.h),
                SvgPicture.asset("assets/images/swipe.svg",
                    height: 150.h,
                    colorFilter:
                        ColorFilter.mode(Appcolors.secondary, BlendMode.srcIn)),
              ],
            ),
          ),
        ],
      ));
    }
  }

  void checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('hasSeenSignalTutorial') ?? false;
    if (widget.showTutorial && !hasSeenTutorial && groupHeaderKeys.isNotEmpty) {
      Future.delayed(const Duration(seconds: 1), () {
        showTutorial();
        prefs.setBool('hasSeenSignalTutorial', true);
      });
    }
  }

  void showTutorial() {
    if (targets.isEmpty) return;
    tutorial = TutorialCoachMark(
      alignSkip: Alignment.centerRight,
      targets: targets,
      colorShadow: Appcolors.primary.withOpacity(0.8),
      textSkip: "Ok",
      paddingFocus: 10,
      onClickTarget: (target) => {},
      onClickOverlay: (target) => tutorial?.finish(),
      onSkip: () => true,
      onFinish: () => {},
    );
    tutorial?.show(context: context);
  }

  Future<void> onRefresh() async {
    setState(() {
      loader = true;
      loader1 = true;
      responseData = [];
      maintenanceData = [];
      analyticsData = null;
    });
    await getSignalData();
    if (filterGroupName.isNotEmpty) {
      await getMaintenanceData(filterGroupName[analyticsIndex], 0, 0);
    }

    await Future.delayed(const Duration(seconds: 1));
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
              onTap: () => widget.onCardsChange(false),
              child: Icon(Icons.arrow_back_rounded, size: 30.r, weight: 50.r),
            ),
          ),
          search
              ? SizedBox(
                  width: 350.w,
                  child: TextField(
                    controller: searchController,
                    style: TextStyle(fontSize: 16.sp, fontFamily: 'bold'),
                    decoration: InputDecoration(
                      hintText: "Search...",
                      hintStyle: TextStyle(
                          fontSize: 16.sp,
                          fontFamily: 'bold',
                          color: Colors.grey),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(left: 10.w),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                )
              : InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: getSignalData,
                  child: UiHelper.heading2(
                      text: "Signal", color: Appcolors.primary)),
          Padding(
            padding: EdgeInsets.only(right: 85.w),
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () {
                if (search) {
                  searchController.clear();
                  setState(() => search = false);
                } else {
                  setState(() => search = true);
                }
              },
              child: Icon(
                search ? Icons.close_outlined : Icons.search_rounded,
                size: 30.r,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget buildSignalCard(int index, Map<String, dynamic> groupData) {
  final dataArray = groupData['data'] ?? [];
  if (dataArray.isEmpty || dataArray[0].keys.isEmpty) {
    return const Center(child: Text("Invalid data"));
  }

  final sortedData = dataArray[0][dataArray[0].keys.first][0];
  final rank1Signals = getRank1Signals(dataArray, List<String>.from(groupData['tag_keys'] ?? []));
debugPrint(' rank1Signals: $rank1Signals'); 
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
                      child: buildAccordions(rank1Signals),
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
        onTap: () {
          // setState(() {
          //   if (isAnyAccordionOpen) {
          //     isGraphOpen = true;
          //   } else {
          //     isGraphOpen = !isGraphOpen;
          //   }
          // });
        },
        child: Container(
          key: index < groupHeaderKeys.length ? groupHeaderKeys[index] : null,
          width: 480.w,
          height: 80.h,
          decoration: BoxDecoration(
            color: HexColor("#457b9d"),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              SizedBox(width: 10.w),
              SvgPicture.asset("assets/images/traffic.svg",
                  width: 50.w,
                  colorFilter:
                      ColorFilter.mode(Appcolors.secondary, BlendMode.srcIn)),
              SizedBox(width: 14.w),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UiHelper.heading2(
                      text: groupName.toString(), color: Appcolors.secondary),
                  Row(
                    children: [
                      Icon(Icons.access_time_filled,
                          color: Appcolors.secondary, size: 20.r),
                      SizedBox(width: 4.w),
                      UiHelper.smallText(
                          text: sortedData['reading_time']
                              .toString()
                              .replaceAll("T", "  "),
                          color: Appcolors.secondary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfoRow(dynamic sortedData) {
    return SizedBox(
      height: 50.h,
      child: Row(
        children: [
          Flexible(
            flex: 1,
            child: Row(
              children: [
                SizedBox(width: 15.w),
                UiHelper.xsmalltxt(
                  text: sortedData['device'].toString(),
                ),
                const Text(" :"),
                SizedBox(width: 10.w),
                Flexible(
                  child: UiHelper.xsmalltxt_bold(
                    text: sortedData['tagid'].toString(),
                    color: Appcolors.primary,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: UiHelper.smallText(
                    text: sortedData['description'].toString(),
                    color: Appcolors.backGroundColor,
                  ),
                ),
                SizedBox(width: 10.w),
                UiHelper.xsmalltxt_bold(
                  text: double.tryParse(sortedData['value'].toString())
                          ?.toStringAsFixed(2) ??
                      '',
                  color: Appcolors.primary,
                ),
                SizedBox(width: 10.w),
              ],
            ),
          ),
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
            fontsize: 16.sp,
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
        ...?socketSignalData[tag]
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

  List<Map<String, dynamic>> getRank1Signals(
      List<dynamic> dataList, List<String> tagKeys) {
    List<Map<String, dynamic>> rank1Signals = [];
    for (var item in dataList) {
      if (item is Map) {
        item.forEach((key, value) {
          if (tagKeys.contains(key)) {
            for (var signal in value) {
              if (signal['rank'] == "1") rank1Signals.add(signal);
            }
          }
        });
      }
    }
    return rank1Signals;
  }

  bool get isAnyAccordionOpen =>
      isRealTimeOpen ||
      isAlertsOpen ||
      isMaintenanceOpen ||
      isAnalyticsOpen ||
      isHistoryOpen;
   Widget buildAccordion({
  required bool isOpen,
  required VoidCallback onToggle,
  required String title,
  required Widget content,
  double collapsedHeight = 48,
  double expandedHeight = 278,
}) {
  return Card(
    elevation: 4.r,
    child: AnimatedContainer(
      duration: const Duration(seconds: 1),
      height: isOpen ? expandedHeight.h : collapsedHeight.h,
      curve: Curves.fastEaseInToSlowEaseOut,
      child: Stack(
        children: [
    
          InkWell(
            onTap: onToggle,
            child: Container(
              height: collapsedHeight.h,
              decoration: BoxDecoration(
                color: HexColor("#457b9d"),
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Row(
                children: [
             
                  Expanded(
                    child: Center(
                      child: UiHelper.subHeading(
                        text: title,
                        color: Appcolors.secondary,
                      ),
                    ),
                  ),
            
                  Icon(
                    isOpen
                        ? Icons.arrow_drop_up_outlined
                        : Icons.arrow_drop_down_outlined,
                    color: Appcolors.secondary,
                    size: 32.r,
                  ),
                ],
              ),
            ),
          ),

         
          if (isOpen)
            Positioned(
              top: collapsedHeight.h,
              left: 0,
              right: 0,
              child: SizedBox(
                height: (expandedHeight - collapsedHeight).h,
                child: content,
              ),
            ),
        ],
      ),
    ),
  );
}


 Widget buildAccordions(List<Map<String, dynamic>> rank1Signals) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildAccordion(
          isOpen: isRealTimeOpen,
          onToggle: () => setState(() => isRealTimeOpen = !isRealTimeOpen),
          title: "RealTime",
          collapsedHeight: 48.h,
          expandedHeight: 177.h,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 39.h,
                child: Row(
                  children: [
                    Expanded(
                        child: Center(
                            child: UiHelper.xsmalltxt_bold(
                      text: "Name",
                      color: Appcolors.primary,
                    ))),
                    Expanded(
                        child: Center(
                            child: UiHelper.xsmalltxt_bold(
                      text: "Current",
                      color: Appcolors.primary,
                    ))),
                    Expanded(
                        child: Center(
                            child: UiHelper.xsmalltxt_bold(
                      text: "Voltage",
                      color: Appcolors.primary,
                    ))),
                    Expanded(
                        flex: 2,
                        child: Center(
                            child: UiHelper.xsmalltxt_bold(
                          text: "Signal ",
                          color: Appcolors.primary,
                        ))),
                  ],
                ),
              ),
              SizedBox(
                height: 90.h, 
                child: Scrollbar(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: rank1Signals.length,
                    separatorBuilder: (_, __) => SizedBox(height: 5.h),
                    itemBuilder: (context, index) {
                      final s = rank1Signals[index];
                      final sig = s['description']
                          .toString()
                          .replaceAll("Double", "")
                          .replaceAll(":", "")
                          .trim();
                      final backColor = sig == "Yellow"
                          ? HexColor("#FF9D23")
                          : sig == "Red"
                              ? Colors.red
                              : sig == "Green"
                                  ? Colors.green
                                  : Colors.transparent;
                      final isDouble = s['tagid'].toString().contains("HHG");
                      return SizedBox(
                        height: 30.h,
                        child: Row(
                          children: [
                            Expanded(
                                child: Center(
                                    child: UiHelper.xsmalltxt(
                                        text: s['tagid'].toString()))),
                            Expanded(
                                child: Center(
                                    child: UiHelper.xsmalltxt(
                                        text: s['type'] == "Current"
                                            ? s['value'].toString()
                                            : '0'))),
                            Expanded(
                                child: Center(
                                    child: UiHelper.xsmalltxt(
                                        text: s['type'] == "Voltage"
                                            ? s['value'].toString()
                                            : '0'))),
                            Expanded(
                              flex: 2,
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4.w,
                                children: [
                                  UiHelper.xsmalltxt(
                                    text: s['description'].toString(),
                                  ),
                                  CircleAvatar(
                                      radius: 8.r,
                                      backgroundColor: backColor),
                                  if (isDouble)
                                    CircleAvatar(
                                        radius: 8.r,
                                        backgroundColor: backColor),
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
        SizedBox(height: 20.h),
        buildAccordion(
          isOpen: isAlertsOpen,
          onToggle: () => setState(() => isAlertsOpen = !isAlertsOpen),
          title: "Alerts",
          expandedHeight: 310.h,
          content: loader1
              ? Center(
                  child: LoadingAnimationWidget.stretchedDots(
                    color: Appcolors.backGroundColor,
                    size: 50.r,
                  ),
                )
              : (maintenanceData != null && maintenanceData.isNotEmpty)
                  ? Column(
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
                                  color: Appcolors.primary,
                                  fontsize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(right: 10.w),
                                child: Card(
                                  elevation: 4.r,
                                  child: Container(
                                    width: 100.w,
                                    height: 45.h,
                                    decoration: BoxDecoration(
                                      color: Appcolors.backGroundColor,
                                      borderRadius:
                                          BorderRadius.circular(7.r),
                                    ),
                                    child: InkWell(
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      // onTap: () =>
                                      //     widget.onNavigateToAlerts(2),
                                      child: Center(
                                        child: UiHelper.customText(
                                          text: "More Logs",
                                          fontFamily: 'bold',
                                          color: Appcolors.secondary,
                                          fontsize: 12.sp,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
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
                          child: Text("alerts")
                          
                          // Alertsaccordians(
                          //     maintenanceList: maintenanceData is List
                          //         ? maintenanceData
                          //         : [maintenanceData],
                          //     onShowAlertsDetails: () =>
                          //         widget.onNavigateToAlerts(2),
                          //   ),
                   
                        ),
                      ],
                    )
                  : Center(
                      child: Container(
                        width: 340.w,
                        height: 210.h,
                        decoration: BoxDecoration(
                          color: Appcolors.backGroundColor,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Text(
                            "No alerts data available",
                            style: TextStyle(
                              color: Appcolors.secondary,
                              fontSize: 17.sp,
                              fontFamily: "bold",
                            ),
                          ),
                        ),
                      ),
                    ),
        ),
        SizedBox(height: 20.h),
        buildAccordion(
          isOpen: isMaintenanceOpen,
          onToggle: () =>
              setState(() => isMaintenanceOpen = !isMaintenanceOpen),
          title: "Maintenance",
          expandedHeight: 310.h,
          content: loader1
              ? Center(
                  child: LoadingAnimationWidget.stretchedDots(
                      color: Appcolors.backGroundColor, size: 50.r),
                )
              : (maintenanceData != null && maintenanceData.isNotEmpty)
                  ? Column(
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
                                  text: "Recent ",
                                  fontFamily: 'bold',
                                  color: Appcolors.primary,
                                  fontsize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(right: 10.w),
                                child: Card(
                                  elevation: 4.r,
                                  child: Container(
                                    width: 100.w,
                                    height: 45.h,
                                    decoration: BoxDecoration(
                                        color: Appcolors.backGroundColor,
                                        borderRadius:
                                            BorderRadius.circular(7.r)),
                                    child: InkWell(
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () {
                                        // widget.maintenanceKey.currentState
                                        //     ?.setMaintenanceDataForHistory(
                                        //         maintenanceData);
                                        // widget.onNavigateToMaintenance(1);
                                      },
                                      child: Center(
                                          child: UiHelper.customText(
                                              text: "More Logs",
                                              fontFamily: 'bold',
                                              color: Appcolors.secondary,
                                              fontsize: 12.sp,
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
                          height: 200.h,
                          child: Text("maintenance")
                          //  MaintenanceAccordian(
                          //     maintenanceList: maintenanceData is List
                          //         ? maintenanceData
                          //         : (maintenanceData != null
                          //             ? [maintenanceData]
                          //             : []),
                          //     onShowMaintenanceDetails: (detail) {
                          //       widget.maintenanceKey.currentState
                          //           ?.setMaintenanceDataFromSignal(detail);
                          //       widget.onNavigateToMaintenance(2);
                          //     },
                          //   ),
                          // MaintenanceAccordian(...)
                        ),
                      ],
                    )
                  : Center(
                      child: Container(
                        width: 340.w,
                        height: 210.h,
                        decoration: BoxDecoration(
                          color: Appcolors.backGroundColor,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Text(
                            "No maintenance data available",
                            style: TextStyle(
                              color: Appcolors.secondary,
                              fontSize: 17.sp,
                              fontFamily: "bold",
                            ),
                          ),
                        ),
                      ),
                    ),
        ),
        SizedBox(height: 20.h),
        buildAccordion(
          isOpen: isAnalyticsOpen,
          onToggle: () async {
            setState(() => isAnalyticsOpen = !isAnalyticsOpen);
            if (isAnalyticsOpen) {
              // setState(() => loader1 = true);
              await getMaintenanceData(filterGroupName[analyticsIndex], 0, 0);
              if (mounted) setState(() => loader1 = false);
            }
          },
          title: "Analytics",
          expandedHeight: 310.h,
          content: loader1
              ? Center(
                  child: LoadingAnimationWidget.stretchedDots(
                    color: Appcolors.backGroundColor,
                    size: 50.r,
                  ),
                )
              : (analyticsData != null && analyticsData.isNotEmpty)
                  ? SizedBox(
                      width: 375.w,
                      height: 210.h,
                      child:  Container(
                          decoration: BoxDecoration(
                            
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12.r),
                              bottomRight: Radius.circular(12.r),
                            ),
                          ),
                          child: AnalyticsAccordian(
                            analyticsList: [analyticsData],
                            lazyLoading: loader1,
                          ),
                        ),
                      // AnalyticsAccordian(...)
                    )
                  : Container(
                      width: 375.w,
                      height: 210.h,
                      decoration: BoxDecoration(
                        color: Appcolors.backGroundColor,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Center(
                        child: Text(
                          "No analytics data.",
                          style: TextStyle(
                            color: Appcolors.secondary,
                            fontSize: 17.sp,
                            fontFamily: "bold",
                          ),
                        ),
                      ),
                    ),
        ),
        SizedBox(height: 20.h),
        buildAccordion(
          isOpen: isHistoryOpen,
          onToggle: () => setState(() => isHistoryOpen = !isHistoryOpen),
          title: "History",
          expandedHeight: 310.h,
          content: loader1
              ? Center(
                  child: LoadingAnimationWidget.stretchedDots(
                    color: Appcolors.backGroundColor,
                    size: 50.r,
                  ),
                )
              : (maintenanceData != null && maintenanceData.isNotEmpty)
                  ? SizedBox(
                      width: 340.w,
                      height: 210.h,
                      child:Container(
                          decoration: BoxDecoration(
                            
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: HistoryAccordians(
                            maintenanceList: [maintenanceData],
                            lazyLoading: loader1,
                          ),
                        ),
                      // HistoryAccordians(...)
                    )
                  : Center(
                      child: Container(
                        width: 340.w,
                        height: 210.h,
                        decoration: BoxDecoration(
                          color: Appcolors.backGroundColor,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Text(
                            "No history data available.",
                            style: TextStyle(
                              color: Appcolors.secondary,
                              fontSize: 17.sp,
                              fontFamily: "bold",
                            ),
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    if (searchController.text.isEmpty) {
      filterGroupName = (responseData as List).cast<Map<String, dynamic>>();
    } else {
      filterGroupName = (responseData as List)
          .where((grp) {
            if (grp is Map) {
              final name = grp['groupname']?.toString().toLowerCase() ?? '';
              return name.contains(searchController.text.toLowerCase());
            }
            return false;
          })
          .toList()
          .cast<Map<String, dynamic>>();
      if (filterGroupName.isNotEmpty) {
 
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
                        width: 40.h,
                        height: 40.w,
                        decoration: BoxDecoration(
                            color: style.background, shape: BoxShape.circle),
                        child: Center(
                          child: renderCompleteState
                              ? Icon(hasError ? Icons.close : Icons.check,
                                  color: style.content, size: 24.r)
                              : SizedBox(
                                  height: 24.h,
                                  width: 24.w,
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
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: 20.h,),
                buildAppBar(),
                SizedBox(
                  height: 715.h,
                  child: loader
                      ? Center(
                          child: LoadingAnimationWidget.stretchedDots(
                              color: Appcolors.backGroundColor, size: 50.r))
                      : (filterGroupName.isEmpty)
                          ? Center(
                              child: Text("No Signal Devices Found.",
                                  style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)))
                          : PageView.builder(
                              scrollDirection: Axis.horizontal,
                              controller: pageController,
                              onPageChanged: (pageIndex) async {
                                currentPageIndex = pageIndex;
                                  analyticsIndex   = pageIndex; 
                                final int fetchId = ++activeFetchId;

                                setState(() {
                                  loader1 = true;
                                  maintenanceData = null;
                                  analyticsData = null;
                                });

                                final groupData = filterGroupName[pageIndex];

                                await Future.wait([
                                  getMaintenanceData(
                                      groupData, fetchId, pageIndex),
                                ]);

                                if (!mounted ||
                                    fetchId != activeFetchId ||
                                    currentPageIndex != pageIndex) {
                                  return;
                                }

                                setState(() => loader1 = false);
                              },
                              itemCount: filterGroupName.length,
                              itemBuilder: (context, index) => buildSignalCard(
                                  index, filterGroupName[index]),
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
  const CheckMarkStyle({
    required this.loading,
    required this.success,
    required this.error,
  });
}
