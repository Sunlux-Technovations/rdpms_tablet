import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rdpms_tablet/screens/AlertsPage/Alerts.dart';
import 'package:rdpms_tablet/screens/Assets/Assetspage.dart';
import 'package:rdpms_tablet/screens/Homepage/Homepage.dart';
import 'package:rdpms_tablet/screens/MaintenancePage/Maintenance.dart';
import 'package:rdpms_tablet/screens/ProfilePage/Profilepage.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';
import 'package:sidebarx/sidebarx.dart';

bool alertFunction = false;

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final SidebarXController controller = SidebarXController(selectedIndex: 0, extended: true);
  Timer? autoCloseTimer;
  bool showNotification = false;
  final double notifIconTop = 16.h;
  final double notifIconRight = 16.w;
  final double notifIconSize = 25.r;
  final double notifIconPadding = 8.r;
  late final double notificationPanelHeight;
  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    notificationPanelHeight = 400.h;
    screens = [
      Homepage(alertUpdates: alertFunction),
      const Assetspage(),
      const Alerts(),
      const Maintenance(),
      const Profilepage(),
    ];
      scheduleAutoClose();
    controller.addListener(() {
      setState(() {});
      if (controller.extended) {
        scheduleAutoClose();
      } else {
        autoCloseTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    autoCloseTimer?.cancel();
    super.dispose();
  }

  void scheduleAutoClose() {
    autoCloseTimer?.cancel();
    autoCloseTimer = Timer(const Duration(seconds: 3), () {
      controller.setExtended(false);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final double panelTop = notifIconTop + notifIconSize + notifIconPadding * 2 + 4.h;
    int currentIndex = controller.selectedIndex < screens.length ? controller.selectedIndex : 0;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (!controller.extended) {
                    controller.setExtended(true);
                    scheduleAutoClose();
                  }
                },
                child: SidebarX(
                  showToggleButton: false,
                  controller: controller,
                  theme: SidebarXTheme(
                    margin: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: Appcolors.backGroundColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10.r),
                        bottomLeft: Radius.circular(10.r),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 30.r),
                      ],
                    ),
                    hoverColor: Appcolors.buttonColor,
                    textStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    selectedTextStyle: const TextStyle(color: Colors.white),
                    hoverTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    itemTextPadding: EdgeInsets.only(left: 30.w),
                    selectedItemTextPadding: EdgeInsets.only(left: 30.w),
                    itemDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Appcolors.backGroundColor),
                    ),
                    selectedItemDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(),
                    ),
                    iconTheme: IconThemeData(color: Colors.white.withOpacity(0.7), size: 18.r),
                    selectedIconTheme: IconThemeData(color: Colors.white, size: 18.r),
                  ),
                  extendedTheme: SidebarXTheme(width: 150.w, decoration: BoxDecoration(color: Appcolors.backGroundColor)),
                  headerBuilder: (context, extended) {
                    return Column(
                      children: [
                        InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () => controller.selectIndex(0),
                          child: SizedBox(
                            height: 100.h,
                            child: Padding(
                              padding: EdgeInsets.all(18.r),
                              child: Image.asset('assets/images/trail_logo.png',),
                            ),
                          ),
                        ),
                        SizedBox(height: 180.h),
                      ],
                    );
                  },
items: [
  SidebarXItem(
    label: 'Home',
    iconBuilder: (bool selected, bool hovered) => Icon(
      Icons.home,
      size: 25.r,                                   
      color: selected
          ? Colors.white
          : Colors.white.withOpacity(0.7),          
    ),
  ),
  SidebarXItem(
    label: 'Assets',
    iconBuilder: (bool selected, bool hovered) => Icon(
      Icons.account_tree,
      size: 25.r,
      color: selected
          ? Colors.white
          : Colors.white.withOpacity(0.7),
    ),
  ),
  SidebarXItem(
    label: 'Alerts',
    iconBuilder: (bool selected, bool hovered) => Icon(
      Icons.notification_add,
      size: 25.r,
      color: selected
          ? Colors.white
          : Colors.white.withOpacity(0.7),
    ),
  ),
  SidebarXItem(
    label: 'Maintenance',
    iconBuilder: (bool selected, bool hovered) => Icon(
      Icons.engineering,
      size: 25.r,
      color: selected
          ? Colors.white
          : Colors.white.withOpacity(0.7),
    ),
  ),
]
,

                  footerBuilder: (context, extended) {
                    if (!extended) {
                      return GestureDetector(
                        onTap: () {
                          controller.selectIndex(4);
                          
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.w),
                          child: Icon(Icons.account_circle_outlined, color: Colors.white.withOpacity(0.7), size: 25.r),
                        ),
                      );
                    }
                return GestureDetector(
  onTap: () => controller.selectIndex(4),
  child: SizedBox(
    width: 150.w, 
    child: Padding(
      padding: EdgeInsets.only(left: 10.w, top: 8.h, bottom: 10.h),
      child: Row(
        children: [
          Icon(Icons.account_circle_outlined, color:Colors.white.withOpacity(0.7), size: 25.r),
          SizedBox(width: 25.w),
          Expanded(
            child: Text(
              "Profile",
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12.sp),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    ),
  ),
);
  },
                ),
              ),
              Expanded(child: IndexedStack(index: currentIndex, children: screens)),
            ],
          ),
          Positioned(
            top: notifIconTop,
            right: notifIconRight,
            child: GestureDetector(
              onTap: () => setState(() => showNotification = !showNotification),
              child: Container(
                padding: EdgeInsets.all(notifIconPadding),
                decoration: BoxDecoration(
                  color: showNotification ? Colors.blue : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4.r)],
                ),
                child: Icon(Icons.notifications_active_outlined, size: notifIconSize, color: showNotification ? Colors.white : Colors.black),
              ),
            ),
          ),
          
Positioned(
  top: panelTop,
  right: notifIconRight,
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.linear,
    width: 300.w,
    height: showNotification ? notificationPanelHeight : 0,
    decoration: BoxDecoration(
        color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      boxShadow: [
        BoxShadow(color: Colors.black26, blurRadius: 8.r),
      ],
    ),
    child: OverflowBox(
      maxHeight: notificationPanelHeight,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        opacity: showNotification ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Padding(
  padding: EdgeInsets.all(12.r),
  child: Column(
    mainAxisSize: MainAxisSize.max,
    children: [
      Text(
        'Today\'s Alerts',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      Expanded(
        child: Center(
          child: Text(
            'No new alerts.',
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
      ),
    ],
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
}
