import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:khmer_traffic_live/video.dart';
import 'package:scoped_model/scoped_model.dart';

final _rowHeight = 100.0;

class TrafficCamera {
  String name;
  String liveUrl;
  int status = 0;

  TrafficCamera({this.name, this.liveUrl});

  factory TrafficCamera.fromJson(Map<String, dynamic> parsedJson) {
    return TrafficCamera(
        name: parsedJson['locationName'], liveUrl: parsedJson['cameraUrl']);
  }

  Future checkStatus() async {
    if (status != 0) return;

    http.get(liveUrl).then((r) {
      bool responseStatus = r.statusCode == 200;
      print("check ${name}");
      if (responseStatus) {
        status = 1;
      } else {
        status = 2;
      }
    });
  }
}

class TrafficListModel extends Model {
  final List<TrafficCamera> _items = <TrafficCamera>[];
  bool _check = false;
  TrafficListModel();


  bool get check => _check;

  TrafficListModel.clone(TrafficListModel trafficList) {
    _items.addAll(trafficList._items);
  }

  int get itemCount => _items.length;

  void addTrafficCamera(TrafficCamera trafficCamera) {
    _items.add(trafficCamera);
    notifyListeners();
  }

  void addAll(List<TrafficCamera> t) {
    _items.addAll(t);
    notifyListeners();
  }

  static TrafficListModel of(BuildContext context) =>
      ScopedModel.of<TrafficListModel>(context);

  List<TrafficCamera> get items => _items;

  Future checkConnection() async {
    for (TrafficCamera item in _items) {
     await item.checkStatus().then((_){
       if(getStatus() == true){
         _check = true;
         notifyListeners();
       }
     });
    }

  }

  //Return false if all status is not checked
  bool getStatus() {
    for (TrafficCamera item in _items) {
      if (item.status == 0) {
        return false;
      }
    }
    return true;
  }

  TrafficCamera get(int i) {
    return _items[i];
  }
}

class TrafficCameraRow extends StatelessWidget {
  TrafficCameraRow({Key key, this.traffic}) : super(key: UniqueKey());

  final List<Color> _colors = [Colors.grey, Colors.green, Colors.red];

  final TrafficCamera traffic;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      height: _rowHeight,
      child: Card(
        elevation: 3.0,
        child: InkWell(
          onTap: () => _navigateToCamera(context, traffic.liveUrl),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(traffic.name),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(Icons.fiber_manual_record,
                    color: _colors[traffic.status]),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCamera(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => VideoApp(url)),
    );
  }
}

class TrafficCameraList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TrafficCameraListState();
  }
}

class _TrafficCameraListState extends State<TrafficCameraList> {
  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<TrafficListModel>(
      builder: (context, child, model) {
        return ListView.builder(
            itemCount: model.items.length,
            itemBuilder: (context, i) {
              return TrafficCameraRow(
                traffic: model._items[i],
              );
            });
      },
    );
  }
}
