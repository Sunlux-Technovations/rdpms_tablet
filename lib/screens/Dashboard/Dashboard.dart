

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:badges/badges.dart' as badges;
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';          
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:rdpms_tablet/screens/AlertsPage/alertsPageRoutes.dart';
import 'package:rdpms_tablet/screens/Assets/AssetsPagesRoute.dart';
import 'package:rdpms_tablet/screens/constants/socketTopic.dart';
import 'package:rdpms_tablet/screens/utils/image_picker_util.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:rdpms_tablet/screens/Homepage/Homepage.dart' as hp;
import 'package:rdpms_tablet/Apis/Urls.dart';
import 'package:rdpms_tablet/Apis/dioInstance.dart';

import 'package:rdpms_tablet/main.dart';
import 'package:rdpms_tablet/screens/AlertsPage/Alerts.dart';
import 'package:rdpms_tablet/screens/Homepage/Homepage.dart';
import 'package:rdpms_tablet/screens/Loginscreen/Loginscreen.dart';
import 'package:rdpms_tablet/screens/MaintenancePage/Maintenance.dart';
import 'package:rdpms_tablet/screens/ProfilePage/Profilepage.dart';

import 'package:rdpms_tablet/widgets/appColors.dart';


  


bool alertFunction = false;

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => DashboardState();
}

class DashboardState extends State<Dashboard>with SingleTickerProviderStateMixin  {
     late final AnimationController refreshController;
  final SidebarXController controller =
      SidebarXController(selectedIndex: 0, extended: true);
  final dio = Dio();
 final GlobalKey<AlertsRoutesState> _alertsKey =
      GlobalKey<AlertsRoutesState>();
  Timer? autoCloseTimer;
  bool showNotification = false;
  bool showProfilePanel = false;
  bool isLoadingAlerts = false;

  
  final double notifIconTop = 16.h;
  final double notifIconRight = 16.w;
  final double notifIconSize = 25.r;
  final double notifIconPadding = 8.r;
  late final double notificationPanelHeight;

  final bool hasError = false;
  File? selectedImage;
  late final List<Widget> screens;
  List<dynamic> notifyData = [];
  IO.Socket? socket;
  late NotificationSettings fireBaseSettings;


final hp.CheckMarkStyle _checkMarkStyle = const hp.CheckMarkStyle(
  loading : hp.CheckMarkColors(content: Colors.white, background: Colors.blueAccent),
  success : hp.CheckMarkColors(content: Colors.black, background: Colors.greenAccent),
  error   : hp.CheckMarkColors(content: Colors.black, background: Colors.redAccent),
);
bool renderCompleteState = false;


  @override
  void initState() {
    super.initState();
    try {
      refreshController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      );
    } catch (e) {

      debugPrint('Error for refreshController: $e');
      
      rethrow;
    }
    notificationPanelHeight = 416.h;
    screens = [
      Homepage(alertUpdates: alertFunction),
      const AssetsPageRoutes(
        //       key: _assetsKey,
        // onNavigateToAlerts: navigateToAlerts,
        // onNavigateToMaintenance: navigateToMaintenance,
        // onNavigateToMaintenanceSignalPage: navigateToAlerts,
        // maintenanceKey: _maintenanceKey,
      ),
       AlertsRoutes(
        key: _alertsKey,
        // onNavigateToAlerts: navigateToAlerts,
      ),
      const Maintenance(),
      const Profilepage(),
    ];  
    socketDataAlerts();
    controller.addListener(() {
      if (controller.extended) {
        startAutoCloseTimer();
      } else {
        autoCloseTimer?.cancel();
      }
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => startAutoCloseTimer());
  }

  @override
  void dispose() {
        refreshController.dispose();
    controller.dispose();
    autoCloseTimer?.cancel();
       
    socket?.dispose();
    super.dispose();
  }
  Future<void> checkForInitialMessage() async {
    RemoteMessage? initial =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) setState(() => showNotification = true);
  }

  void setUpFcm() async {
    fireBaseSettings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );
    FirebaseMessaging.instance.subscribeToTopic(GlobalData().userName);
    FirebaseMessaging.onMessageOpenedApp.listen((_) {
      setState(() => showNotification = true);
    });
  }
