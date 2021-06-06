import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsManager {
  static bool locationPermissionsAccepted = false;
  static bool cameraPermissionsAccepted = false;
  static bool storagePermissionsAccepted = false;
  static bool isLocationEnabled = false;

  static checkPermissions() async {
    isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    locationPermissionsAccepted = await Permission.location.isGranted;
    cameraPermissionsAccepted = await Permission.camera.isGranted;
    storagePermissionsAccepted = (await Permission.storage.isGranted);

    print("Location : $locationPermissionsAccepted");
    print("isLocation Enabled : $isLocationEnabled");
    print("Storage : $storagePermissionsAccepted");
    print("Camera : $cameraPermissionsAccepted");
  }

  static Future<bool> enableLocation() async {
    return Geolocator.openLocationSettings();
  }

  static askForLocationPermissions() async {
    await Geolocator.requestPermission();
    await Permission.location.request();
    await Permission.locationAlways.request();
    await Permission.locationWhenInUse.request();
    if (await Permission.location.isDenied) {
      Fluttertoast.showToast(msg: "Please change location settings");
      Geolocator.openAppSettings();
    }
  }

  static askForStoragePermissions() {
    Permission.manageExternalStorage.request();
    Permission.storage.request();
  }

  static askForCameraPermissions() {
    Permission.camera.request();
  }
}
