import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:railway/Apis/Urls.dart';
// import 'package:railway/Apis/dioInstance.dart';
// import 'package:railway/widgets/UiHelper.dart';
import 'package:rdpms_tablet/widgets/UiHelper.dart';
// import 'package:railway/widgets/appColors.dart';

class Maintenancehistory extends StatefulWidget {
  const Maintenancehistory({super.key});

  @override
  State<Maintenancehistory> createState() => _MaintenancehistoryState();
}

class _MaintenancehistoryState extends State<Maintenancehistory> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
            clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: 60.h,
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 0.w),
                        child: IconButton(
                          onPressed: (){},
                          icon: Icon(Icons.arrow_back_rounded, size: 30.r),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 5.w),
                        child: UiHelper.customHeadings(
                          text: "Maintenance history",
                        ),
                      ),
                    ],
                  ),
                ),
                  ],
        ),
      ),
    );
  }
}
