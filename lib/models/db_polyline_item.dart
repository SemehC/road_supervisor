class DbPolyline {
  final int id;
  final String fileLocation;
  final String imageLocation;
  final bool uploadStatus;
  final String onlineId;

  DbPolyline({
    this.id = 0,
    required this.fileLocation,
    this.uploadStatus = false,
    this.imageLocation = "",
    this.onlineId = "",
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileLocation': fileLocation,
      'uploadStatus': uploadStatus,
      'imageLocation': imageLocation,
    };
  }

  Map<String, dynamic> toCloudMap() {
    return {
      'id': id,
      'fileLocation': fileLocation,
      'uploadStatus': uploadStatus,
      'imageLocation': imageLocation,
      'networkId': onlineId,
    };
  }
}
