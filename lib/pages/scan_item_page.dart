import 'dart:convert';
import 'dart:io';
import 'package:floating_menu_panel/floating_menu_panel.dart';
import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:group_button/group_button.dart';
import 'package:menu_button/menu_button.dart';
import 'package:ndialog/ndialog.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:road_supervisor/models/db_polyline_item.dart';

class ScanItemPage extends StatefulWidget {
  final DbPolyline dbItem;
  ScanItemPage({Key? key, required this.dbItem}) : super(key: key);

  @override
  _ScanItemPageState createState() => _ScanItemPageState();
}

class _ScanItemPageState extends State<ScanItemPage>
    with TickerProviderStateMixin {
  bool uploadStatus = false;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  Set<Polyline> _polyline = {};
  List<MapType> mapTypes = [
    MapType.normal,
    MapType.satellite,
    MapType.hybrid,
    MapType.terrain
  ];

  List<String> mapTypeDropdownItems = [
    "Normal",
    "Satellite",
    "Hybrid",
    "Terrain"
  ];
  bool showMarkers = false;
  bool stillLoading = true;
  //Initial map type
  int currentMapType = 0;
  LatLng? prevPos = null;
  LatLng _initialPosition = LatLng(0, 0);
  List<LatLng> currentPoints = [];
  int currRoadType = 2;
//Google map Controller
  late GoogleMapController _googleMapController;
  @override
  void initState() {
    super.initState();
    fetchJsonFileData();
  }

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

  CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();
  _addMarker(String id, LatLng pos, String infos) {
    MarkerId m = MarkerId(id);
    setState(
      () {
        markers[m] = Marker(
          markerId: m,
          position: pos,
          onTap: () {
            print("Tapped");
            _customInfoWindowController.addInfoWindow!(
                Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_circle,
                                color: Colors.white,
                                size: 30,
                              ),
                              SizedBox(
                                width: 8.0,
                              ),
                              Text(
                                "I am here",
                              )
                            ],
                          ),
                        ),
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ],
                ),
                pos);
          },
        );
      },
    );
  }

  _addNewPolyline({int type = 0}) {
    int id = _polyline.length;
    print("Adding polyline of type : $type");
    if (type == 0) {
      _polyline.add(Polyline(
        endCap: Cap.roundCap,
        startCap: Cap.roundCap,
        polylineId: PolylineId("${id + 1}"),
        visible: true,
        points: currentPoints,
        color: Colors.red,
      ));
    }
    if (type == 1) {
      _polyline.add(Polyline(
        endCap: Cap.roundCap,
        startCap: Cap.roundCap,
        polylineId: PolylineId("${id + 1}"),
        visible: true,
        points: currentPoints,
        color: Colors.orange,
      ));
    }
    if (type == 2) {
      _polyline.add(Polyline(
        endCap: Cap.roundCap,
        startCap: Cap.roundCap,
        polylineId: PolylineId("${id + 1}"),
        visible: true,
        points: currentPoints,
        color: Colors.blue,
      ));
    }
  }

  fetchJsonFileData() async {
    File f = File(widget.dbItem.fileLocation);

    String s = await f.readAsString();
    var cl = s.substring(0, s.length - 2);
    cl += "}";
    var js = json.decode(cl) as Map<String, dynamic>;
    js.forEach((key, value) {
      LatLng currPos =
          LatLng(double.parse(value['lat']), double.parse(value['long']));
      String makerInfo = "";
      if (key == "0") {
        makerInfo = "Initial Position Position";
        setState(() {
          _initialPosition = currPos;
          stillLoading = false;
        });
      }
      int roadTp = int.parse(value['type']);
      String rdType = roadTp == 0
          ? "Bad"
          : roadTp == 1
              ? "Average"
              : "Good";
      makerInfo += "\n$rdType";
      _addMarker(key, currPos, makerInfo);

      print("Road type : $roadTp");
      print("Road nbr : $key");
      if (roadTp == 0) {
        print("Added type 0");
        if (currRoadType != 0) {
          currentPoints = [];
          if (prevPos != null) {
            currentPoints.add(prevPos!);
          }

          _addNewPolyline(type: 0);
          currRoadType = 0;
        }
      }
      if (roadTp == 1) {
        if (currRoadType != 1) {
          currentPoints = [];
          if (prevPos != null) {
            currentPoints.add(prevPos!);
          }

          _addNewPolyline(type: 1);
          currRoadType = 1;
        }
      }

      if (roadTp == 2) {
        if (currRoadType != 2) {
          currentPoints = [];
          if (prevPos != null) {
            currentPoints.add(prevPos!);
          }
          _addNewPolyline(type: 2);
          currRoadType = 2;
        }
      }
      currentPoints.add(currPos);
      prevPos = currPos;
    });
    print("Polylines length${_polyline.length}");
    setState(() {});
  }

  buildMap() {
    return Container(
      child: GoogleMap(
        polylines: _polyline,
        markers:
            showMarkers ? Set<Marker>.of(markers.values) : Set<Marker>.of([]),
        mapType: mapTypes[currentMapType],
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 20,
        ),
        onMapCreated: (GoogleMapController controller) {
          _googleMapController = controller;
        },
      ),
    );
  }

  buildPage() {
    return Stack(
      children: [
        !stillLoading ? buildMap() : Text("Loading"),
        buildFloatingBox(),
      ],
    );
  }

  buildFloatingBox() {
    return FloatingMenuPanel(
        positionTop: 0.0, // Initial Top Position
        positionLeft: 0.0, // Initial Left Position
        backgroundColor: Color(0xFFEDEDED), // Color of the panel
        contentColor: Colors.black, // Color of the icons
        borderRadius: BorderRadius.circular(8.0), // Border radius of the panel
        dockType: DockType
            .inside, // 'DockType.inside' or 'DockType.outside', weather to dock the panel outside or inside the edge of the screen
        dockOffset:
            5.0, // Offset the dock from the edge depending on the 'dockType' property
        panelAnimDuration: 300, // Duration for panel open and close animation
        panelAnimCurve:
            Curves.easeOut, // Curve for panel open and close animation
        dockAnimDuration:
            100, // Auto dock to the edge of screen - animation duration
        dockAnimCurve: Curves.easeOut, // Auto dock animation curve
        panelOpenOffset:
            20.0, // Offset from the edge of screen when panel is open
        panelIcon: Icons.menu, // Panel open/close icon
        size: 60.0, // Size of single button in the panel
        iconSize: 25.0, // Size of icons
        borderWidth: 1.0, // Width of panel border
        borderColor: Colors.black, // Color of panel border

        onPressed: (index) {
          if (index == 0) buildMapSettingsPopup();
        },
        buttons: [
          Icons.map_outlined,
        ]);
  }

  final Widget normalChildButton = SizedBox(
    width: 93,
    height: 40,
    child: Padding(
      padding: const EdgeInsets.only(left: 16, right: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(child: Text("Map type", overflow: TextOverflow.ellipsis)),
          const SizedBox(
            width: 12,
            height: 17,
            child: FittedBox(
              fit: BoxFit.fill,
              child: Icon(
                Icons.arrow_drop_down,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  buildMapSettingsPopup() async {
    await NDialog(
      dialogStyle: DialogStyle(titleDivider: true),
      title: Text("Map Settings"),
      content: Container(
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Text("Map type : "),
                MenuButton(
                  child: normalChildButton,
                  items: mapTypeDropdownItems,
                  itemBuilder: (String value) => Container(
                    height: 40,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                        vertical: 0.0, horizontal: 5),
                    child: Text(value),
                  ),
                  toggledChild: Container(
                    child: normalChildButton,
                  ),
                  onItemSelected: (String value) {
                    setState(() {
                      currentMapType = mapTypeDropdownItems.indexOf(value);
                    });
                  },
                )
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text("Show markers : "),
                GroupButton(
                  selectedButtons: [showMarkers ? "Show" : "Hide"],
                  onSelected: (index, _) {
                    setState(() {
                      showMarkers = index == 0;
                    });
                  },
                  buttons: ["Show", "Hide"],
                ),
              ],
            ),
          ],
        ),
      ),
    ).show(context, transitionType: DialogTransitionType.Bubble);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: buildPageAppBar(),
      body: buildPage(),
    );
  }
}
