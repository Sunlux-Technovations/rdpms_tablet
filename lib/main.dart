import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:rdpms_tablet/screens/Splashscreen/SplashScreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    
  ]);
  
  
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  runApp(const MyApp());
}
class GlobalData {
  static final GlobalData _instance = GlobalData._internal();
  String userName = "";
  String name = "";
  String department = "";
  List<dynamic> array1 = [];
  var LiveAlerts;
  List stations = [];

  factory GlobalData() => _instance;
  GlobalData._internal();
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      
      designSize: const Size(1024, 768),  
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        title: 'Voyant',
        debugShowCheckedModeBanner: false,
   theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const LandscapeLockedWrapper(
          child: Splashscreen(),
        ),
      ),
    );
  }
}


class LandscapeLockedWrapper extends StatelessWidget {
  final Widget child;
  
  const LandscapeLockedWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

