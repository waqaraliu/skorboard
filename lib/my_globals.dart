import 'package:skorboard/device.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyGlobalData {
  Future<void> setCurrentRemote(Remote? data) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('name', (data?.name ?? ""));
    prefs.setString('service', data?.service ?? "");
    prefs.setString('status', data?.status ?? "");
  }

  Future<void> setHostIp(String ip) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('hostIp', ip);
  }

  Future<String?> getHostIp(String ip) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var data = prefs.getString('hostIp');
    return data;
  }

  Future<Remote>? getSavedRemote() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    Remote remote;
    String remoteName, remoteService, remoteStatus;

    remoteName = pref.getString('counter') ?? "";
    remoteService = pref.getString('service') ?? "";
    remoteStatus = pref.getString('status') ?? "";
    remote =
        Remote(name: remoteName, service: remoteService, status: remoteStatus);

    return remote;
  }

  Future removeRemote(Remote data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Remove String
    prefs.remove(data.name);
    prefs.remove(data.service);
    prefs.remove(data.status);
  }
}
