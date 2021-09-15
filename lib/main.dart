import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skorboard/remoteController.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  WidgetsFlutterBinding.ensureInitialized();
  // runApp(MyApp());
  return runApp(SkorboardControler());
}
