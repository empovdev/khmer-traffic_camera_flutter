import 'package:flutter/material.dart';
import 'package:khmer_traffic_live/TrafficCamera.dart';
import 'dart:convert';
import 'package:scoped_model/scoped_model.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/',
      routes: {'/': (context) => MyHomePage()},
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TrafficListModel trafficListModel = TrafficListModel();

  bool _loading = true;

  //Network
  String _connectionStatus = 'Unknown';
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();

    //Init Network
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _connectionStatus = result.toString();

        if (_connectionStatus != "ConnectivityResult.none") {
          if (trafficListModel.getStatus() == false) {
            trafficListModel.checkConnection();
          }
        }
      });
    });

    //Loading Data from Json
    _loadDataFromAsset();
  }

  void _loadDataFromAsset() async {
    String data =
        await DefaultAssetBundle.of(context).loadString("assets/data.json");

    final jsonResult = json.decode(data);
    List<TrafficCamera> trafficCameras = List();
    for (var item in jsonResult) {
      trafficCameras.add(TrafficCamera.fromJson(item));
    }
    setState(() {
      trafficListModel.addAll(trafficCameras);
      trafficListModel.checkConnection();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Khmer Live Traffic"),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: Colors.white,
            ),
            onPressed: _openInfo,
          )
        ],
      ),
      body: ScopedModel(model: trafficListModel, child: TrafficCameraList()),
    );
  }

  Future<Null> _openInfo() async {
    await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return SimpleDialog(
            title: Text("Infomation And Credit"),
            contentPadding: EdgeInsets.all(8.0),
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("This is for educational purpose.")),
              Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("The Streaming Camera is provided by Ezecom."))
            ],
          );
        });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<Null> initConnectivity() async {
    String connectionStatus;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      connectionStatus = (await _connectivity.checkConnectivity()).toString();
    } on PlatformException catch (e) {
      print(e.toString());
      connectionStatus = 'Failed to get connectivity.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return;
    }

    setState(() {
      _connectionStatus = connectionStatus;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
