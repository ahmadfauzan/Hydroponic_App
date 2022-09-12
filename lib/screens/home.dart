import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_esp32/res/custom_colors.dart';
import 'package:firebase_esp32/screens/sign_in_screen.dart';
import 'package:firebase_esp32/utils/authentication.dart';
import 'package:water_bottle/water_bottle.dart';

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final fb = FirebaseDatabase.instance;
  late DatabaseReference _dbref;
  late User _user;
  late Map sensor;
  late Map data;
  late Map relay;
  var distancePercentage;
  bool isLed = false;
  bool _isSigningOut = false;

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
      distancePercentage = (4.5 / sensor['waterLevel']) * 100;
      if (distancePercentage > 100) {
        distancePercentage = 100;
      }
    });
  }

  _readData() {
    _dbref.child('data/').onValue.listen((event) {
      final snapshot = event.snapshot;
      setState(() {
        data = {
          'age': snapshot.child('age').value,
          'autoLed': snapshot.child('autoLed').value,
          'autoWaterLevel': snapshot.child('autoWaterLevel').value,
          'dateTime': snapshot.child('dateTime').value,
          'timeLedOn': snapshot.child('timeLedOn').value,
          'timeLedOff': snapshot.child('timeLedOff').value,
        };
      });
    });
  }

  _readRelay() {
    _dbref.child('relay/').onValue.listen((event) {
      final snapshot = event.snapshot;
      setState(() {
        relay = {
          'pumpMix': snapshot.child('pumpMix').value,
          'pumpNutA': snapshot.child('pumpNutA').value,
          'pumpNutB': snapshot.child('pumpNutB').value,
          // 'pumpPhDown': snapshot.child('pumpPhDown').value,
          // 'pumpPhUp': snapshot.child('pumpPhUp').value,
          'pumpWater': snapshot.child('pumpWater').value,
        };
      });
    });
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
      'autoWaterLevel': false,
      'dateTime': '',
      'timeLedOn': '',
      'timeLedOff': '',
    };

    relay = {
      'pumpMix': false,
      'pumpNutA': false,
      'pumpNutB': false,
      // 'pumpPhDown': false,
      // 'pumpPhUp': false,
      'pumpWater': false,
    };
    distancePercentage = 0;
    _dbref = FirebaseDatabase.instance.ref();
    _readSensor();
    _readData();
    _readRelay();
    super.initState();
  }

  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      margin: EdgeInsets.only(
                        top: 5,
                        left: 10,
                        right: 5,
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width *
                            0.46, // between 0 and 1
                        height: 150,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/tds.png',
                                    height: 70,
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'TDS',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: CustomColors.cream,
                                        ),
                                      ),
                                      Text(
                                        sensor['tds'].toString() + ' ppm',
                                        style: TextStyle(
                                          color: CustomColors.darkCream,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Spacer(
                                flex: 2,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Pompa nutrisi A',
                                    style: TextStyle(
                                      color: CustomColors.darkCream,
                                    ),
                                  ),
                                  relay['pumpNutA']
                                      ? Text(
                                          'On',
                                          style: TextStyle(
                                            color: CustomColors.green,
                                          ),
                                        )
                                      : Text(
                                          'Off',
                                          style: TextStyle(
                                            color: CustomColors.red,
                                          ),
                                        ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Pompa nutrisi B',
                                    style: TextStyle(
                                      color: CustomColors.darkCream,
                                    ),
                                  ),
                                  relay['pumpNutB']
                                      ? Text(
                                          'On',
                                          style: TextStyle(
                                            color: CustomColors.green,
                                          ),
                                        )
                                      : Text(
                                          'Off',
                                          style: TextStyle(
                                            color: CustomColors.red,
                                          ),
                                        ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Card(
                    //   shape: RoundedRectangleBorder(
                    //     borderRadius: BorderRadius.circular(15),
                    //   ),
                    //   elevation: 5,
                    //   margin: EdgeInsets.only(
                    //     top: 5,
                    //     left: 5,
                    //     right: 5,
                    //   ),
                    //   child: SizedBox(
                    //     width: MediaQuery.of(context).size.width *
                    //         0.46, // between 0 and 1
                    //     height: 150,
                    //     child: Padding(
                    //       padding: const EdgeInsets.all(10),
                    //       child: Column(
                    //         children: [
                    //           Row(
                    //             mainAxisAlignment:
                    //                 MainAxisAlignment.spaceBetween,
                    //             crossAxisAlignment: CrossAxisAlignment.start,
                    //             children: [
                    //               Image.asset(
                    //                 'assets/ph.png',
                    //                 width: 60,
                    //                 height: 80,
                    //               ),
                    //               Column(
                    //                 mainAxisAlignment: MainAxisAlignment.start,
                    //                 crossAxisAlignment: CrossAxisAlignment.end,
                    //                 children: [
                    //                   Text(
                    //                     'Ph',
                    //                     style: TextStyle(
                    //                       fontSize: 18,
                    //                       color: CustomColors.cream,
                    //                     ),
                    //                   ),
                    //                   Text(
                    //                     sensor['ph'].toString(),
                    //                     style: TextStyle(
                    //                       color: CustomColors.darkCream,
                    //                     ),
                    //                   ),
                    //                 ],
                    //               ),
                    //             ],
                    //           ),
                    //           Spacer(
                    //             flex: 2,
                    //           ),
                    //           Row(
                    //             mainAxisAlignment:
                    //                 MainAxisAlignment.spaceBetween,
                    //             crossAxisAlignment: CrossAxisAlignment.end,
                    //             children: [
                    //               Text(
                    //                 'Pompa Ph Up',
                    //                 style: TextStyle(
                    //                   color: CustomColors.darkCream,
                    //                 ),
                    //               ),
                    //               relay['pumpPhUp']
                    //                   ? Text(
                    //                       'On',
                    //                       style: TextStyle(
                    //                         color: CustomColors.green,
                    //                       ),
                    //                     )
                    //                   : Text(
                    //                       'Off',
                    //                       style: TextStyle(
                    //                         color: CustomColors.red,
                    //                       ),
                    //                     ),
                    //             ],
                    //           ),
                    //           Row(
                    //             mainAxisAlignment:
                    //                 MainAxisAlignment.spaceBetween,
                    //             crossAxisAlignment: CrossAxisAlignment.end,
                    //             children: [
                    //               Text(
                    //                 'Pompa Ph Down',
                    //                 style: TextStyle(
                    //                   color: CustomColors.darkCream,
                    //                 ),
                    //               ),
                    //               relay['pumpPhDown']
                    //                   ? Text(
                    //                       'On',
                    //                       style: TextStyle(
                    //                         color: CustomColors.green,
                    //                       ),
                    //                     )
                    //                   : Text(
                    //                       'Off',
                    //                       style: TextStyle(
                    //                         color: CustomColors.red,
                    //                       ),
                    //                     ),
                    //             ],
                    //           )
                    //         ],
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      margin: EdgeInsets.only(
                        top: 5,
                        left: 5,
                        right: 5,
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width *
                            0.46, // between 0 and 1
                        height: 150,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  sensor['led']
                                      ? Image.asset(
                                          'assets/ledTrue.png',
                                          height: 80,
                                        )
                                      : Image.asset(
                                          'assets/ledFalse.png',
                                          height: 80,
                                        ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'LED',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: CustomColors.cream,
                                        ),
                                      ),
                                      Text(
                                        data['autoLed'] ? 'Auto' : 'Manual',
                                        style: TextStyle(
                                          color: CustomColors.darkCream,
                                        ),
                                      ),
                                      Text(
                                        data['timeLedOn'].toString() + ' On',
                                        style: TextStyle(
                                          color: CustomColors.darkCream,
                                        ),
                                      ),
                                      Text(
                                        data['timeLedOff'].toString() + ' Off',
                                        style: TextStyle(
                                          color: CustomColors.darkCream,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Spacer(
                                flex: 2,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Status',
                                    style: TextStyle(
                                      color: CustomColors.darkCream,
                                    ),
                                  ),
                                  sensor['led']
                                      ? Text(
                                          'On',
                                          style: TextStyle(
                                            color: CustomColors.green,
                                          ),
                                        )
                                      : Text(
                                          'Off',
                                          style: TextStyle(
                                            color: CustomColors.red,
                                          ),
                                        ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      margin: EdgeInsets.only(
                        top: 10,
                        left: 5,
                        right: 5,
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width *
                            0.46, // between 0 and 1
                        height: 150,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  sensor['temp'] > 32
                                      ? Image.asset(
                                          'assets/tempHot.png',
                                          height: 80,
                                        )
                                      : Image.asset(
                                          'assets/tempCold.png',
                                          height: 80,
                                        ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Temp',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: CustomColors.cream,
                                        ),
                                      ),
                                      Text(
                                        sensor['temp'].floor().toString() +
                                            ' C',
                                        style: TextStyle(
                                          color: CustomColors.darkCream,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Spacer(
                                flex: 2,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  sensor['temp'] >= 28
                                      ? Text(
                                          'Not good',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: CustomColors.red,
                                          ),
                                        )
                                      : Text(
                                          'Good',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: CustomColors.green,
                                          ),
                                        ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      margin: EdgeInsets.only(
                        top: 10,
                        left: 5,
                        right: 5,
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width *
                            0.46, // between 0 and 1
                        height: 150,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/waterLevel.png',
                                    width: 60,
                                    height: 80,
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Water Level',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: CustomColors.cream,
                                        ),
                                      ),
                                      Text(
                                        distancePercentage.floor().toString() +
                                            '%',
                                        style: TextStyle(
                                          color: CustomColors.darkCream,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Spacer(
                                flex: 2,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Pompa Air',
                                    style: TextStyle(
                                      color: CustomColors.darkCream,
                                    ),
                                  ),
                                  relay['pumpWater']
                                      ? Text(
                                          'On',
                                          style: TextStyle(
                                            color: CustomColors.green,
                                          ),
                                        )
                                      : Text(
                                          'Off',
                                          style: TextStyle(
                                            color: CustomColors.red,
                                          ),
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
          ],
        ),
      ),
    );
  }
}
