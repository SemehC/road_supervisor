import 'package:colours/colours.dart';
import 'package:flutter/material.dart';
import 'package:road_supervisor/models/database_manager.dart';
import 'package:road_supervisor/models/db_polyline_item.dart';

class MyAccoutWidget extends StatefulWidget {
  MyAccoutWidget({Key? key}) : super(key: key);

  @override
  _MyAccoutWidgetState createState() => _MyAccoutWidgetState();
}

class _MyAccoutWidgetState extends State<MyAccoutWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> databaseItemsWidgets = [];

  @override
  void initState() {
    super.initState();
    fetchAllDbItems();
  }

  buildPageHeader() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(15, 0, 15, 20),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'User Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                ),
                Text(
                  'Location',
                )
              ],
            ),
            Align(
              alignment: Alignment(0, 1),
              child: Container(
                width: 80,
                height: 80,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Image.network(
                  'https://picsum.photos/seed/26/600',
                  fit: BoxFit.cover,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  buildPolyLineItem(
      {int id = 0, String fileName = "", bool isUploaed = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.network(
            'https://picsum.photos/seed/83/600',
            width: 200,
            height: 100,
            fit: BoxFit.cover,
          ),
          Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                'Scan N°$id',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              isUploaed
                  ? Icon(Icons.upload, color: Colours.green)
                  : Icon(
                      Icons.upload,
                      color: Colours.red,
                    ),
            ],
          )
        ],
      ),
    );
  }

  fetchAllDbItems() async {
    List<DbPolyline> dbitems = await DatabaseManager.getAllPolylines();

    dbitems.forEach((element) {
      setState(() {
        databaseItemsWidgets.add(buildPolyLineItem(
            id: element.id,
            fileName: element.fileLocation,
            isUploaed: element.uploadStatus));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Color(0xFFE6E6E6),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          buildPageHeader(),
          Divider(
            thickness: 1,
            color: Color(0xFF5B5B5B),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  ...databaseItemsWidgets,
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
