import 'package:flutter/material.dart';
import 'package:rdpms_tablet/screens/AlertsPage/Alerts.dart';
import 'package:rdpms_tablet/screens/AlertsPage/settings.dart';


class AlertsRoutes extends StatefulWidget {
  // final VoidCallback onNavigateToAlerts;
  const AlertsRoutes({super.key,
  //  required this.onNavigateToAlerts
   
   });

  @override
  AlertsRoutesState createState() => AlertsRoutesState();
}

class AlertsRoutesState extends State<AlertsRoutes> {
  int currentPage = 0;
  Map<String, dynamic>? selectedAlertData;
  String? selectedTagId;
  final GlobalKey<AlertsHistoryState> _alertsHistoryKey =
      GlobalKey<AlertsHistoryState>();
  void updatePage(int newPage) {
    const totalPages = 2;
    if (newPage < 0) newPage = 0;
    if (newPage >= totalPages) newPage = totalPages - 1;
    // if (currentPage == 0 && newPage != 0) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     _alertsHistoryKey.currentState?.resetDropdowns();
    //   });
    // }
    setState(() {
      currentPage = newPage;
    });
  }

  void popInner() {
    if (currentPage == 1) {
      updatePage(0);
    }
  }

  // void resetAlertsDropdowns() {
  //   _alertsHistoryKey.currentState?.resetDropdowns();
  // }

  void moveToHistory([Map<String, dynamic>? alertData]) {
    setState(() {
      currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      AlertsHistory(
        key: _alertsHistoryKey,
        onGoToSettings: () {
          updatePage(1);
        },
      ),
      SettingPage(
        onChange: (visible) {
          updatePage(0);
        },
      ),
    ];

    int index = currentPage;
    if (index < 0 || index >= pages.length) {
      index = 0;
    }

    return IndexedStack(
      index: index,
      children: pages,
    );
  }
}