void socketDataAlerts() {

  if (socket != null) {
    socket!.disconnect();
    socket!.dispose();
  }
  

  socket = IO.io(dashboardpagesocket, {
    'transports': ['websocket'],
    'autoConnect': false,
  });
  
  socket!.connect();

  socket!.onConnect((_) {
    print("Connected...");
    socket!.emit('subscribe', {
      'topic': dashboardalertsTopic,
      'username': GlobalData().userName,
    });
  });

  socket!.on('update', (data) {
    print("Received data: $data");
    if (!mounted) return;

    try {
      var msg = (data is Map<String, dynamic> && data['message'] is String)
          ? jsonDecode(data['message'])
          : data['message'];

      var list = msg?['data'] ?? [];

      var rowData = <dynamic>[];
      for (var e in list) {
        if (e['key'] == 'alert' && e['row_data'] is Iterable) {
          rowData.addAll(e['row_data']);
        }
      }

      setState(() {
 
        List<dynamic> newAlerts = rowData.where((a) =>
            !notifyData.any((existing) => existing['id'] == a['id'])).toList();

        if (newAlerts.isNotEmpty) {
          notifyData = [...newAlerts, ...notifyData];
          notifyData.sort((a, b) =>
              DateTime.parse(b['alert_time']).compareTo(DateTime.parse(a['alert_time'])));
        }
      });
    } catch (e) {
      print('Socket parse error: $e');
    }
  });

  socket!.onDisconnect((_) => print('Socket disconnected'));
  socket!.onError((err) => print('Socket error: $err'));
}


