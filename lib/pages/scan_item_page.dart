import 'package:flutter/material.dart';
import 'package:road_supervisor/models/db_polyline_item.dart';

class ScanItemPage extends StatefulWidget {
  final DbPolyline dbItem;
  ScanItemPage({Key? key, required this.dbItem}) : super(key: key);

  @override
  _ScanItemPageState createState() => _ScanItemPageState();
}

class _ScanItemPageState extends State<ScanItemPage> {
  buildPageAppBar() {
    return AppBar(
      title: Text("Scan : ${widget.dbItem.id}"),
    );
  }

  fetchJsonFile() {}

  handleUpload() {
    print("Uploading");
  }

  buildUploadBt() {
    return TextButton.icon(
      onPressed: handleUpload,
      icon: Icon(Icons.upload_file),
      label: Text("Upload scan to cloud"),
    );
  }

  buildPage() {
    return Column(
      children: [
        Text(widget.dbItem.fileLocation),
        Divider(),
        buildUploadBt(),
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
