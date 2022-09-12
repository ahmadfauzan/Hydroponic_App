import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_esp32/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_esp32/res/custom_colors.dart';
import 'package:firebase_esp32/screens/sign_in_screen.dart';
import 'package:firebase_esp32/utils/authentication.dart';
import 'package:firebase_esp32/widgets/app_bar_title.dart';
import 'package:intl/intl.dart';

import 'control.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({Key? key, required User user})
      : _user = user,
        super(key: key);

  final User _user;

  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final fb = FirebaseDatabase.instance;
  late DatabaseReference _dbref;
  late User _user;
  var levelUser;
  var distance;
  var ph;
  var tds;
  var temp;
  var timestamp;
  var inputFormat = DateFormat('HH:mm');
  var time;

  late Map sensor;
  bool isLed = false;
  bool _isSigningOut = false;

  // bottom navbar
  int _selectedIndex = 0;
  List<Widget> _widgetOptions = <Widget>[
    Home(),
    Control(),
    Home(),
  ];

  _setLevelUser() {
    _dbref.child('users/' + _user.uid).child('level').onValue.listen((event) {
      final data = event.snapshot.value;
      setState(() {
        if (data == 1) {
          _dbref.child("users/" + _user.uid).set({
            "level": 1,
          });
        } else {
          _dbref.child("users/" + _user.uid).set({
            "level": 2,
          });
        }
      });
      levelUser = data;
    });
  }

  Future<void> _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    if (levelUser == 1) {
      if (index == 2) {
        setState(() {
          _isSigningOut = true;
        });
        await Authentication.signOut(context: context);
        setState(() {
          _isSigningOut = false;
        });
        Navigator.of(context).pushReplacement(_routeToSignInScreen());
      }
    } else {
      if (index == 1) {
        setState(() {
          _isSigningOut = true;
        });
        await Authentication.signOut(context: context);
        setState(() {
          _isSigningOut = false;
        });
        Navigator.of(context).pushReplacement(_routeToSignInScreen());
      }
    }
  }

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
          'ph': data.child('ph').value,
          'temp': data.child('temp').value,
          'waterLevel': data.child('distance').value,
          'led': data.child('led').value,
        };
      });
    });
    _dbref.child('data/').onValue.listen((event) {
      final data = event.snapshot;
      setState(() {
        timestamp = data.child('dateTime').value;
        ;
      });
    });
  }

  _storeUUID() {
    _dbref.child("hydroponic/" + _user.uid).set({
      "name": _user.displayName,
    });
  }

  @override
  void initState() {
    _user = widget._user;
    sensor = {
      'tds': 0,
      'ph': 0,
      'temp': 0,
      'waterLevel': 0,
      'led': false,
    };
    timestamp = 0;
    _dbref = FirebaseDatabase.instance.ref();
    _readSensor();
    _setLevelUser();
    _storeUUID();

    super.initState();
  }

  BottomNavigationBarItem? control(BuildContext context) {
    BottomNavigationBarItem? item;
    if (levelUser == 1) {
      item = BottomNavigationBarItem(
        icon: Icon(Icons.business),
        label: 'Business',
        backgroundColor: Colors.green,
      );
    } else {
      item = null;
    }
    return item;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: CustomColors.signInBackground,
        body: SingleChildScrollView(
          child: Column(
            children: [
              banner(),
              SizedBox(
                height: 20,
              ),
              _widgetOptions.elementAt(_selectedIndex),
            ],
          ),
        ),
        bottomNavigationBar: levelUser == 1
            ? BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                    backgroundColor: Colors.red,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Control',
                    backgroundColor: Colors.pink,
                  ),
                  // control(context),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.logout),
                    label: 'Sign Out',
                    backgroundColor: Colors.purple,
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.amber[800],
                onTap: _onItemTapped,
              )
            : BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                    backgroundColor: Colors.red,
                  ),
                  // control(context),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.logout),
                    label: 'Sign Out',
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.amber[800],
                onTap: _onItemTapped,
              ),
      ),
    );
  }

  Widget banner() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          // topLeft: Radius.circular(20),
          // topRight: Radius.circular(20),
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      elevation: 5,
      margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0),
      child: SizedBox(
        width: double.infinity, // between 0 and 1
        height: 200,
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/plant.png',
                height: 120,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Hydroponic',
                    style: TextStyle(
                      fontSize: 25,
                      color: CustomColors.cream,
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    inputFormat.format(new DateTime.fromMillisecondsSinceEpoch(
                        timestamp * 1000)),
                    style: TextStyle(
                      color: CustomColors.darkCream,
                    ),
                  ),
                  // Text('24 hari menuju panen'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
