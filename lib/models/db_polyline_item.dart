class DbPolyline {
  final int id;
  final String fileLocation;
  final String imageLocation;
  final bool uploadStatus;

  DbPolyline({
    this.id = 0,
    required this.fileLocation,
    this.uploadStatus = false,
    required this.imageLocation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileLocation': fileLocation,
      'uploadStatus': uploadStatus,
      'imageLocation': imageLocation,
    };
  }
}
