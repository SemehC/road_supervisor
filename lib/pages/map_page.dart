import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:colours/colours.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:group_button/group_button.dart';

import 'package:menu_button/menu_button.dart';
import 'package:floating_menu_panel/floating_menu_panel.dart';
import 'package:flutter/material.dart';
import 'package:road_supervisor/models/ImageUtils.dart';
import 'package:road_supervisor/models/classifier.dart';
import 'package:road_supervisor/models/classifier_quant.dart';
import 'package:road_supervisor/models/database_manager.dart';
import 'package:road_supervisor/models/permissions_manager.dart';
import 'package:road_supervisor/models/polyline_point.dart';
import 'package:road_supervisor/models/sensors_predictor.dart';
import 'package:road_supervisor/models/user_manager.dart';
import 'package:sensors/sensors.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:lottie/lottie.dart' as lottie;
import 'package:geolocator/geolocator.dart';

import 'package:ndialog/ndialog.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../main.dart';
import 'package:road_supervisor/generated/codegen_loader.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class MapPage extends StatefulWidget {
  MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  //Location service

  //Location service enabled
  late bool _serviceEnabled;
  //Permissions check

  //Location data
  late Position _initialPosition;
  //Google map Controller
  late GoogleMapController _googleMapController;
  //Map markers
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  Set<Circle> circle = {};
  //Fetched locations status
  bool gotData = false;
  //Minimum location distance change
  int minLocationDistance = 5;

  //Map Polylines
  Set<Polyline> _polyline = {};
  //Current polyline points
  List<LatLng> currentPoints = [];

  //Google map map types
  List<MapType> mapTypes = [
    MapType.normal,
    MapType.satellite,
    MapType.hybrid,
    MapType.terrain
  ];
  //Initial map type
  int currentMapType = 0;
  //Map type dropdown
  List<String> mapTypeDropdownItems = [
    LocaleKeys.Normal.tr(),
    "Satellite",
    LocaleKeys.Hybrid.tr(),
    "Terrain"
  ];
  //Traffic enabled status
  bool trafficEnabled = false;

  LatLng? prevPos = null;
  int currRoadType = 0;
  /*
    Sensors
  */
  bool initializedSensors = false;
  bool showSensors = false;
  late UserAccelerometerEvent accelerometerEvent;
  var oldTimeCheckpoint = new DateTime.now().millisecondsSinceEpoch;
  /*
    Camera
  */
  late CameraController _cameraController;
  bool showCamera = false;

  double cameraPreviewHeight = 200;
  double cameraPreviewWidth = 100;
  bool isCameraPreviewZoomedIn = false;
  double cameraPreviewTop = 0;
  double cameraPreviewRight = 0;

  /*
  UI
  */
  bool startedScanning = false;
  bool mapIsMainPage = true;
  Stopwatch watch = new Stopwatch();

  /*App Vars */

  List<PolyLinePoint> currPolylinePoints = [];

  /* TENSORFLOW STUFF */
  bool predictUsingSensors = true;
  bool predictUsingCamera = false;

  int currentSensorPrediction = -1;
  var oldTime = DateTime.now().millisecondsSinceEpoch;
  late Classifier _classifier;
  var MODEL_PATH = "assets/roadImageClassificationModel.tflite";
  var LABELS_PATH = "assets/labels.txt";
  Category? category = Category("Asphalt", 1);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    SensorsPredictor.initializePredictor();

    fetchCamera();
    initializeLocation();
    initializeSensors();
    _classifier = ClassifierQuant();
    UserManager.getLocalSettings(this);
  }

  checkLocationAgain() {
    initializeLocation();
  }

  void _predict(img.Image imageInput) async {
    var pred = _classifier.predict(imageInput);
    setState(() {
      this.category = pred;
    });
  }

  fetchCamera() {
    _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    _cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      _cameraController.startImageStream((CameraImage img) async {
        if (predictUsingCamera) {
          var currentTime = new DateTime.now().millisecondsSinceEpoch;
          if (currentTime - oldTimeCheckpoint >= 2000) {
            _predict(ImageUtils.convertYUV420ToImage(img));
            oldTimeCheckpoint = currentTime;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  initializeSensors() {
    userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      setState(() {
        // For ex: if input tensor shape [1,5] and type is float32
        var input = [
          [event.x, event.y, event.z]
        ];

        currentSensorPrediction = SensorsPredictor.predict(input);

        accelerometerEvent = event;
      });
    });
    setState(() {
      initializedSensors = true;
    });
  }

  buildAccelerometerDataDisplay() {
    return Container(
      margin: EdgeInsets.only(left: MediaQuery.of(context).size.width / 4),
      width: MediaQuery.of(context).size.width / 2,
      child: Column(
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                    title: Text(
                  LocaleKeys.AccelerometerSensor.tr(),
                )),
                ListTile(
                  leading: Icon(Icons.sensors),
                  title: initializedSensors
                      ? Text(
                          "X-" +
                              LocaleKeys.Axis.tr() +
                              " : " +
                              accelerometerEvent.x.toStringAsFixed(1),
                        )
                      : Text(""),
                ),
                ListTile(
                  leading: Icon(Icons.sensors),
                  title: initializedSensors
                      ? Text(
                          "Y-" +
                              LocaleKeys.Axis.tr() +
                              " : " +
                              accelerometerEvent.y.toStringAsFixed(1),
                        )
                      : Text(""),
                ),
                ListTile(
                  leading: Icon(Icons.sensors),
                  title: initializedSensors
                      ? Text(
                          "Z-" +
                              LocaleKeys.Axis.tr() +
                              " : " +
                              accelerometerEvent.z.toStringAsFixed(1),
                        )
                      : Text(""),
                ),
              ],
            ),
          ),
        ],
      ),
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

  updateCurrentPositionMarker(Position position, Uint8List imageData) {
    LatLng currPos = LatLng(position.latitude, position.longitude);
    circle = {
      Circle(
          circleId: CircleId("car"),
          radius: position.accuracy,
          zIndex: 1,
          strokeColor: Colors.blue,
          center: currPos,
          fillColor: Colors.blue.withAlpha(70)),
    };

    final MarkerId markerId = MarkerId(LocaleKeys.CurrentPosition.tr());

    final Marker marker = Marker(
      markerId: markerId,
      position: currPos,
      rotation: position.heading,
      icon: BitmapDescriptor.fromBytes(imageData),
      draggable: false,
      zIndex: 2,
      flat: true,
      anchor: Offset(0.5, 0.5),
      infoWindow: InfoWindow(
          title: LocaleKeys.CurrentPosition.tr(),
          snippet: LocaleKeys.CurrentPosition.tr()),
    );

    setState(() {
      markers[markerId] = marker;
    });
  }

  initializeLocation() async {
    // ignore: deprecated_member_use
    Uint8List imageData = await getMarker();
    if (!PermissionsManager.isLocationEnabled) return;
    _initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    Geolocator.getPositionStream(
            desiredAccuracy: LocationAccuracy.high,
            distanceFilter: minLocationDistance)
        .listen((Position position) {
      updateCurrentPositionMarker(position, imageData);
      _googleMapController.animateCamera(CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude)));

      if (!startedScanning)
        prevPos = LatLng(position.latitude, position.longitude);
      if (startedScanning) {
        print("current points length : ${currentPoints.length}");
        print("Current sensors pred : $currentSensorPrediction");
        LatLng currPos = LatLng(
          position.latitude,
          position.longitude,
        );

        if (currentSensorPrediction == 0) {
          if (currRoadType != 0) {
            currentPoints = [];
            if (prevPos != null) {
              currPolylinePoints.add(PolyLinePoint(
                  lat: prevPos!.latitude, long: prevPos!.longitude, type: 0));
              currentPoints.add(prevPos!);
            }

            _addNewPolyline(type: 0);
            currRoadType = 0;
          }
          currPolylinePoints.add(PolyLinePoint(
              lat: currPos.latitude, long: currPos.longitude, type: 0));

          currentPoints.add(currPos);
        }
        if (currentSensorPrediction == 1) {
          print("Into condition 1");

          if (currRoadType != 1) {
            currentPoints = [];
            if (prevPos != null) {
              currPolylinePoints.add(PolyLinePoint(
                  lat: prevPos!.latitude, long: prevPos!.longitude, type: 1));
              currentPoints.add(prevPos!);
            }

            _addNewPolyline(type: 1);
            currRoadType = 1;
          }
          currPolylinePoints.add(PolyLinePoint(
              lat: currPos.latitude, long: currPos.longitude, type: 1));

          currentPoints.add(currPos);
        }
        if (currentSensorPrediction == 2) {
          print("Into condition 2");
          if (currRoadType != 2) {
            currentPoints = [];
            if (prevPos != null) {
              currPolylinePoints.add(PolyLinePoint(
                  lat: prevPos!.latitude, long: prevPos!.longitude, type: 2));
              currentPoints.add(prevPos!);
            }
            _addNewPolyline(type: 2);

            currRoadType = 2;
            print("Reset current points");
          }
          currPolylinePoints.add(PolyLinePoint(
              lat: currPos.latitude, long: currPos.longitude, type: 2));
          currentPoints.add(currPos);
          print("Added point");
        }
        prevPos = currPos;
      }
    });

    addInitialPositionMarker();
    setState(() {
      addInitialPositionMarker();
      gotData = true;
    });
  }

  addInitialPositionMarker() {
    final MarkerId markerId = MarkerId(LocaleKeys.InitialPosition.tr());
    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(
        _initialPosition.latitude,
        _initialPosition.longitude,
      ),
      infoWindow: InfoWindow(
          title: LocaleKeys.InitialPosition.tr(),
          snippet: LocaleKeys.InitialPosition.tr()),
    );

    setState(() {
      markers[markerId] = marker;
    });
  }

  Future<Uint8List> getMarker() async {
    ByteData byteData =
        await DefaultAssetBundle.of(context).load("assets/images/car_icon.png");
    return byteData.buffer.asUint8List();
  }

  buildMap() {
    return Container(
      child: GoogleMap(
        markers: Set<Marker>.of(markers.values),
        polylines: _polyline,
        mapType: mapTypes[currentMapType],
        circles: circle,
        trafficEnabled: trafficEnabled,
        initialCameraPosition: CameraPosition(
          target: LatLng(_initialPosition.latitude, _initialPosition.longitude),
          zoom: 20,
        ),
        onMapCreated: (GoogleMapController controller) {
          _googleMapController = controller;
        },
      ),
    );
  }

  final Widget normalChildButton = SizedBox(
    width: 93,
    height: 40,
    child: Padding(
      padding: const EdgeInsets.only(left: 16, right: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
              child: Text(LocaleKeys.MapType.tr(),
                  overflow: TextOverflow.ellipsis)),
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
      title: Text(LocaleKeys.MapSettings.tr()),
      content: Container(
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(LocaleKeys.MapType.tr()),
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
            TextButton.icon(
              onPressed: fetchCloudData,
              icon: Icon(Icons.cloud_download_outlined),
              label: Text("Fetch cloud data"),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text(LocaleKeys.Traffic.tr()),
                GroupButton(
                  selectedButtons: [
                    trafficEnabled ? LocaleKeys.Show.tr() : LocaleKeys.Hide.tr()
                  ],
                  onSelected: (index, isSelected) {
                    if (index == 0)
                      setState(() {
                        trafficEnabled = true;
                      });
                    if (index == 1)
                      setState(() {
                        trafficEnabled = false;
                      });
                  },
                  buttons: [LocaleKeys.Show.tr(), LocaleKeys.Hide.tr()],
                ),
              ],
            ),
          ],
        ),
      ),
    ).show(context, transitionType: DialogTransitionType.Bubble);
  }

  drawCloudData() async {
    var pols = await PolyLinePoint.loadDownloadedPolylines();

    pols.forEach((element) {
      setState(() {
        _polyline.addAll(element);
      });
    });
  }

  fetchCloudData() async {
    await PolyLinePoint.downloadCloudData();
    drawCloudData();
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
      size: MediaQuery.of(context).size.width / 7,
      iconSize: 18.0, // Size of icons
      borderWidth: 1.0, // Width of panel border
      borderColor: Colors.black, // Color of panel border

      onPressed: (index) {
        if (index == 0) buildMapSettingsPopup();
        if (index == 1) {
          setState(() {
            if (mapIsMainPage) showCamera = !showCamera;
          });
        }
        if (index == 2)
          setState(() {
            showSensors = !showSensors;
          });
        if (index == 3) {
          if (showCamera)
            setState(() {
              mapIsMainPage = !mapIsMainPage;
            });
          else {
            Fluttertoast.showToast(msg: LocaleKeys.EnableCamera.tr());
          }
        }
        if (index == 4) {
          setState(() {
            predictUsingSensors = !predictUsingSensors;
          });
        }
        if (index == 5) {
          setState(() {
            predictUsingCamera = !predictUsingCamera;
          });
        }
      },
      buttons: [
        Icons.map_outlined,
        showCamera ? Icons.camera_enhance_outlined : Icons.camera,
        showSensors ? Icons.sensors_off : Icons.sensors,
        showCamera ? Icons.fullscreen : Icons.fullscreen_exit,
        predictUsingSensors ? Icons.sensors_off : Icons.sensors,
        predictUsingCamera
            ? Icons.camera_indoor_sharp
            : Icons.linked_camera_outlined,
      ],
    );
  }

  handleCameraPreviewClick() {
    if (isCameraPreviewZoomedIn) {
      setState(() {
        cameraPreviewHeight = 200;
        cameraPreviewWidth = 100;
        isCameraPreviewZoomedIn = false;
      });
    } else {
      setState(() {
        cameraPreviewHeight = 400;
        cameraPreviewWidth = 200;
        isCameraPreviewZoomedIn = true;
      });
    }
  }

  handleCameraPreviewPan(double dx, double dy) {
    if (cameraPreviewRight >= 0) {
      setState(() {
        cameraPreviewRight -= dx;
      });
    }
    if (cameraPreviewTop >= 0) {
      setState(() {
        cameraPreviewTop += dy;
      });
    }

    if (cameraPreviewRight < 0) cameraPreviewRight = 0;
    if (cameraPreviewTop < 0) cameraPreviewTop = 0;
    if (cameraPreviewRight >
        MediaQuery.of(context).size.width - cameraPreviewWidth)
      cameraPreviewRight =
          MediaQuery.of(context).size.width - cameraPreviewWidth;

    if (cameraPreviewTop >
        MediaQuery.of(context).size.height - cameraPreviewHeight - 150)
      cameraPreviewTop =
          MediaQuery.of(context).size.height - cameraPreviewHeight - 150;
  }

  buildCameraView() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 100),
      top: cameraPreviewTop,
      right: cameraPreviewRight,
      child: GestureDetector(
        onPanUpdate: (dragUpdate) {
          handleCameraPreviewPan(dragUpdate.delta.dx, dragUpdate.delta.dy);
        },
        onTap: handleCameraPreviewClick,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
          height: cameraPreviewHeight,
          width: cameraPreviewWidth,
          color: Colors.red,
          child: CameraPreview(
            _cameraController,
          ),
        ),
      ),
    );
  }

  buildMapSmallView() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 100),
      top: cameraPreviewTop,
      right: cameraPreviewRight,
      child: GestureDetector(
        onPanUpdate: (dragUpdate) {
          handleCameraPreviewPan(dragUpdate.delta.dx, dragUpdate.delta.dy);
        },
        onLongPress: handleCameraPreviewClick,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
          height: cameraPreviewHeight,
          width: cameraPreviewWidth,
          color: Colors.black,
          child: buildMap(),
        ),
      ),
    );
  }

  buildCameraMainView() {
    return Container(
      child: CameraPreview(
        _cameraController,
      ),
    );
  }

  startScanning() async {
    print(await DatabaseManager.getAllPolylines());
    watch.start();
    initializeLocation();
  }

  stopScanning() async {
    print(currPolylinePoints.length);
    await PolyLinePoint.savePolylinePointsToLocal(currPolylinePoints);
    _googleMapController.takeSnapshot().then((u8IntListImage) async {
      await PolyLinePoint.savePolylineSnaphotToLocal(u8IntListImage);
    });

    currPolylinePoints.clear();
    markers.clear();
    _polyline.clear();
    watch.stop();
    watch.reset();
  }

  String buildPredictionText() {
    String retString = "";
    if (predictUsingCamera) retString += category!.label.split(" ").last;
    if (predictUsingSensors && currentSensorPrediction != -1)
      retString += " " + SensorsPredictor.labels[currentSensorPrediction];
    if (!predictUsingCamera && !predictUsingSensors)
      retString = "Predictors not enabled";
    return retString;
  }

  buildPredictionPanel() {
    return Positioned(
      bottom: 60,
      left: MediaQuery.of(context).size.width / 4,
      child: Text(
        buildPredictionText(),
        style: TextStyle(fontSize: 20),
      ),
    );
  }

  buildStartStopButton() {
    return Positioned(
      bottom: 0,
      left: MediaQuery.of(context).size.width / 4,
      child: AnimatedButton(
        height: 50,
        width: MediaQuery.of(context).size.width / 2,
        text: !startedScanning
            ? LocaleKeys.Start.tr()
            : LocaleKeys.Stop.tr() + ': ${watch.elapsed.inSeconds.toString()}',
        isReverse: startedScanning,
        isSelected: startedScanning,
        selectedTextColor: Colors.black,
        backgroundColor: Colours.white,
        gradient: LinearGradient(colors: [Colours.blue, Colours.cyan]),
        transitionType: TransitionType.TOP_CENTER_ROUNDER,
        borderColor: Colors.white,
        borderRadius: 50,
        borderWidth: 2,
        textStyle: TextStyle(
            fontSize: 28,
            letterSpacing: 5,
            color: Colors.deepOrange,
            fontWeight: FontWeight.w300),
        onPress: () {
          setState(() {
            if (!startedScanning)
              startScanning();
            else
              stopScanning();
            startedScanning = !startedScanning;
          });
        },
      ),
    );
  }

  List<Widget> buildMapMainPageUI() {
    return <Widget>[
      gotData ? buildMap() : Text(LocaleKeys.FetchingLocation.tr()),
      if (showSensors) buildAccelerometerDataDisplay(),
      if (showCamera) buildCameraView(),
      buildPredictionPanel(),
      buildStartStopButton(),
    ];
  }

  buildCameraBottomControls() {
    return Container(
      alignment: Alignment.bottomCenter,
      margin: EdgeInsets.only(left: MediaQuery.of(context).size.width / 4),
      width: MediaQuery.of(context).size.width / 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () async {
                    var f = await _cameraController.takePicture();
                    print(f.path);
                  },
                  icon: Icon(Icons.camera),
                  iconSize: 45,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> buildCamerMainPageUI() {
    return <Widget>[
      buildCameraMainView(),
      buildMapSmallView(),
      buildCameraBottomControls(),
    ];
  }

  buildLoadingScreen() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          lottie.Lottie.asset(
            "assets/lottie/gps_sattelite_orbit.json",
            animate: true,
            repeat: true,
            alignment: Alignment.center,
          ),
          TextButton.icon(
            onPressed: initializeLocation,
            icon: Icon(Icons.location_on_outlined),
            label: Text("Try again"),
          ),
        ],
      ),
    );
  }

  buildPermissionsScreen() {
    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(1.5),
      scrollDirection: Axis.vertical,
      crossAxisCount: 2,
      childAspectRatio: 0.80,
      mainAxisSpacing: 1.0,
      shrinkWrap: true,
      crossAxisSpacing: 1,
      children: [
        !PermissionsManager.isLocationEnabled
            ? Column(
                children: [
                  lottie.LottieBuilder.asset(
                    "assets/lottie/location_marker.json",
                    animate: true,
                    repeat: true,
                    width: MediaQuery.of(context).size.width / 4,
                    height: MediaQuery.of(context).size.width / 4,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Fluttertoast.showToast(msg: "Please enable location");
                      PermissionsManager.enableLocation();
                    },
                    icon: Icon(Icons.location_on_outlined, size: 18),
                    label: Text("Enable location"),
                  )
                ],
              )
            : Text(""),
        !PermissionsManager.locationPermissionsAccepted
            ? Column(
                children: [
                  lottie.LottieBuilder.asset(
                    "assets/lottie/location_permissions.json",
                    animate: true,
                    repeat: true,
                    reverse: true,
                    width: MediaQuery.of(context).size.width / 4,
                    height: MediaQuery.of(context).size.width / 4,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Fluttertoast.showToast(
                          msg: "Please accept location permissions");
                      PermissionsManager.askForLocationPermissions();
                    },
                    icon: Icon(Icons.location_on_outlined, size: 18),
                    label: Text("Location permissions"),
                  )
                ],
              )
            : Text(""),
        !PermissionsManager.storagePermissionsAccepted
            ? Column(
                children: [
                  lottie.LottieBuilder.asset(
                    "assets/lottie/storage_permissions.json",
                    animate: true,
                    repeat: true,
                    reverse: true,
                    width: MediaQuery.of(context).size.width / 4,
                    height: MediaQuery.of(context).size.width / 4,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Fluttertoast.showToast(
                          msg: "Please accept storage permissions");
                      PermissionsManager.askForStoragePermissions();
                    },
                    icon: Icon(Icons.storage_rounded, size: 18),
                    label: Text("Storage permissions"),
                  )
                ],
              )
            : Text(""),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: (PermissionsManager.isLocationEnabled &&
                PermissionsManager.locationPermissionsAccepted &&
                PermissionsManager.storagePermissionsAccepted)
            ? [
                if (!gotData) buildLoadingScreen(),
                if (mapIsMainPage & gotData) ...buildMapMainPageUI(),
                if (!mapIsMainPage & gotData) ...buildCamerMainPageUI(),
                if (gotData) buildFloatingBox(),
              ]
            : [
                buildPermissionsScreen(),
              ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("State changed");
    if (state == AppLifecycleState.resumed) {
      print("back to app");
      PermissionsManager.checkPermissions();
      setState(() {});
    }
  }
}
