import 'package:flutter/material.dart';
import 'package:road_supervisor/models/database_manager.dart';
import 'package:road_supervisor/models/db_polyline_item.dart';
import 'package:road_supervisor/models/polyline_point.dart';

class ScanItemPage extends StatefulWidget {
  final DbPolyline dbItem;
  ScanItemPage({Key? key, required this.dbItem}) : super(key: key);

  @override
  _ScanItemPageState createState() => _ScanItemPageState();
}

class _ScanItemPageState extends State<ScanItemPage> {
  bool uploadStatus = false;
  buildPageAppBar() {
    return AppBar(
      title: Text("Scan : ${widget.dbItem.id}"),
      leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          }),
    );
  }

  buildPage() {
    return Column(
      children: [
        Text(widget.dbItem.fileLocation),
        Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildPageAppBar(),
      body: buildPage(),
    );
  }
}
