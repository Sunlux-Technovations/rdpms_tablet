import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:rdpms_tablet/Apis/Urls.dart';
import 'package:rdpms_tablet/Apis/dioInstance.dart';
import 'package:rdpms_tablet/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Maintenance extends StatefulWidget {
  // final void Function(String?, String?, String?) onGoToHistory;

  const Maintenance({super.key,});

  @override
  State<Maintenance> createState() => _MaintenanceState();
}

class _MaintenanceState extends State<Maintenance> {
  String? selectedValues;
  String? selectedDevices;
  String? selectedAssets;
  int selectedIndex = 0;
  late List<Widget> pages;

  bool cards = false;
  bool isLoading = false;
  String? selectedDevice;

  List<dynamic> responseData = [];
  List<String> stationList = [];
  List<String> assetsList = [];
  List<String> devicesList = [];

  final TextEditingController searchStation = TextEditingController();
  final TextEditingController searchDevice = TextEditingController();

  bool isStationDataAvailable = false;
  late WebSocketChannel channel;

  @override
  void initState() {
    super.initState();
    getStationOnly();
  }

  @override
  void dispose() {
    searchStation.dispose();
    searchDevice.dispose();
    super.dispose();
  }

  Future<void> getStationOnly() async {
    try {
      final response = await dioInstance.get(getStationValues);
      if (response != null) {
        setState(() {
          stationList = List<String>.from(response);
        });
      }
    } catch (e) {
      print("Error  $e");
    }
  }

  Future<void> sendingStationValue(String selectedStation) async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await dioInstance.post(
        getMaintenanceByStationDetails,
        {'station': selectedStation},
      );

