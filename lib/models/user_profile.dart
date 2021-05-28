import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String fullName;
  final String carType;
  final Timestamp? joinDate;
  final String photoUrl;
  UserProfile({
    required this.photoUrl,
    required this.fullName,
    required this.carType,
    this.joinDate,
  });

  static parseDoc(DocumentSnapshot doc) {
    return UserProfile(
      photoUrl: doc['photoUrl'] != null ? doc['photoUrl'] : "none",
      carType: doc['CarType'] != null ? doc['CarType'] : "none",
      fullName: doc['FullName'] != null ? doc['FullName'] : "none",
      joinDate: doc['CreationTime'],
    );
  }
}
