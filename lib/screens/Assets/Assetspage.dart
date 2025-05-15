import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rdpms_tablet/Apis/Urls.dart';
import 'package:rdpms_tablet/Apis/dioInstance.dart';
import 'package:rdpms_tablet/main.dart';
import 'package:rdpms_tablet/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';

class Assetspage extends StatefulWidget {
  final Function(String) onStationSelected;
  final Function(int) onNavigateToAsset;
  const Assetspage({
    super.key,
    required this.onStationSelected,
    required this.onNavigateToAsset,
  });

  @override
  State<Assetspage> createState() => _AssetspageState();
}

class _AssetspageState extends State<Assetspage> {
  List<dynamic> locationAlertData = [];
  final int _selectedIndex = 0;
  bool assetsCards = false;
  String? selectedStation;
  late List<Widget> pages;
  String? selectedValue;
  List<dynamic> stationResponse = [];
  bool isLoading = true;
  final TextEditingController dropDownSearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    getAlertLocation();
    getSensorData();
  }

  Future<void> getSensorData() async {
    try {
      var responsedData = await dioInstance.get(getStationValues);
      if (mounted) {
        setState(() {
          stationResponse = responsedData;
          isLoading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> getAlertLocation() async {
    try {
      var responseLoc = await dioInstance.get('$totalAlertsByStation?station=$selectedStation');
      if (mounted) {
        setState(() {
          locationAlertData = responseLoc;
        });
      }
    } catch (err) {}
  }

int getAlertCount(String targetDevice) {
  for (final alert in locationAlertData) {
    final deviceName = alert['device']?.toString().toLowerCase();
    if (deviceName == targetDevice.toLowerCase()) {
      return int.tryParse(alert['count'].toString()) ?? 0;
    }
  }
  return 0;
}


  Widget buildAssetCard({
    required String assetName,
    required String assetSvg,
    required int alertCount,
    required int navigateIndex,
  }) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () {
        if (selectedStation != null) {
          widget.onNavigateToAsset(navigateIndex);
        } else {
          UiHelper.showErrorToast(context, "Please Select Location First");
        }
      },
      child: Card(
        elevation: 3.r,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Container(
          width: 220.w,
          height: 220.w,
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                assetSvg,
                width: 90.r,
              ),
              SizedBox(height: 20.h),
              UiHelper.heading2(text: assetName, color: Appcolors.primary),
              SizedBox(height: 10.h),
              UiHelper.subHeading(text: "Alerts : $alertCount", color: Appcolors.primary),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 30.h),
            UiHelper.heading2(text: "Assets", color: Appcolors.primary),
            SizedBox(height: 20.h),
            Card(
              elevation: 4.r,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              child: Container(
                width: 400.w,
                height: 90.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      "assets/images/stations.svg",
                      width: 52.w,
                    ),
                    SizedBox(width: 8.w),
                    UiHelper.button_large(text: "Location"),
                    SizedBox(width: 10.w),
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        hint: UiHelper.smallText_bold(text: "Select Location"),
                        items: GlobalData().stations.map((el) {
                          return DropdownMenuItem<String>(
                            value: el ?? "",
                            child: Text(
                              el ?? "",
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontFamily: "bold",
                              ),
                            ),
                          );
                        }).toList(),
                        value: selectedValue,
                        onChanged: (value) {
                          setState(() {
                            selectedValue = value;
                            selectedStation = selectedValue;
                            getAlertLocation();
                          });
                          widget.onStationSelected(value!);
                        },
                        buttonStyleData: ButtonStyleData(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          height: 50.h,
                          width: 210.w,
                          elevation: 2,
                          overlayColor: WidgetStateProperty.all(Colors.transparent),
                        ),
                        dropdownStyleData: DropdownStyleData(
                          padding: EdgeInsets.symmetric(horizontal: 19.w),
                          width: 200.w,
                          maxHeight: 290.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                        ),
                        menuItemStyleData: MenuItemStyleData(
                          height: 44.h,
                        ),
                        dropdownSearchData: DropdownSearchData(
                          searchController: dropDownSearch,
                          searchInnerWidgetHeight: 50.h,
                          searchInnerWidget: Container(
                            height: 50.h,
                            padding: EdgeInsets.all(8.w),
                            child: TextFormField(
                              expands: true,
                              maxLines: null,
                              controller: dropDownSearch,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                                hintText: 'Search Station...',
                                hintStyle: TextStyle(fontSize: 13.sp, fontFamily: 'bold'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ),
                          ),
                          searchMatchFn: (item, searchValue) {
                            return item.value.toString().toLowerCase().contains(searchValue.toLowerCase());
                          },
                        ),
                        onMenuStateChange: (isOpen) {
                          if (!isOpen) {
                            dropDownSearch.clear();
                          }
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height: 90.h),
            Wrap(
              spacing: 30.w,
              runSpacing: 30.h,
              alignment: WrapAlignment.center,
              children: [
                buildAssetCard(
                  assetName: "Signal",
                  assetSvg: "assets/images/trafficlights.svg",
                  alertCount: getAlertCount('Signal'),
                  navigateIndex: 0,
                ),
                buildAssetCard(
                  assetName: "Point Machine",
                  assetSvg: "assets/images/sensor (2).svg",
                  alertCount: getAlertCount('Pointmachine'),
                  navigateIndex: 1,
                ),
                buildAssetCard(
                  assetName: "Track",
                  assetSvg: "assets/images/switch.svg",
                  alertCount: getAlertCount('Track'),
                  navigateIndex: 2,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
