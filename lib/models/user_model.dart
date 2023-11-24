import 'package:firebase_database/firebase_database.dart';

class UserModel {
  String? phone;
  String? name;
  String? id;
  String? email;
  String? address;

  UserModel({
    this.name,
    this.phone,
    this.id,
    this.email,
    this.address,
  });

  UserModel.fromSnapShot(DataSnapshot snap) {
    id = snap.key;
    phone = (snap.value as dynamic)["phone"];
    name = (snap.value as dynamic)["name"];
    address = (snap.value as dynamic)["address"];
    email = (snap.value as dynamic)["email"];
  }
}