      if (response != null) {
        List<String> assetLists = [];
        const values = ['Signal', 'Pointmachine', 'Track'];

        assetLists.addAll(
          values.where((key) => response[key]?.isNotEmpty ?? false).toList(),
        );

        isStationDataAvailable = assetLists.isNotEmpty;
        if (!isStationDataAvailable) {
          MotionToast.warning(
            width: 300.w,
            height: 50.h,
            description: Text(
              "Data not available for the selected station.",
              style: TextStyle(fontFamily: "bold", fontSize: 14.sp),
            ),
            position: MotionToastPosition.top,
          ).show(context);
        }

        setState(() {
          assetsList = assetLists;
          selectedDevices = null;
          devicesList = [];
        });

        if (selectedDevice != null && !devicesList.contains(selectedDevice)) {
          devicesList.add(selectedDevice!);
        }
        if (selectedAssets != null && response[selectedAssets] != null) {
          devicesList = List<String>.from(response[selectedAssets] ?? []);
        } else {
          devicesList = [];
        }

        selectedDevice = devicesList.contains(selectedDevice)
            ? selectedDevice
            : (devicesList.isNotEmpty ? devicesList.first : null);
      }
    } catch (e) {
      print("Error : $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  bool get isGoEnabled {
    return selectedValues != null && isStationDataAvailable;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:Column(
          children: [
             Padding(
               padding:  EdgeInsets.only(top: 20.sp),
               child: Text(
                'Maintainence',
                style: TextStyle(
                  fontSize: 30.sp,
                  fontFamily: 'bold',
                ),
                           ),
             ),
            SizedBox(height: 100.h),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Card(
                elevation: 5.r,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Container(
                  width: 250.w,
                  height: 150.h,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 25.w),
                        child: SvgPicture.asset(
                          'assets/images/train-station.svg',
                          width: 45.w,
                        ),
                      ),
                      SizedBox(width: 0.w),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: 10.w,top: 5.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 15.h, right: 0.w),
                                child: UiHelper.heading2(
                                  text: 'Station',
                                  color: Appcolors.primary,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              // Move the dropdown here or adjust its position as needed
                              DropdownButtonHideUnderline(
                                child: DropdownButton2<String>(
                                  value: selectedValues,
                                  hint: UiHelper.subHeading(
                                    fontSize: 12.2.sp,
                                    text: 'Select Station',
                                    color: Appcolors.primary,
                                  ),
                                  isExpanded: true,
                                  items: stationList
                                      .map((station) => DropdownMenuItem<String>(
                                    value: station,
                                    child: Text(
                                      station,
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontFamily: 'bold',
                                        color: Appcolors.primary,
                                      ),
                                    ),
                                  ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedValues = value;
                                        selectedAssets = null;
                                        selectedDevices = null;
                                        devicesList = [];
                                      });
                                      sendingStationValue(selectedValues!);
                                    }
                                  },
                                  buttonStyleData: ButtonStyleData(
                                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                                    height: 40.h,
                                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    scrollbarTheme: ScrollbarThemeData(
                                      radius: Radius.circular(40.r),
                                      thickness: WidgetStateProperty.all(6.r),
                                      thumbVisibility: WidgetStateProperty.all(true),
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    maxHeight: 200.h,
                                  ),
                                  menuItemStyleData: MenuItemStyleData(
                                    height: 50.h,
                                  ),
                                  dropdownSearchData: DropdownSearchData(
                                    searchController: searchStation,
                                    searchInnerWidgetHeight: 50.h,
                                    searchInnerWidget: Container(
                                      height: 60.h,
                                      padding: EdgeInsets.only(
                                        top: 12.h,
                                        bottom: 4.h,
                                        right: 8.w,
                                        left: 8.w,
                                      ),
                                      child: TextFormField(
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontFamily: 'bold',
                                        ),
                                        expands: true,
                                        maxLines: null,
                                        controller: searchStation,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 8.h,
                                          ),
                                          hintText: 'Search For The Station',
                                          hintStyle: TextStyle(
                                            fontSize: 13.sp,
                                            fontFamily: 'bold',
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(10.r)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    searchMatchFn: (item, searchValue) {
                                      return item.value.toString().toLowerCase().contains(searchValue);
                                    },
                                  ),
                                  onMenuStateChange: (isOpen) {
                                    if (!isOpen) {
                                      searchStation.clear();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                  SizedBox(width: 25.h),
                  Card(
                    elevation: 5.r,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Container(
                      width: 250.w,
                      height: 150.h,
                      padding: EdgeInsets.symmetric(vertical: 10.w),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 35.w),
                            child: SvgPicture.asset(
                              'assets/images/automated-engineering.svg',
                              width: 40.w,
                            ),
                          ),
                          SizedBox(width: 0.w),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: 8.w),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                        top: 15.h, right: 5.w),
                                    child: UiHelper.heading2(
                                        text:
                                        'Asset',
                                        color: Appcolors.primary),
                                  ),
                                  SizedBox(height: 10.h),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton2<String>(
                                      isExpanded: true,
                                      hint: Padding(
                                          padding: EdgeInsets.only(
                                              left: 0.w),
                                          child: UiHelper.subHeading(
                                            fontSize: 13.sp,
                                              text: "Select Asset",
                                              color: Appcolors
                                                  .primary)),
                                      items: assetsList
                                          .map((asset) =>
                                          DropdownMenuItem<
                                              String>(
                                            value: asset,
                                            child: Text(
                                              asset,
                                              style: TextStyle(
                                                fontSize: 18.sp,
                                                fontFamily:
                                                'bold',
                                              ),
                                            ),
                                          ))
                                          .toList(),
                                      value: selectedAssets,
                                      onChanged: selectedValues !=
                                          null
                                          ? (value) {
                                        if (value != null) {
                                          setState(() {
                                            selectedAssets =
                                                value;
                                          });
                                          sendingStationValue(
                                              selectedValues!);
                                        }
                                      }
                                          : null,
                                      buttonStyleData:
                                      ButtonStyleData(
                                        padding:
                                        EdgeInsets.symmetric(
                                            horizontal: 20.w),
                                        height: 40.h,
                                        overlayColor:
                                        WidgetStateProperty.all(
                                            Colors.transparent),
                                      ),
                                      dropdownStyleData:
                                      DropdownStyleData(
                                        scrollbarTheme:
                                        ScrollbarThemeData(
                                          radius:
                                          Radius.circular(40.r),
                                          thickness:
                                          WidgetStateProperty
                                              .all(6.r),
                                          thumbVisibility:
                                          WidgetStateProperty
                                              .all(true),
                                        ),
                                        maxHeight: 200.h,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                          BorderRadius.circular(
                                              20.r),
                                        ),
                                      ),
                                      menuItemStyleData:
                                      MenuItemStyleData(
                                        height: 60.h,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 25.h),
                  Card(
                    elevation: 5.r,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Container(
                      width: 250.w,
                      height: 150.h,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 25.w),
                            child: SvgPicture.asset(
                              'assets/images/chip.svg',
                              width: 37.w,
                            ),
                          ),
                          SizedBox(width: 0.w),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: 8.w),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                      padding: EdgeInsets.only(
                                          top: 15.h, left: 45.w),
                                      child: UiHelper.heading2(
                                          text: "Device",
                                          color:
                                          Appcolors.primary)),
                                  SizedBox(height: 10.h),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton2<String>(
                                      isExpanded: true,
                                      hint: Padding(
                                          padding: EdgeInsets.only(
                                              left: 0.w),
                                          child: UiHelper.subHeading(
                                            fontSize: 13.sp,
                                              text: "Select Device",
                                              color: Appcolors
                                                  .primary)),
                                      items: devicesList
                                          .map((device) =>
                                          DropdownMenuItem<
                                              String>(
                                            value: device,
                                            child: Text(
                                              device,
                                              style: TextStyle(
                                                fontSize: 18.sp,
                                                fontFamily:
                                                'bold',
                                              ),
                                            ),
                                          ))
                                          .toList(),
                                      value: selectedDevices,
                                      onChanged: selectedValues !=
                                          null
                                          ? (value) {
                                        if (value != null) {
                                          setState(() {
                                            selectedDevices =
                                                value;
                                          });
                                        }
                                      }
                                          : null,
                                      buttonStyleData:
                                      ButtonStyleData(
                                        padding:
                                        EdgeInsets.symmetric(
                                            horizontal: 20.w),
                                        height: 40.h,
                                        overlayColor:
                                        WidgetStateProperty.all(
                                            Colors.transparent),
                                      ),
                                      dropdownStyleData:
                                      DropdownStyleData(
                                        scrollbarTheme:
                                        ScrollbarThemeData(
                                          radius:
                                          Radius.circular(40.r),
                                          thickness:
                                          WidgetStateProperty
                                              .all(6),
                                          thumbVisibility:
                                          WidgetStateProperty
                                              .all(true),
                                        ),
                                        maxHeight: 200.h,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                          BorderRadius.circular(
                                              20.r),
                                        ),
                                      ),
                                      menuItemStyleData:
                                      MenuItemStyleData(
                                        height: 40.h,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 350.h),
                ],
              ),
            ),
            Card(
              elevation: 5.r,
              color: const Color(0xFF0E4375),
              child: Container(
                width: 130.w,
                height: 70.h,
                padding:
                EdgeInsets.symmetric(horizontal: 20.w),
                child: ElevatedButton(
                  onPressed: () {
                    // if (isGoEnabled) {
                    //   widget.onGoToHistory(
                    //     selectedValues ?? '',
                    //     selectedAssets ?? '',
                    //     selectedDevices ?? '',
                    //   );
                    // } else {
                    //   MotionToast.warning(
                    //     width: 300.w,
                    //     height: 50.h,
                    //     description: Text(
                    //       "Please Select Station First.",
                    //       style: TextStyle(
                    //         fontFamily: "bold",
                    //         fontSize: 14.sp,
                    //         fontWeight: FontWeight.normal,
                    //       ),
                    //     ),
                    //     position: MotionToastPosition.top,
                    //   ).show(context);
                    // }
                  },
                  style: ElevatedButton.styleFrom(
                    shadowColor: Colors.transparent,
                    backgroundColor: const Color(0xFF0E4375),
                  ),
                  child: Text(
                    "Go",
                    style: TextStyle(
                      color: Appcolors.secondary,
                      fontSize: 20.sp,
                      fontFamily: 'bold',
                    ),
                  ),
                ),
              ),
            ),
          ],

        ),
      ),
    );
  }
}