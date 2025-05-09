import 'package:flutter/material.dart';
import 'package:rdpms_tablet/screens/Assets/Assetspage.dart';
import 'package:rdpms_tablet/screens/assetsDetailPages/pointMachine.dart';
import 'package:rdpms_tablet/screens/assetsDetailPages/signalPage.dart';
import 'package:rdpms_tablet/screens/assetsDetailPages/track.dart';




class AssetsPageRoutes extends StatefulWidget {
  // final VoidCallback onNavigateToAlerts;
  // final VoidCallback onNavigateToMaintenance;
  // final VoidCallback onNavigateToMaintenanceSignalPage;

  // final GlobalKey<MaintenanceRoutesState> maintenanceKey;

  const AssetsPageRoutes({
    super.key,
    // required this.onNavigateToAlerts,
    // required this.onNavigateToMaintenance,
    // required this.onNavigateToMaintenanceSignalPage,
    // required this.maintenanceKey,
  });

  @override
  AssetsPageRoutesState createState() => AssetsPageRoutesState();
}

class AssetsPageRoutesState extends State<AssetsPageRoutes> {
  int currentPage = 0;
  String? selectedStation;

  void updatePage(int newPage, String station) {
    if (newPage < 0) newPage = 0;
    if (newPage > 3) newPage = 3;
    setState(() {
      selectedStation = station;
      currentPage = newPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Assetspage(
        onStationSelected: (station) {
          setState(() {
            selectedStation = station;
          });
        },
        onNavigateToAsset: (index) {
          if (selectedStation == null) {
          } else {
            updatePage(index + 1, selectedStation!);
          }
        },
      ),
      if (selectedStation != null) ...[
        Signalpage(
          key: ValueKey(selectedStation),
          selectedStationName: selectedStation!,
          onCardsChange: (bool _) {
            setState(() {
              currentPage = 0;
            });
          },
          // onNavigateToAlerts: (int index) {
          //   widget.onNavigateToMaintenanceSignalPage();
          // },
          // onNavigateToMaintenance: (int index) {
          //   widget.onNavigateToMaintenance();
          // },
          // maintenanceKey: widget.maintenanceKey,
          showTutorial: currentPage == 1,
        ),
        Pointmachine(
          key: ValueKey(selectedStation),
          // selectedStationName: selectedStation!,
          // onCardsChange: (bool _) {
          //   setState(() {
          //     currentPage = 0;
          //   });
          // },
          // onNavigateToAlerts: (int index) {
          //   widget.onNavigateToMaintenanceSignalPage();
          // },
          // showTutorial: currentPage == 1,
          // onNavigateToAsset: (int index) {
          //   widget.onNavigateToAlerts();
          // },
          // onNavigateToMaintenance: (int index) {
          //   widget.onNavigateToMaintenance();
          // },
          // maintenanceKey: widget.maintenanceKey,
        ),
        Trackpage(
          key: ValueKey(selectedStation),
          selectedStationName: selectedStation!,
          onCardsChange: (bool _) {
            setState(() {
              currentPage = 0;
            });
          },
          // onNavigateToMaintenanceForTrack: (int index) {
          //   widget.onNavigateToMaintenance();
          // },
          // onNavigateToAlertsForTrack: (int index) {
          //   widget.onNavigateToAlerts();
          // },
          // maintenanceKey: widget.maintenanceKey,
        ),
      ] else
        const Center(child: Text("Please select a station")),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentPage,
        children: pages,
      ),
    );
  }
}
