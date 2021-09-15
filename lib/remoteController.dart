import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:skorboard/apiCalls.dart';
import 'package:skorboard/my_globals.dart';
import 'package:new_virtual_keyboard/virtual_keyboard.dart';
import 'device.dart';
import 'package:http/http.dart' as http;
import 'package:network_tools/network_tools.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SkorboardControler extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkorBoard',
      home: Scaffold(
        backgroundColor: Color(0XFF2e2e2e),
        body: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  bool _keypadShown = false;
  bool _arrowsShown = false;
  bool _deviceShown = false;
  bool _menuShown = false;
  bool _showKeyboard = false;
  bool shiftEnabled = false;
  bool showAvailable = false;
  bool isConnected = false;
  bool searching = false;
  // = new ProgressDialog(context);
  List<Remote>? devices = [];
  List<String>? devicesIp = [];
  //  List<Remote, String>? deviceStamps = [];
  Future<Remote>? _responseFuture;
  late AnimationController controller;
  MyGlobalData myData = MyGlobalData();
  //.......
  final int timerTimeout = 60;
  final keyDelay = 200;
  //........
  bool connectedToRemote = false;
  final String authUrl = 'http://';
  final String hostPort = ':8050';
  String remoteIp = "";
  String restString = "";
  String deviceName = 'No Device Connected !';
  //.......
  ApiCalls s = ApiCalls();

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        setState(() {});
      });
    controller.repeat(reverse: true);
    super.initState();
    devices = [];
    devicesIp = [];
    isConnected = false;
    searching = false;
    _arrowsShown = true;
    _menuShown = false;
    connectedToRemote = false;
    _showKeyboard = false;
    shiftEnabled = false;
    showAvailable = false;
    // devices?.add(Remote(name: "RPI1", service: "Test", status: "Disabled"));
    // devicesIp?.add('192.168.1.11');
  }

  Future<bool?> connectTV(BuildContext context) async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());

      if (connectivityResult == ConnectivityResult.wifi) {
        // I am connected to a wifi network.
        setState(() {
          searching = true;
          isConnected = false;
          devices?.clear();
          devicesIp?.clear();
          //......
          //......
          //test
          // devices
          //     ?.add(Remote(name: "RPI1", service: "Test", status: "Disabled"));
          // devicesIp?.add('192.168.1.11');
        });

        _showMyDialog('Searching Devices !', context, 15,
            onComplete: closeDialog);
        await discoverer(onComplete: complete).then((value) {
          // print("Remote host found :" + value.toString());
          if (value != null) {
            print("Remote host found :" + value.toString());
          }
          return true;
        });
        return true;
      } else if (connectivityResult == ConnectivityResult.mobile) {
        _showMyDialog(
            'Unable to search PI using Mobile Data !\nPlease connect to Wifi Network',
            context,
            2,
            onComplete: closeDialog);
        setState(() {
          _keypadShown = false;
          _arrowsShown = true;
          _menuShown = false;
          _deviceShown = false;
          showAvailable = false;
        });
      } else {
        setState(() {
          _keypadShown = false;
          _arrowsShown = true;
          _menuShown = false;
          _deviceShown = false;
          showAvailable = false;
        });
        _showMyDialog('Wifi not connected !!!', context, 2,
            onComplete: closeDialog);
      }
    } catch (e) {
      print("Connectivity Error" + e.toString());
    }
    // print("this is the token to save somewere ${tv.token}");
  }

  bool getConnectionStatus() {
    return connectedToRemote;
  }

  void setRemoteStatus(bool val) {
    setState(() {
      connectedToRemote = val;
    });
  }

  Future? complete(String data) {
    setState(() {
      isConnected = true;
      searching = false;
    });
    if (devices?.length == 0) {
      _showMyDialog('No Device Found !', context, 3, onComplete: closeDialog);
      setState(() {
        _keypadShown = false;
        _arrowsShown = true;
        _menuShown = false;
        _deviceShown = false;
      });
    } else {
      // print('Devices found Complete :' + data);
      _showMyDialog('Search Complete !', context, 3, onComplete: closeDialog);
    }
    //  return true;
  }

  Future? closeDialog(BuildContext context, int duration) {
    // print('Closing Dialog');
    Timer(Duration(seconds: duration), () {
      // print("Closing Dialog Now");
      Navigator.of(context).pop();
    });
    setState(() {});
    //  return true;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              // crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: FractionalOffset.bottomCenter,
                  // child: Padding(
                  // padding: EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    deviceName,
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  // ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            getNumPadWidget(),
            getArrowsWidget(),
            getMenuWidget(context),
            Visibility(
              visible: _deviceShown,
              child: Expanded(
                child: Center(
                  child: devices?.length == 0
                      ? Center(
                          child: CircularProgressIndicator(
                            value: controller.value,
                            semanticsLabel: 'progress indicator',
                          ),
                        )
                      : showAvailable
                          ? getAvailableListView(context)
                          : getListView(context),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _showKeyboard ? showVirtualKeyboard() : getBottomImageRow(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Visibility getArrowsWidget() {
    return Visibility(
      visible: _arrowsShown,
      child: Expanded(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: SkorboardButton(
                onPressed: () async {
                  setState(() {
                    _menuShown = true;
                    _arrowsShown = false;
                    _keypadShown = false;
                    _deviceShown = false;
                  });
                },
                child: const Text(
                  "MENU",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: SkorboardButton(
                child: Text(
                  "INPUT",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _showKeyboard ? Colors.blue : Colors.white54),
                ),
                onPressed: () async {
                  _showKeyboard = !_showKeyboard;
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: SkorboardButton(
                child: const Text(
                  "BACK",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54),
                ),
                onPressed: () async {
                  if (connectedToRemote) {
                    var apiReq = restString + s.btnBack;
                    await sendApiRequest(apiReq, context);
                  }
                },
              ),
            ),
            // Align(
            //   alignment: Alignment.bottomRight,
            //   child: SkorboardButton(
            //     child: Text(
            //       "EXIT",
            //       style: TextStyle(
            //           fontSize: 11,
            //           fontWeight: FontWeight.bold,
            //           color: Colors.white54),
            //     ),
            //     onPressed: () async {
            //       if (connectedToRemote) {
            //         var apiReq = restString + s.btnExit;
            //         await sendApiRequest(apiReq, context);
            //       }
            //     },
            //   ),
            // ),
            Align(
              alignment: Alignment.center,
              child: SkorboardButton(
                child: const Text(
                  "OK",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                onPressed: () async {
                  // await tv.sendKey(KEY_CODES.KEY_ENTER);
                  if (connectedToRemote) {
                    var apiReq = restString + s.btnOk;
                    await sendApiRequest(apiReq, context);
                  }
                },
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.6),
              child: Container(
                alignment: const Alignment(0, -0.5),
                child: SkorboardButton(
                  borderRadius: 10,
                  child: const Icon(Icons.arrow_drop_up,
                      size: 50, color: Colors.white),
                  onPressed: () async {
                    if (connectedToRemote) {
                      var apiReq = restString + s.btnUp;
                      await sendApiRequest(apiReq, context);
                    }
                  },
                ),
              ),
              //   ],
              // ),
            ),
            Align(
              alignment: const Alignment(0, 0.5),
              child: SkorboardButton(
                borderRadius: 10,
                child: const Icon(Icons.arrow_drop_down,
                    size: 50, color: Colors.white),
                onPressed: () async {
                  if (connectedToRemote) {
                    var apiReq = restString + s.btnDown;
                    await sendApiRequest(apiReq, context);
                  }
                },
              ),
            ),
            Align(
              alignment: const Alignment(0.7, 0),
              child: SkorboardButton(
                borderRadius: 10,
                child: const Icon(Icons.arrow_right,
                    size: 50, color: Colors.white),
                onPressed: () async {
                  if (connectedToRemote) {
                    var apiReq = restString + s.btnRight;
                    await sendApiRequest(apiReq, context);
                  }
                },
              ),
            ),
            Align(
              alignment: const Alignment(-0.7, 0),
              child: SkorboardButton(
                borderRadius: 10,
                child:
                    const Icon(Icons.arrow_left, size: 50, color: Colors.white),
                onPressed: () async {
                  if (connectedToRemote) {
                    var apiReq = restString + s.btnLegt;
                    await sendApiRequest(apiReq, context);
                  }
                  // await tv.sendKey(KEY_CODES.KEY_LEFT);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Visibility getNumPadWidget() {
    return Visibility(
      visible: _keypadShown,
      child: Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SkorboardButton(
                  child: const Text(
                    "1",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70),
                  ),
                  onPressed: () async {},
                ),
                SkorboardButton(
                  child: const Text(
                    "2",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70),
                  ),
                  onPressed: () async {},
                ),
                SkorboardButton(
                  child: const Text(
                    "3",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70),
                  ),
                  onPressed: () async {},
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SkorboardButton(
                  child: const Text(
                    "4",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70),
                  ),
                  onPressed: () async {},
                ),
                SkorboardButton(
                  child: const Text(
                    "5",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70),
                  ),
                  onPressed: () async {},
                ),
                SkorboardButton(
                  child: const Text(
                    "6",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70),
                  ),
                  onPressed: () async {},
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SkorboardButton(
                  child: const Text(
                    "7",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70),
                  ),
                  onPressed: () async {},
                ),
                SkorboardButton(
                  child: const Text(
                    "8",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70),
                  ),
                  onPressed: () async {},
                ),
                SkorboardButton(
                  child: const Text(
                    "9",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70),
                  ),
                  onPressed: () async {},
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SkorboardButton(
                  child: const Text(
                    "0",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70),
                  ),
                  onPressed: () async {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Row getBottomImageRow() {
    return Row(
      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Image.asset('assets/logoApp.png'),
        ),
      ],
    );
  }

  Widget showVirtualKeyboard() {
    return Row(
      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Container(
            // Keyboard is transparent
            color: Colors.grey[800],
            child: VirtualKeyboard(
                // Default height is 300
                height: 350,
                // Default is black
                textColor: Colors.white,
                // Default 14
                fontSize: 20,
                // [A-Z, 0-9]
                type: VirtualKeyboardType.Alphanumeric,
                // Callback for key press event
                onKeyPress: _onKeyPress),
          ),
        ),
      ],
    );
  }

  _onKeyPress(VirtualKeyboardKey key) async {
    String text;
    if (connectedToRemote) {
      if (key.keyType == VirtualKeyboardKeyType.String) {
        text =
            (shiftEnabled ? (key.capsText.toString()) : (key.text.toString()));
        print('alphaNumeric Pressed :' + text);
        if (text == ".") {
          text = "dot";
        } else if (text == "/") {
          text = "fSlash";
        }
        var apiReq = restString + s.btnVkey + text;
        // print('Sending :' + apiReq);
        await sendApiRequest(apiReq, context);
      } else if (key.keyType == VirtualKeyboardKeyType.Action) {
        switch (key.action) {
          case VirtualKeyboardKeyAction.Backspace:
            // print('BackSpace pressed');
            var apiReq = restString + s.btnBack;
            await sendApiRequest(apiReq, context);
            break;
          case VirtualKeyboardKeyAction.Return:
            // print('Enter pressed');
            // text = text + '\n';
            var apiReq = restString + s.btnOk;
            await sendApiRequest(apiReq, context);
            break;
          case VirtualKeyboardKeyAction.Space:
            // print('Space pressed');
            var apiReq = restString + s.btnSpace;
            await sendApiRequest(apiReq, context);
            break;
          case VirtualKeyboardKeyAction.Shift:
            setState(() {
              shiftEnabled = !shiftEnabled;
            });
            break;
          default:
        }
      }
    }
  }

  Widget getMenuWidget(BuildContext context) {
    return Visibility(
      visible: _menuShown,
      child: Expanded(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomLeft,
              child: SkorboardButton(
                child: const Text(
                  "BACK",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54),
                ),
                onPressed: () async {
                  setState(() {
                    _menuShown = false;
                    _arrowsShown = true;
                    _keypadShown = false;
                    _deviceShown = false;
                  });
                },
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.settings_remote, color: Colors.white),
                  trailing: const Icon(Icons.keyboard_arrow_right),
                  title: const Text(
                    'Show Available Devices',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  onTap: () async {
                    setState(() {
                      _keypadShown = false;
                      _arrowsShown = false;
                      _menuShown = false;
                      if (devices?.length != 0) {
                        _deviceShown = true;
                        showAvailable = true;
                      } else {
                        _keypadShown = false;
                        _arrowsShown = true;
                        _menuShown = false;
                        _deviceShown = false;
                        showAvailable = false;
                        _showMyDialog('No Available Devices', context, 3,
                            onComplete: closeDialog);
                      }
                    });
                  },
                ),
                const Divider(
                  thickness: 2,
                ),
                ListTile(
                  leading:
                      const Icon(Icons.settings_remote, color: Colors.white),
                  trailing: const Icon(Icons.keyboard_arrow_right),
                  title: const Text(
                    'Search Devices',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  onTap: () async {
                    setState(() {
                      _keypadShown = false;
                      _arrowsShown = false;
                      _menuShown = false;
                      _deviceShown = true;
                      showAvailable = false;
                    });
                    if (!searching) {
                      // && !isConnected) {
                      await connectTV(context);
                    }
                  },
                ),
                const Divider(
                  thickness: 2,
                ),
                ListTile(
                  leading: const Icon(
                    Icons.account_box_outlined,
                    color: Colors.white,
                  ),
                  trailing: const Icon(Icons.keyboard_arrow_right),
                  title: const Text(
                    'About',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  onTap: () async {
                    setState(() {
                      _keypadShown = false;
                      _arrowsShown = true;
                      _menuShown = false;
                      _deviceShown = false;
                    });
                    String msg = 'Skorboard Remote';
                    String contents =
                        'Controller for Skorboard v1\nGet Skorboard @\nfantronics.com';
                    String tradeMark = '@SKORBOARD';
                    _showAboutDialog(msg, contents, tradeMark, context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget getAvailableListView(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: devices?.length,
        itemBuilder: (BuildContext context, int index) {
          return Center(
            child: ListTile(
              leading: const Icon(Icons.settings_remote),
              trailing: const Icon(Icons.keyboard_arrow_right),
              title: Text(
                '${devices?[index].name} (${devices?[index].service})',
                style: const TextStyle(fontSize: 18),
              ),
              onTap: () async {
                //Go to the next screen with Navigator.push
                var remote = devices?[index];
                restString = devicesIp?[index] ?? "";
                // print('ip in rest str is :' + restString);
                await myData.setHostIp(restString);
                setState(() {
                  restString = 'http://' + restString + hostPort;
                  connectedToRemote = true;
                  deviceName = (remote?.service ?? "");
                });

                // print('Complete Rest Api String is :' + restString);
                await myData.setCurrentRemote(remote);
                setState(() {
                  _keypadShown = false;
                  _arrowsShown = true;
                  _deviceShown = false;
                });
              },
            ),
          );
        });
  }

  Widget getListView(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: devices?.length,
        itemBuilder: (BuildContext context, int index) {
          return Center(
            child: ListTile(
              leading: const Icon(Icons.settings_remote),
              trailing: const Icon(Icons.keyboard_arrow_right),
              title: Text(
                '${devices?[index].name} (${devices?[index].service})',
                style: const TextStyle(fontSize: 18),
              ),
              onTap: () async {
                //Go to the next screen with Navigator.push
                var remote = devices?[index];
                restString = devicesIp?[index] ?? "";
                // print('ip in rest str is :' + restString);
                await myData.setHostIp(restString);
                setState(() {
                  restString = 'http://' + restString + hostPort;
                  connectedToRemote = true;
                  deviceName = (remote?.service ?? "");
                });

                // print('Complete Rest Api String is :' + restString);
                await myData.setCurrentRemote(remote);
                setState(() {
                  _keypadShown = false;
                  _arrowsShown = true;
                  _deviceShown = false;
                });
              },
            ),
          );
        });
  }

  Future<void> _showAboutDialog(String msg, String contents, String tradeMark,
      BuildContext context) async {
    return showDialog<void>(
      context: context,
      // barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[500],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(msg),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  contents,
                  style: const TextStyle(fontSize: 18),
                ),
                // Text(
                //   tradeMark,
                //   style: TextStyle(fontSize: 15),
                // ),
              ],
            ),
          ),
          // shape: CircleBorder(),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMyDialog(String msg, BuildContext context, int duration,
      {required Function onComplete}) async {
    // onComplete(context, duration);
    return showDialog<void>(
      context: context,
      // barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(msg),
          actions: const <Widget>[],
        );
      },
    );
  }

  //...........
  Future discoverer({required Function onComplete}) async {
    var completer = Completer();
    var deviceHold;
    String hostInfo = "";
    String wifiIPa = "";
    final info = NetworkInfo();
    await info.getWifiIP().then((value) {
      // Don't forget to cancel the stream when not in use.
      // print('new ip Address :' + value.toString());
      wifiIPa = value.toString();
      String ip = wifiIPa;
      print("Wifi IP Address is :" + ip);
      final String subnet = ip.substring(0, ip.lastIndexOf('.'));
      final stream = HostScanner.discover(subnet,
          firstSubnet: 1, lastSubnet: 50, progressCallback: (progress) {
        // print('Progress for host discovery : $progress');
      });
      stream.listen((host) async {
        print('Found device: ${host}');
        // hostInfo = host.ip;
        if (host.ip.toString().substring(
                    host.ip.toString().length - 2, host.ip.toString().length) ==
                ".1" ||
            wifiIPa == host.ip) {
          print('Router address found :' + host.ip);
        } else {
          // deviceHold =
          try {
            await getAuth(host.ip.toString()).then((value) {
              if (value.name == 'skorboard') {
                print('Found RPI remote Device');

                setState(() {
                  devices?.add(value);
                  devicesIp?.add(host.ip);
                });
                hostInfo = host.ip;
                deviceHold = value;
                return value;
              } else {
                // print('no RPI found on get auth');
                deviceHold = value;
                return value;
              }
            }).onError((error, stackTrace) {
              print("error in getauth :" + error.toString());
              return deviceHold;
              // hostInfo = "";
              // onError(error.toString());
            });
          } catch (e) {
            print("error in getauth Try Catch :" + e.toString());
          }
        }
        // }
      }, onDone: () {
        // return val;
        // completer.complete(device);
        onComplete(hostInfo);
        print('Scan completed');
        completer.complete(deviceHold);
      });
    }).onError((error, stackTrace) {
      _showMyDialog('Wifi search error !\nContact Developers', context, 3,
          onComplete: closeDialog);
      print('Wifi Connection Error :' + error.toString());
      completer.completeError('Wifi Connection Error :' + error.toString());
    });
    return completer.future;
  }

  Future<Remote> getAuth(String hostIp) async {
    // var completer = new Completer();

    var data;
    String urlStr = authUrl + hostIp + hostPort;
    String authStr = '/auth/get';
    var url = Uri.parse(urlStr + authStr);
    print('Posting :' + urlStr + authStr);
    try {
      var response = await http.get(url).timeout(const Duration(seconds: 3),
          onTimeout: () {
        throw TimeoutException(
            'The connection has timed out, Please try again!');
      });
      print('response :' + response.toString());
      if (response.statusCode == 200) {
        // print('Found response 200 Body :' + response.body.toString());
        // If the server did return a 201 CREATED response,
        // then parse the JSON.
        if (response.body.length > 0) {
          data = Remote.fromJson(jsonDecode(response.body));
        }

        return data;
      } else if (response.statusCode == 500) {
        print('timeout');
      }
    } on SocketException catch (e) {
      print('Socket Exception');
      // return data;
      // throw Exception('Failed to Communucate.');
      // return data;
    }
    return data;
  }

  Future sendApiRequest(String apiUrl, BuildContext context) async {
    var url = Uri.parse(apiUrl);
    // print('Posting :' + apiUrl);
    try {
      await http.get(url).then((value) {
        if (value.statusCode == 200) {
          // If the server did return a 201 CREATED response,
          // then parse the JSON.
          if (value.body.length > 0) {
            //Check api response. if rpi responds the key press. else it is disconnected.
            //then sho disconnect message
            // print('Found response 200 Body :' + value.body.toString());
          }

          //return data;
        }
      }).onError((error, stackTrace) {
        print('Http Error Sending Key :' + error.toString());
        _showMyDialog(error.toString(), context, 3, onComplete: closeDialog);
      });
    } on SocketException {
      print('Socket Exception');
    }
    //return data;
    return Future.delayed(Duration(milliseconds: keyDelay));
  }
}

class SkorboardButton extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final Color? color;
  const SkorboardButton(
      {Key? key,
      this.child,
      this.borderRadius = 30,
      this.color,
      this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        color: const Color(0XFF2e2e2e),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          colors: [Color(0XFF1c1c1c), Color(0XFF383838)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0XFF1c1c1c),
            offset: Offset(5.0, 5.0),
            blurRadius: 10.0,
          ),
          BoxShadow(
            color: Color(0XFF404040),
            offset: Offset(-5.0, -5.0),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
            // shape: BoxShape.circle,
            borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                colors: [Color(0XFF303030), Color(0XFF1a1a1a)]),
          ),
          child: MaterialButton(
            color: color,
            minWidth: 0,
            onPressed: onPressed,
            shape: const CircleBorder(),
            child: child,
          ),
        ),
      ),
    );
  }
}
