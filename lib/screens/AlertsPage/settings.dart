import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:rdpms_tablet/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/appColors.dart';

class SettingPage extends StatefulWidget {
  final Function onChange;
  const SettingPage({super.key, required this.onChange});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  Map<String, dynamic> jsonData = {};

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    final jsonString = await rootBundle.loadString('assets/instruction.json');
    jsonData = jsonDecode(jsonString);

    if (jsonData.isNotEmpty) {
      _tabController = TabController(length: jsonData.keys.length, vsync: this);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<bool> _onSwipeBack() async {
    Navigator.pop(context);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      
      
      
      
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 70.h,
          leading: Padding(
            padding: EdgeInsets.only(left: 10.w, top: 30.h),
            child: IconButton(
              icon: Icon(Icons.arrow_back, size: 30.r),
              onPressed: () => widget.onChange(false),
            ),
          ),
          title: Padding(
            padding: EdgeInsets.only(left: 350.w, top: 30.h),
            child: UiHelper.heading2(
              text: "Settings",
              color: Appcolors.primary,
            ),
          ),

          
          bottom: _tabController != null
              ? PreferredSize(
                  preferredSize: Size.fromHeight(88.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 30.h),      
                      TabBar(
                        controller: _tabController,
                        labelColor: Appcolors.primary,
                        unselectedLabelColor: Colors.grey,
                        tabs: jsonData.keys
                            .map((title) => Tab(text: title))
                            .toList(),
                      ),
                    ],
                  ),
                )
              : PreferredSize(
                  preferredSize: Size.fromHeight(20.h),
                  child: const SizedBox.shrink(),
                ),
        ),

        
        body: _tabController == null
            ? const SizedBox.shrink()
            : TabBarView(
                controller: _tabController,
                children: jsonData.keys.map((key) {
                  final containers =
                      Map<String, String>.from(jsonData[key] as Map);

                  return Padding(
                    padding: EdgeInsets.only(top: 25.h),
                    child: ListView.builder(
                      itemCount: containers.length,
                      itemBuilder: (context, index) {
                        final title = containers.keys.elementAt(index);
                        final value = containers[title]!;

                        return Container(
                          width: 300.w,
                          height: 150.h,
                          margin: EdgeInsets.symmetric(
                              vertical: 10.h, horizontal: 20.w),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            elevation: 4.r,
                            child: Padding(
                              padding: EdgeInsets.all(16.r),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Center(
                                    child: UiHelper.heading2(
                                      text: title,
                                      color: Appcolors.primary,
                                    ),
                                  ),
                                  Center(
                                    child: UiHelper.normal(text: value),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}
