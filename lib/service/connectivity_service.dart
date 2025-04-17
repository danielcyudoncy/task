// service/connectivity_service.dart
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityService extends GetxService {
  final _connectionChecker = InternetConnectionChecker.createInstance();
  final connectionStatus = false.obs;

  @override
  void onInit() {
    _connectionChecker.onStatusChange.listen((status) {
      connectionStatus.value = status == InternetConnectionStatus.connected;
    });
    super.onInit();
  }

  Future<bool> isConnected() async {
    return await _connectionChecker.hasConnection;
  }
}