Future<void> onRefresh() async {

  setState(() {
    isLoadingAlerts = true;
  });
  
  int previousCount = notifyData.length;

  try {

    if (socket == null || !socket!.connected) {
      socketDataAlerts();
    } else {
   
      socket!.emit('subscribe', {
        'topic': dashboardalertsTopic,
        'username': GlobalData().userName,
      });
      

      socket!.emit('fetchAlerts', {
        'username': GlobalData().userName,
      });
    }


    await Future.delayed(const Duration(seconds: 2));
    
    
    if (notifyData.length == previousCount) {
      MotionToast.warning(
        width: 300.w,
        height: 50.h,
        description: Text(
          "No new alerts available.",
          style: TextStyle(fontFamily: "bold", fontSize: 14.sp),
        ),
        position: MotionToastPosition.top,
      ).show(context);
    }
  } catch (e) {
    print('Error during refresh: $e');

    MotionToast.error(
      width: 300.w,
      height: 50.h,
      description: Text(
        "Failed to refresh alerts. Please try again.",
        style: TextStyle(fontFamily: "bold", fontSize: 14.sp),
      ),
      position: MotionToastPosition.top,
    ).show(context);
  } finally {
   
    setState(() {
      isLoadingAlerts = false;
    });
  }
}
  Future<void> getAcknowledge(int index) async {
    try {
      await dioInstance.post(getUpdateAlert, {
        'alertid': notifyData[index]['id'],
      });
    } catch (_) {}
  }

  
  void startAutoCloseTimer() {
    autoCloseTimer?.cancel();
    autoCloseTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        controller.setExtended(false);
        setState(() {});
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final double panelTop =
        notifIconTop + notifIconSize + notifIconPadding * 3.3 + 4.h;
    int currentIndex =
        controller.selectedIndex < screens.length ? controller.selectedIndex : 0;
    return Scaffold(
      body: GestureDetector(
          behavior: HitTestBehavior.translucent,
  onTap: () {
    if (showNotification || showProfilePanel) {
      setState(() {
        showNotification = false;
        showProfilePanel = false;
      });
    }
  },
        child: Stack(
          children: [   
            Row(
              children: [
                buildSidebar(),
                Expanded(
                  child: IndexedStack(index: currentIndex, children: screens),
                ),
              ],
            ),
            Positioned(
              top: 25.h,
              right: notifIconRight,
              child: GestureDetector(
                onTap: () => setState(() => showNotification = !showNotification),
                child: badges.Badge(
                  showBadge: notifyData.isNotEmpty,
                  badgeContent: Text(
                    '${notifyData.length}',
                    style:
                        TextStyle(color: Colors.white, fontSize: 10.sp),
                  ),
                  position: badges.BadgePosition.topEnd(top: -5, end: -5),
                  badgeStyle: badges.BadgeStyle(
                    badgeColor: Colors.red,
                    padding: EdgeInsets.all(5.r),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(notifIconPadding),
                    decoration: BoxDecoration(
                      color: showNotification
                          ? Appcolors.backGroundColor
                          : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4.r)
                      ],
                    ),
                    child: Icon(Icons.notifications_active_outlined,
                        size: notifIconSize,
                        color:
                            showNotification ? Colors.white : Colors.black),
                  ),
                ),
              ),
            ),
            buildNotificationPanel(panelTop),
            buildProfilePanel(),
          ],
        ),
      ),
    );
  }
  Widget buildSidebar() {
    return GestureDetector(
      onTap: () {
        if (!controller.extended) {
          controller.setExtended(true);
          startAutoCloseTimer();
          setState(() {});
        }
      },
      behavior: HitTestBehavior.translucent,
      child: SidebarX(
        showToggleButton: false,
        controller: controller,
        theme: SidebarXTheme(
          width: 70.w,
          margin: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: Appcolors.backGroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 30)
            ],
          ),
          hoverColor: Appcolors.buttonColor,
          textStyle: TextStyle(color: Colors.white, fontSize: 14.sp),
          selectedTextStyle: TextStyle(
              color: Colors.blue, fontSize: 14.sp, fontWeight: FontWeight.w600),
          itemDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Appcolors.backGroundColor)),
          selectedItemDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Appcolors.backGroundColor,
          ),
          iconTheme: IconThemeData(color: Colors.white, size: 18.r),
          selectedIconTheme: IconThemeData(color: Colors.blue, size: 18.r),
        ),
        extendedTheme:
            SidebarXTheme(width: 150.w, decoration: BoxDecoration(color: Appcolors.backGroundColor)),
     headerBuilder: (context, extended) => Padding(
  padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
  child: Column(
    children: [
GestureDetector(
  onTap: () {
    controller.selectIndex(0);
    if (!controller.extended) {
      controller.setExtended(true);
      startAutoCloseTimer();
    }
    setState(() {});
  },
  child: Image.asset('assets/images/trail_logo.png', height: 60.h),
),
      if (extended) ...[
        SizedBox(height: 12.h),
         Text('VOYANT RDPMS',
            style: TextStyle(color: Colors.white, fontSize: 14.sp, fontFamily: 'bold')),
      ],
      SizedBox(height: 180.h), 
    ],
  ),
),
        items: [
          buildItem(Icons.home, 0, 'Home'),
          buildItem(Icons.account_tree, 1, 'Assets'),
          buildItem(Icons.notification_add, 2, 'Alerts'),
          buildItem(Icons.engineering, 3, 'Maintenance'),
        ],
        footerBuilder: (context, extended) => GestureDetector(
          onTap: () => setState(() => showProfilePanel = !showProfilePanel),
          child: Padding(
            padding:
                EdgeInsets.only(left: extended ? 15.w : 23.w, top: 8.h, bottom: 10.h),
            child: Row(children: [
              Icon(Icons.account_circle_outlined,
                  color: showProfilePanel ? Colors.blue : Colors.white,
                  size: 25.r),
                  SizedBox(width: 12.w,),
              if (extended)
                Expanded(
                    child: Text('Profile',
                        style: TextStyle(
                            color: showProfilePanel ? Colors.blue : Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600)))
            ]),
          ),
        ),
      ),
    );
  }
 SidebarXItem buildItem(IconData icon, int idx, String label) {
  return SidebarXItem(
    label: label,
    iconBuilder: (sel, __) => Padding(
      padding: EdgeInsets.only(right: 8.w), 
      child: Icon(
        icon,
        size: 25.r,
        color: sel ? Colors.blue : Colors.white,
      ),
    ),
    onTap: () {
      controller.selectIndex(idx);
      if (!controller.extended) {
        controller.setExtended(true);
        startAutoCloseTimer();
        setState(() {});
      }
    },
  );
}Widget buildNotificationPanel(double panelTop) {
  return Positioned(
    top: panelTop,
    right: notifIconRight,
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear,
        width: 300.w,
        height: showNotification
            ? min(
                MediaQuery.of(context).size.height * 0.6,
                MediaQuery.of(context).size.height - panelTop - 20,
              )
            : 0,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8.r)],
        ),
        clipBehavior: Clip.antiAlias,
        child: showNotification
            ? SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12.r),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Today's Alerts",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        RotationTransition(
                            turns: refreshController,
                            child: IconButton(
                              icon: Icon(Icons.refresh, size: 24.r),
                              onPressed: () {
                                refreshController.forward(from: 0);
                                onRefresh();
                              },
                            ),
                          ),
                      
                        ],
                      ),
                    ),
                    Divider(height: 1.h, color: Colors.grey),
                    SizedBox(
                      height: min(
                              MediaQuery.of(context).size.height * 0.6,
                              MediaQuery.of(context).size.height -
                                  panelTop -
                                  20) -
                          60.h,
                      child: CustomRefreshIndicator(
                        onRefresh: onRefresh,
                        triggerMode: IndicatorTriggerMode.anywhere,
                        durations:
                            const RefreshIndicatorDurations(completeDuration: Duration(seconds: 1)),
                        onStateChanged: (change) {
                          if (change.didChange(to: IndicatorState.complete)) {
                            renderCompleteState = true;
                          } else if (change.didChange(to: IndicatorState.idle)) {
                            renderCompleteState = false;
                          }
                        },
                        builder: (context, child, controller) {
                          final hp.CheckMarkColors style =
                              renderCompleteState
                                  ? (hasError
                                      ? _checkMarkStyle.error
                                      : _checkMarkStyle.success)
                                  : _checkMarkStyle.loading;
                          return Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              ClipRect(
                                child: AnimatedBuilder(
                                  animation: controller,
                                  builder: (context, _) => Transform.translate(
                                    offset: Offset(0, controller.value * 40),
                                    child: child,
                                  ),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: controller,
                                builder: (context, _) => Opacity(
                                  opacity:
                                      controller.isLoading ? 1.0 : controller.value.clamp(0.0, 1.0),
                                  child: Container(
                                    height: 80.h,
                                    alignment: Alignment.center,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      curve: Curves.linear,
                                      width: 40.w,
                                      height: 40.h,
                                      decoration: BoxDecoration(
                                        color: style.background,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: renderCompleteState
                                            ? Icon(
                                                hasError ? Icons.close : Icons.check,
                                                color: style.content,
                                                size: 24.r,
                                              )
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
                              ),
                            ],
                          );
                        },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SizedBox(
                              height: constraints.maxHeight,
                              child: notifyData.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No alerts for today.',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      physics: const ClampingScrollPhysics(),
                                      padding: EdgeInsets.only(bottom: 24.h, top: 8.h),
                                      itemCount: notifyData.length,
                                      separatorBuilder: (_, __) =>
                                          Divider(thickness: 1, color: Colors.grey),
                                      itemBuilder: (context, idx) {
                                        return SwipeActionCell(
                                          key: ObjectKey(notifyData[idx]),
                                          trailingActions: [
                                            SwipeAction(
                                              performsFirstActionWithFullSwipe: true,
                                              title: 'Acknowledge',
                                              style: TextStyle(
                                                fontFamily: 'bold',
                                                color: Appcolors.secondary,
                                              ),
                                              onTap: (handler) async {
                                                handler(true);
                                                if (idx < 0 || idx >= notifyData.length) {
                                                  return;
                                                }
                                                await getAcknowledge(idx);
                                                Future.delayed(
                                                  const Duration(milliseconds: 300),
                                                  () {
                                                    if (idx >= 0 && idx < notifyData.length) {
                                                      setState(() => notifyData.removeAt(idx));
                                                      MotionToast.success(
                                                        width: 300.w,
                                                        height: 50.h,
                                                        description: Text(
                                                          "Notification Acknowledged",
                                                          style: TextStyle(
                                                              fontFamily: "bold", fontSize: 14.sp),
                                                        ),
                                                        position: MotionToastPosition.top,
                                                      ).show(context);
                                                    }
                                                  },
                                                );
                                              },
                                              color: Colors.green,
                                            ),
                                          ],
                                          child: SizedBox(
                                            height: 80.h,
                                            child: InkWell(
                                              onTap: () => showAlertDialog(idx),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 8.h, horizontal: 10.w),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            '${notifyData[idx]['topic'].split("_")[4]} ${notifyData[idx]['alerttype']}',
                                                            style: TextStyle(
                                                              fontSize: 16.sp,
                                                              fontWeight: FontWeight.bold,
                                                              color: Appcolors.primary,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        Text(
                                                          DateFormat('HH:mm:ss').format(
                                                            DateTime.parse(
                                                                notifyData[idx]['alert_time']),
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 12.sp,
                                                            fontWeight: FontWeight.w600,
                                                            color: Appcolors.primary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 4.h),
                                                    Text(
                                                      notifyData[idx]['message']
                                                                  .toString()
                                                                  .length >
                                                              40
                                                          ? '${notifyData[idx]['message'].toString().substring(0, 40)}...'
                                                          : notifyData[idx]['message'],
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(fontSize: 12.sp),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    ),
  );
}

void showAlertDialog(int index) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => AlertDialog(
      backgroundColor: Appcolors.backGroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 320.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Alerts',
                      style: TextStyle(
                          color: Appcolors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp)),
                          SizedBox(width: 40.w,),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: notifyData[index]['alerttype'] == 'Critical'
                          ? HexColor('#9d0208')
                          : HexColor('#ff7c00'),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(notifyData[index]['alerttype'],
                        style:
                            TextStyle(color: Colors.white, fontSize: 12.sp)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Appcolors.secondary,
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),
             Divider(height: 1.h),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(notifyData[index]['topic'].split('_')[4],
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14.sp,color: Colors.white)),
                  Text(
                      DateFormat('dd-MM-yyyy HH:mm:ss').format(
                          DateTime.parse(notifyData[index]['alert_time'])),
                      style: TextStyle(fontSize: 11.sp,color: Colors.white)),
                ],
              ),
            ),
             Divider(height: 1.h),
            
           ConstrainedBox( 
              constraints: BoxConstraints(maxHeight: 200.h),
              child: SingleChildScrollView(
                child: Text(notifyData[index]['message'],
                    style: TextStyle(fontSize: 12.sp, color: Colors.white)),
              ),
            ),
             Divider(height: 1.h),
            
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r))),
                onPressed: () async {
                  await getAcknowledge(index);
                  setState(() => notifyData.removeAt(index));
                  Navigator.pop(context);
                  MotionToast.success(
                          description: const Text('Notification Acknowledged'),
                          position: MotionToastPosition.top)
                      .show(context);
                },
                child:  Text('Acknowledge',style: TextStyle(color: Colors.white,fontSize: 11.sp),),
              ),
            )
          ],
        ),
      ),
    ),
  );
}
  Widget buildAlertTile(int idx) {
    final alert = notifyData[idx];
    return InkWell(
      onTap: () => showAlertDialog(idx),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${alert['topic'].split("_")[4]} ${alert['alerttype']}',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold,color: Colors.white)),
          SizedBox(height: 4.h),
          Text(
            alert['message'].toString().length > 40
                ? '${alert['message'].toString().substring(0, 40)}...'
                : alert['message'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.sp,color: Colors.white),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd-MM-yyyy HH:mm:ss')
                    .format(DateTime.parse(alert['alert_time'])),
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
              GestureDetector(
                onTap: () async {
                  await getAcknowledge(idx);
                  setState(() => notifyData.removeAt(idx));
                  MotionToast.success(
                    description: const Text('Notification Acknowledged'),
                    position: MotionToastPosition.top,
                  ).show(context);
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6.r)),
                  child:  Text('Acknowledge',
                      style: TextStyle(color: Colors.white, fontSize: 11.sp)),
                ),
              )
            ],
          )
        ]),
      ),
    );
  }
  Widget buildProfilePanel() {
  return Positioned(
    left: controller.extended ? 180.w : 100.w,
    bottom: notifIconTop,
    child: GestureDetector(
        behavior: HitTestBehavior.translucent,
      onTap: () {},
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear,
        opacity: showProfilePanel ? 1 : 0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
                  curve: Curves.linear,
          width: 300.w,
          height: showProfilePanel ? 500.h : 0, 
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8.r)],
          ),
          child:showProfilePanel
      ? SingleChildScrollView(
          padding: EdgeInsets.all(16.r),
          child: Column(
            children: [
              const Text('My Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 40.h),
              buildProfileAvatar(),
              SizedBox(height: 40.h),
              Container(
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  color: Appcolors.backGroundColor,),
                child:  Text('Voyant RDPMS',style: TextStyle(color: Colors.white,fontFamily: "regular",fontSize: 14.sp),),
              ),
              SizedBox(height: 100.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appcolors.backGroundColor,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('No')),
                        TextButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const Loginscreen()),
                                  (_) => false);
                              FirebaseMessaging.instance.unsubscribeFromTopic(
                                  GlobalData().userName);
                            },
                            child: const Text('Yes')),
                      ],
                    ),
                  );
                },
                child: const Text('Sign Out',style: TextStyle(color: Colors.white),),
              )
            ],
          ),
        )
              : null,
        ),
      ),
    ),
  );
}
  Widget buildProfileAvatar() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProfileImagePreview(imageFile: selectedImage)),
      ),
      child: Hero(
        tag: 'profileImageHero',
        child: Stack(alignment: Alignment.bottomRight, children: [
          CircleAvatar(
            radius: 60.r,
            backgroundColor: Colors.transparent,
            backgroundImage: selectedImage != null
                ? FileImage(selectedImage!)
                : const AssetImage('assets/images/trail_logo.png')
                    as ImageProvider,
          ),
          Positioned(
            bottom: 0,
            right: 4.w,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16.r),
                onTap: () async {
                  final img = await ImagePickerUtil.pickImage(context);
                  if (img != null) setState(() => selectedImage = img);
                },
                child: CircleAvatar(
                  radius: 16.r,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.camera_alt, size: 16.r, color: Colors.black),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
class ProfileImagePreview extends StatelessWidget {
  final File? imageFile;
  const ProfileImagePreview({super.key, required this.imageFile});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Center(
          child: Hero(
              tag: 'profileImageHero',
              child: imageFile != null
                  ? Image.file(imageFile!)
                  : Image.asset('assets/images/trail_logo.png')),
       ),
        Positioned(
          top: 24.h,
          left: 16.w,
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24.r),
                onTap: () => Navigator.pop(context),
                child: CircleAvatar(
                  radius: 24.r,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.close, size: 24.r, color: Colors.black),
                ),
              )),
        )
      ]),
    );
  }
}
class CheckMarkColors {
  final Color content;
  final Color background;
  const CheckMarkColors({
    required this.content,
    required this.background,
  });
}
class CheckMarkStyle {
  final CheckMarkColors loading;
  final CheckMarkColors success;
  final CheckMarkColors error;
  const CheckMarkStyle({
    required this.loading,
    required this.success,
    required this.error,
  });
}