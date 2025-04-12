import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';


class AppDevices {
  AppDevices._();

  static void hideKeyboard(BuildContext context){
    FocusScope.of(context).requestFocus(FocusNode());
  }

  static bool isLandscapeOrientation(BuildContext context){
    final viewInset = View.of(context).viewInsets;
    return viewInset.bottom == 0;
  }

  static bool getAppTheme(){
    return Theme.of(Get.context!).brightness == Brightness.dark;
  }

  static bool isPotraitOrientation(BuildContext context){
    final viewInset = View.of(context).viewInsets;
    return viewInset.bottom != 0;
  }

  static double getStatusBarHeight(){
    return MediaQuery.of(Get.context!).padding.top;
  }

  static double getScreenHeight(){
    return MediaQuery.of(Get.context!).size.height;
  }

  static double getScreenWidth(){
    return MediaQuery.of(Get.context!).size.width;
  }

  static Future<bool> hasInternetConnection() async{
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch(_){
      return false;
    }
  }

  static bool isIOS(){
    return Platform.isIOS;
  }

  static bool isAndroid(){
    return Platform.isAndroid;
  }

  static void launchUrl(String url) async{
    if (await canLaunchUrlString(url)){
      await launchUrlString(url);
    }else{
      throw 'Could not launch $url';
    }
  }
}