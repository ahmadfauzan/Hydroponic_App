import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_esp32/res/custom_colors.dart';
import 'package:firebase_esp32/screens/sign_in_screen.dart';
import 'package:firebase_esp32/utils/authentication.dart';
import 'package:intl/intl.dart';
import 'package:water_bottle/water_bottle.dart';

class Control extends StatefulWidget {
  @override
  State<Control> createState() => _ControlState();
}

class _ControlState extends State<Control> {
  final fb = FirebaseDatabase.instance;
  late DatabaseReference _dbref;
  late User _user;
  late Map sensor;
  late Map data;
  final timeFormat = DateFormat("HH:mm");
  var _hour, _minute, _time;
  bool isAutoLed = false;
  bool isStateLed = false;
  bool _isSigningOut = false;
  TextEditingController tdsInput = TextEditingController();
  TextEditingController phInput = TextEditingController();
  TextEditingController timeOn = TextEditingController();
  TextEditingController timeOff = TextEditingController();

  final chemistryBottleRef = GlobalKey<SphericalBottleState>();
  var waterLevel = 0.1;

  Route _routeToSignInScreen() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => SignInScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(-1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  _readSensor() {
    _dbref.child('sensor/').onValue.listen((event) {
      final data = event.snapshot;
      setState(() {
        sensor = {
          'tds': data.child('tds').value,
          // 'ph': data.child('ph').value,
          'temp': data.child('temp').value,
          'waterLevel': data.child('distance').value,
          'led': data.child('led').value,
        };
      });
    });
  }

  _readData() {
    _dbref.child('data/').onValue.listen((event) {
      final snapshot = event.snapshot;
      setState(() {
        data = {
          'age': snapshot.child('age').value,
          'autoLed': snapshot.child('autoLed').value,
          'stateLed': snapshot.child('stateLed').value,
          'autoWaterLevel': snapshot.child('autoWaterLevel').value,
          'limitTds': snapshot.child('limitTds').value,
          // 'limitPh': snapshot.child('limitPh').value,
          'dateTime': snapshot.child('dateTime').value,
          'timeLedOn': snapshot.child('timeLedOn').value,
          'timeLedOff': snapshot.child('timeLedOff').value,
        };
      });
    });
  }

  _updateAutoLed() {
    if (isAutoLed) {
      _dbref.child("data").update({
        "stateLed": false,
      });
    }
    _dbref.child("data").update({
      "autoLed": isAutoLed,
    });
  }

  _updateLed() {
    if (data['stateLed']) {
      _dbref.child("sensor").update({
        "led": true,
      });
      _dbref.child("data").update({
        "autoLed": false,
      });
      isAutoLed = false;
    } else {
      _dbref.child("sensor").update({
        "led": false,
      });
    }

    _dbref.child("data").update({
      "stateLed": data['stateLed'],
    });
  }

  _updateWaterLevel() {
    _dbref.child("data").update({
      "autoWaterLevel": data['autoWaterLevel'],
    });
  }

  _updateTds() {
    _dbref.child("data").update({
      "limitTds": int.parse(tdsInput.text),
    });
  }

  // _updatePh() {
  //   _dbref.child("data").update({
  //     "limitPh": int.parse(phInput.text),
  //   });
  // }

  _updateTimer() {
    _dbref.child("data").update({
      "timeLedOn": timeOn.text,
      "timeLedOff": timeOff.text,
    });
    print(timeOn.text);
  }

  @override
  void initState() {
    sensor = {
      'tds': 0,
      // 'ph': 0,
      'temp': 0,
      'waterLevel': 0,
      'led': false,
    };
    data = {
      'age': 0,
      'autoLed': false,
      'stateLed': false,
      'autoWaterLevel': false,
      'limitTds': 0,
      // 'limitPh': 0,
      'dateTime': '',
      'timeLedOn': '',
      'timeLedOff': '',
    };
    _dbref = FirebaseDatabase.instance.ref();
    _readSensor();
    _readData();
    timeOn.text = "";
    super.initState();
  }

  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      elevation: 5,
                      margin: EdgeInsets.only(
                        top: 5,
                        left: 5,
                        right: 5,
                        bottom: 10,
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width *
                            0.90, // between 0 and 1
                        height: 100,
                        child: Padding(
                          padding: const EdgeInsets.all(25),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/tds.png',
                                width: 50,
                                height: 50,
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TDS',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: CustomColors.cream,
                                    ),
                                  ),
                                  Text(
                                    'Limit max: ' + data['limitTds'].toString(),
                                    style: TextStyle(
                                      color: CustomColors.darkCream,
                                    ),
                                  ),
                                ],
                              ),
                              Spacer(
                                flex: 2, // <-- SEE HERE
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.red, // background
                                  onPrimary: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ), // foreground
                                ),
                                onPressed: () {
                                  _tdsInput(context);
                                },
                                child: Text('Set'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   crossAxisAlignment: CrossAxisAlignment.center,
                //   children: [
                //     Card(
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(40),
                //       ),
                //       elevation: 5,
                //       margin: EdgeInsets.only(
                //         top: 5,
                //         left: 5,
                //         right: 5,
                //         bottom: 10,
                //       ),
                //       child: SizedBox(
                //         width: MediaQuery.of(context).size.width *
                //             0.90, // between 0 and 1
                //         height: 100,
                //         child: Padding(
                //           padding: const EdgeInsets.all(25),
                //           child: Row(
                //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //             crossAxisAlignment: CrossAxisAlignment.center,
                //             children: [
                //               Image.asset(
                //                 'assets/ph.png',
                //                 height: 50,
                //               ),
                //               SizedBox(
                //                 width: 20,
                //               ),
                //               Column(
                //                 mainAxisAlignment: MainAxisAlignment.center,
                //                 crossAxisAlignment: CrossAxisAlignment.start,
                //                 children: [
                //                   Text(
                //                     'Ph',
                //                     style: TextStyle(
                //                       fontSize: 18,
                //                       color: CustomColors.cream,
                //                     ),
                //                   ),
                //                   Text(
                //                     'Limit max: ' + data['limitPh'].toString(),
                //                     style: TextStyle(
                //                       color: CustomColors.darkCream,
                //                     ),
                //                   ),
                //                 ],
                //               ),
                //               Spacer(
                //                 flex: 2, // <-- SEE HERE
                //               ),
                //               ElevatedButton(
                //                 style: ElevatedButton.styleFrom(
                //                   primary: Colors.red, // background
                //                   onPrimary: Colors.white,
                //                   shape: RoundedRectangleBorder(
                //                     borderRadius: BorderRadius.circular(15),
                //                   ), // for// foreground
                //                 ),
                //                 onPressed: () {
                //                   _phInput(context);
                //                 },
                //                 child: Text('Set'),
                //               ),
                //             ],
                //           ),
                //         ),
                //       ),
                //     ),
                //   ],
                // ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      elevation: 5,
                      margin: EdgeInsets.only(
                        top: 5,
                        left: 5,
                        right: 5,
                        bottom: 10,
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width *
                            0.90, // between 0 and 1
                        height: 170,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/ledTrue.png',
                                height: 50,
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'LED',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: CustomColors.cream,
                                    ),
                                  ),
                                  Text(
                                    'On: ' + data['timeLedOn'].toString(),
                                    style: TextStyle(
                                      color: CustomColors.darkCream,
                                    ),
                                  ),
                                  Text(
                                    'Off: ' + data['timeLedOff'].toString(),
                                    style: TextStyle(
                                      color: CustomColors.darkCream,
                                    ),
                                  ),
                                ],
                              ),
                              Spacer(
                                flex: 1,
                              ),
                              Column(
                                children: [
                                  Text(
                                    'Auto',
                                    style: TextStyle(
                                      color: CustomColors.darkCream,
                                    ),
                                  ),
                                  Switch(
                                    value: data['autoLed'],
                                    onChanged: (value) {
                                      setState(() {
                                        isAutoLed = value;
                                        _updateAutoLed();
                                        // print(isSwitched);
                                      });
                                    },
                                    activeTrackColor: Colors.lightGreenAccent,
                                    activeColor: Colors.green,
                                  ),
                                  Text(
                                    'Manual',
                                    style: TextStyle(
                                      color: CustomColors.darkCream,
                                    ),
                                  ),
                                  Switch(
                                    value: data['stateLed'],
                                    onChanged: (value) {
                                      setState(() {
                                        data['stateLed'] = value;
                                        _updateLed();
                                        // print(isSwitched);
                                      });
                                    },
                                    activeTrackColor: Colors.lightGreenAccent,
                                    activeColor: Colors.green,
                                  ),
                                ],
                              ),
                              Spacer(
                                flex: 1,
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.red, // background
                                  onPrimary: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ), // foreground
                                ),
                                onPressed: () {
                                  _ledTimer(context);
                                },
                                child: Text('Set'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Card(
                      margin: EdgeInsets.only(
                        top: 5,
                        left: 5,
                        right: 5,
                        bottom: 10,
                      ),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width *
                            0.90, // between 0 and 1
                        height: 115,
                        child: Padding(
                          padding: const EdgeInsets.all(25),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/waterLevel.png',
                                width: 50,
                                height: 80,
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Water Pump',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: CustomColors.cream,
                                    ),
                                  ),
                                ],
                              ),
                              Spacer(
                                flex: 2, // <-- SEE HERE
                              ),
                              Column(
                                children: [
                                  Text(
                                    'Auto',
                                    style: TextStyle(
                                      color: CustomColors.darkCream,
                                    ),
                                  ),
                                  Switch(
                                    value: data['autoWaterLevel'],
                                    onChanged: (value) {
                                      setState(() {
                                        data['autoWaterLevel'] = value;
                                        _updateWaterLevel();
                                        // print(isSwitched);
                                      });
                                    },
                                    activeTrackColor: Colors.lightGreenAccent,
                                    activeColor: Colors.green,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _tdsInput(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Atur batas maksimal TDS'),
          content: TextField(
            controller: tdsInput,
            decoration: InputDecoration(hintText: "750ppm"),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            FlatButton(
              child: Text('OK'),
              onPressed: () {
                print(tdsInput.text);
                Navigator.pop(context);
                setState(() {
                  _updateTds();
                });
              },
            ),
          ],
        );
      },
    );
  }

  // Future<void> _phInput(BuildContext context) async {
  //   return showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Text('Atur batas maksimal Ph'),
  //         content: TextField(
  //           controller: phInput,
  //           decoration: InputDecoration(hintText: "7"),
  //         ),
  //         actions: <Widget>[
  //           FlatButton(
  //             child: Text('CANCEL'),
  //             onPressed: () {
  //               Navigator.pop(context);
  //             },
  //           ),
  //           FlatButton(
  //             child: Text('OK'),
  //             onPressed: () {
  //               print(phInput.text);
  //               Navigator.pop(context);
  //               setState(() {
  //                 _updatePh();
  //               });
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Future<void> _ledTimer(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Atur waktu led'),
          content: Column(
            children: [
              TextField(
                controller: timeOn,
                decoration: InputDecoration(
                    icon: Icon(Icons.timer), //icon of text field
                    labelText: "Waktu hidup" //label text of field
                    ),
                readOnly:
                    true, //set it true, so that user will not able to edit text
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    initialTime: TimeOfDay.now(),
                    context: context,
                  );

                  if (pickedTime != null) {
                    print(pickedTime.format(context).toString());

                    setState(() {
                      timeOn.text = pickedTime.format(context).toString();

                      _updateTimer();
                    });
                  } else {
                    print("Time is not selected");
                  }
                },
              ),
              TextField(
                controller: timeOff,
                decoration: InputDecoration(
                    icon: Icon(Icons.timer), //icon of text field
                    labelText: "Waktu mati" //label text of field
                    ),
                readOnly:
                    true, //set it true, so that user will not able to edit text
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    initialTime: TimeOfDay.now(),
                    context: context,
                  );

                  if (pickedTime != null) {
                    print(pickedTime.format(context).toString());

                    setState(() {
                      timeOff.text = pickedTime.format(context).toString();

                      _updateTimer();
                    });
                  } else {
                    print("Time is not selected");
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            FlatButton(
              child: Text('OK'),
              onPressed: () {
                print(phInput.text);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
