import 'dart:async';
// import 'dart:core';
// import 'dart:js';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project/assistants/assistant_methods.dart';
import 'package:project/global/global.dart';
import 'package:project/info_handler/app_info.dart';
import 'package:project/screens/result_screen.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../models/directions.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  final pickUpTextEditingController = TextEditingController();
  final dropOffTextEditingController = TextEditingController();
  final seatTextEditingController = TextEditingController();

  String responseData = '';

  final _formKey = GlobalKey<FormState>();
  
  void _submit() async {

    if (_formKey.currentState!.validate()) {
      Future<void> sendData(BuildContext context) async {
        final Uri uri = Uri.parse('');

        final Map<String, dynamic> formData = {
          'pickup': pickUpTextEditingController.text.trim(),
          'dropoff': dropOffTextEditingController.text.trim(),
          'seats': seatTextEditingController.text.trim(),
        };

        // final queryParameter = {
        //   'pickup': pickUpTextEditingController.text.trim(),
        //   'dropoff': dropOffTextEditingController.text.trim(),
        //   'seats': seatTextEditingController.text.trim(),
        // };

        try {
          final response = await http.put(uri, body: formData);

          if (response.statusCode == 200) {
            setState(() {
              responseData = response.body;
            });
            await Fluttertoast.showToast(msg: 'Successfully Booked');
            // Navigator.push(context, MaterialPageRoute(builder: (c) => ResultScreen()));
          } else {
            await Fluttertoast.showToast(msg: 'Error ${response.statusCode}');
          }
        } catch (error) {
          await Fluttertoast.showToast(msg: 'Error $error');
        }
      }
    }

    //   validate all the form fields
    // if (_formKey.currentState!.validate()) {
    //   await firebaseAuth.createUserWithEmailAndPassword(
    //     email: emailTextEditingController.text.trim(),
    //     password: passwordTextEditingController.text.trim(),
    //   ).then((auth) async {
    //     currentUser = auth.user;
    //     if (currentUser != null) {
    //       Map userMap = {
    //         "id": currentUser!.uid,
    //         "name": nameTextEditingController.text.trim(),
    //         "email": emailTextEditingController.text.trim(),
    //         "phone": phoneTextEditingController.text.trim(),
    //         "address": addressTextEditingController.text.trim(),
    //       };
    //
    //       DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users");
    //       userRef.child(currentUser!.uid).set(userMap);
    //     }
    //
    //     await Fluttertoast.showToast(msg: 'Successfully Registered');
    //     Navigator.push(context, MaterialPageRoute(builder: (c) => MainScreen()));
    //   }).catchError((errorMessage) {
    //     Fluttertoast.showToast(msg: "Error!! \n $errorMessage");
    //   });
    // }
    // if (_formKey.currentState!.validate()) {
    //   Fluttertoast.showToast(msg: "Auto booked");
    // } else {
    //   Fluttertoast.showToast(msg: "Not all fields are valid");
    // }
  }

  // String _dropdownValue = '1';
  //
  // var _items = [
  //   '1',
  //   '2',
  //   '3',
  //   '4',
  // ];

  LatLng? pickLocation;
  loc.Location location = loc.Location();
  String? _address;

  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();

  double searchLocationContainerHeight = 220;
  double waitingResponseFromDriverContainerWidget = 0;
  double assignedDriverInfoContainerWidget = 0;

  Position? userCurrentPosition;
  var geoLocation = Geolocator();

  LocationPermission? _locationPermission;
  double bottomPaddingOfMap = 0;

  List<LatLng> pLineCoordinatedList = [];
  Set<Polyline> polyLineSet = {};

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  String userName = "";
  String userEmail = "";

  bool openNavigatorDrawer = true;
  bool activeNearbyDriverKeysLoaded = false;

  BitmapDescriptor? activeNearbyIcon;


  locateUserPosition() async {
    Position cPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = cPosition;

    LatLng latLngPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
    CameraPosition cameraPosition = CameraPosition(target: latLngPosition, zoom: 15);

    newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String humanReadableAddress = await AssistantMethods.searchAddressForGeographicCoordinates(userCurrentPosition!, context);
    print("This is our address = $humanReadableAddress");

    userName = userModelCurrentInfo!.name!;
    userEmail = userModelCurrentInfo!.email!;

    // initializeGeofireListener();
    // AssistantMethods.readTripKeysForOnlineUser(context);
  }

  getAddressFromLatLng() async {
    try {
      GeoData data = await Geocoder2.getDataFromCoordinates(
        latitude: pickLocation!.latitude,
        longitude: pickLocation!.longitude,
        googleMapApiKey: "",
      );
      setState(() {
        Directions userPickUpAddress = Directions();
        userPickUpAddress.locationLatitude = pickLocation!.latitude;
        userPickUpAddress.locationLongitude = pickLocation!.longitude;
        userPickUpAddress.locationName = data.address;

        Provider.of<AppInfo>(context, listen: false).updatePickUpLocationAddress(userPickUpAddress);

        // _address = data.address;
      });
    } catch (e) {
      print(e);
    }
  }

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();

    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  // final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {

    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;


    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(0.0),
          children: [
            Column(
              children: [
                const SizedBox(height: 10.0,),
                Text(
                  'User Journey Details',
                  style: TextStyle(
                    color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20.0,),

                Padding(
                  padding: const EdgeInsets.fromLTRB(15.0, 20.0, 15.0, 50.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextFormField(
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(null),
                              ],
                              decoration: InputDecoration(
                                hintText: 'Enter Pick Up Location',
                                hintStyle: const TextStyle(
                                  color: Colors.grey,
                                ),
                                filled: true,
                                fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(40.0),
                                  borderSide: const BorderSide(
                                    width: 0,
                                    style: BorderStyle.none,
                                  ),
                                ),
                                prefixIcon: Icon(Icons.location_on_outlined, color: darkTheme ? Colors.amber.shade400 : Colors.grey,),
                              ),
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (text) {
                                if (text == null || text.isEmpty) {
                                  return 'Pick Up Location can\'t be empty';
                                }
                                if (text.length < 2) {
                                  return 'Please enter a valid pick up location';
                                }
                              },
                              onChanged: (text) => setState(() {
                                pickUpTextEditingController.text = text;
                              }),
                            ),

                            const SizedBox(height: 10.0,),

                            TextFormField(
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(null),
                              ],
                              decoration: InputDecoration(
                                hintText: 'Enter Drop Off Location',
                                hintStyle: const TextStyle(
                                  color: Colors.grey,
                                ),
                                filled: true,
                                fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(40.0),
                                  borderSide: const BorderSide(
                                    width: 0,
                                    style: BorderStyle.none,
                                  ),
                                ),
                                prefixIcon: Icon(Icons.location_on, color: darkTheme ? Colors.amber.shade400 : Colors.grey,),
                              ),
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (text) {
                                if (text == null || text.isEmpty)
                                {
                                  return 'Drop Off location can\'t be empty';
                                }
                                // if (EmailValidator.validate(text) == true) {
                                //   return null;
                                // }
                                if (text.length < 2)
                                {
                                  return 'Please enter a valid location';
                                }
                                // if (text.length > 99)
                                // {
                                //   return 'Email can\'t be more than 100 characters';
                                // }
                              },
                              onChanged: (text) => setState(() {
                                dropOffTextEditingController.text = text;
                              }),
                            ),

                            const SizedBox(height: 10.0,),

                            TextFormField(
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(null),
                              ],
                              decoration: InputDecoration(
                                hintText: 'Enter Number of Seats between 1 to 4',
                                hintStyle: const TextStyle(
                                  color: Colors.grey,
                                ),
                                filled: true,
                                fillColor: darkTheme ? Colors.black45 : Colors.grey.shade200,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(40.0),
                                  borderSide: const BorderSide(
                                    width: 0,
                                    style: BorderStyle.none,
                                  ),
                                ),
                                prefixIcon: Icon(Icons.people_alt, color: darkTheme ? Colors.amber.shade400 : Colors.grey,),
                              ),
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (text) {
                                if (text == null || text.isEmpty)
                                {
                                  return 'Number of seats can\'t be empty';
                                }
                                // if (EmailValidator.validate(text) == true) {
                                //   return null;
                                // }
                                // if (text.length < 2)
                                // {
                                //   return 'Please enter a valid email';
                                // }
                                // if (text.length > 1)
                                // {
                                //   return 'Email can\'t be more than 100 characters';
                                // }
                              },
                              onChanged: (text) => setState(() {
                                seatTextEditingController.text = text;
                              }),
                            ),

                            const SizedBox(height: 10.0,),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: darkTheme ? Colors.black : Colors.white,
                                backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32.0),
                                ),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              onPressed: () {
                                _submit();
                              },
                              child: const Text(
                                'Search Ride',
                                style: TextStyle(
                                  fontSize: 20.0,
                                ),
                              ),
                            ),

                            const SizedBox(height: 10.0,),

                            Text(responseData),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );

    // return GestureDetector(
    //   onTap: () {
    //     FocusScope.of(context).unfocus();
    //   },
    //   child: Scaffold(
    //     body: Stack(
    //       children: [
    //         GoogleMap(
    //           initialCameraPosition: _kGooglePlex,
    //           mapType: MapType.normal,
    //           myLocationEnabled: true,
    //           zoomControlsEnabled: true,
    //           zoomGesturesEnabled: true,
    //           polylines: polyLineSet,
    //           markers: markersSet,
    //           circles: circlesSet,
    //           onMapCreated: (GoogleMapController controller) {
    //             _controllerGoogleMap.complete(controller);
    //             newGoogleMapController = controller;
    //
    //             setState(() {
    //
    //             });
    //
    //             locateUserPosition();
    //           },
    //           onCameraMove: (CameraPosition? position) {
    //             if (pickLocation != position!.target) {
    //               setState(() {
    //                 pickLocation = position.target;
    //               });
    //             }
    //           },
    //           onCameraIdle: () {
    //             getAddressFromLatLng();
    //           },
    //         ),
    //         Align(
    //           alignment: Alignment.center,
    //           child: Padding(
    //             padding: const EdgeInsets.only(bottom: 35.0),
    //             child: Image.network("https://media.istockphoto.com/id/1135275961/vector/location-icon.jpg?s=612x612&w=is&k=20&c=jBi3l0UBU3paubj0F9zWKD6kND5-lo8D9nk6srYzhFo=", height: 45, width: 45,),
    //           ),
    //         ),
    //         Positioned(
    //           bottom: 0,
    //           left: 0,
    //           right: 0,
    //           child: Padding(
    //             padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
    //             child: Column(
    //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //               children: [
    //                 Container(
    //                   padding: const EdgeInsets.all(10),
    //                   decoration: BoxDecoration(
    //                     borderRadius: BorderRadius.circular(10),
    //                     color: darkTheme ? Colors.grey.shade900 : Colors.grey.shade100,
    //                   ),
    //                   child: Column(
    //                     children: [
    //                       Padding(
    //                         padding: const EdgeInsets.all(5),
    //                         child: Row(
    //                           children: [
    //                             Icon(Icons.location_on_outlined, color: darkTheme ? Colors.amber.shade400 : Colors.blue,),
    //                             const SizedBox(width:10,),
    //                             Column(
    //                               crossAxisAlignment: CrossAxisAlignment.start,
    //                               children: [
    //                                 Text(
    //                                   "From",
    //                                   style: TextStyle(
    //                                     color: darkTheme ? Colors.amber.shade400 : Colors.blue,
    //                                     fontSize: 12,
    //                                     fontWeight: FontWeight.bold,
    //                                   ),
    //                                 ),
    //                                 Text(
    //                                   Provider.of<AppInfo>(context).userPickUpLocation != null ? "${(Provider.of<AppInfo>(context).userPickUpLocation!.locationName!).substring(0, 24)}..." : "Not getting address",
    //                                   style: const TextStyle(color: Colors.grey, fontSize: 14),
    //                                 )
    //                               ],
    //                             )
    //                           ],
    //                         ),
    //                       ),
    //
    //                       const SizedBox(height: 5,),
    //
    //                       Divider(
    //                         height: 1,
    //                         thickness: 2,
    //                         color: darkTheme ? Colors.amber.shade400 : Colors.blue,
    //                       ),
    //
    //                       const SizedBox(height: 5,),
    //
    //                       Padding(
    //                         padding: const EdgeInsets.all(5),
    //                         child: GestureDetector(
    //                           onTap: () {},
    //                           child: Row(
    //                             children: [
    //                               Icon(Icons.location_on_outlined, color: darkTheme ? Colors.amber.shade400 : Colors.blue,),
    //                               const SizedBox(width:10,),
    //                               Column(
    //                                 crossAxisAlignment: CrossAxisAlignment.start,
    //                                 children: [
    //                                   Text(
    //                                     "From",
    //                                     style: TextStyle(
    //                                       color: darkTheme ? Colors.amber.shade400 : Colors.blue,
    //                                       fontSize: 12,
    //                                       fontWeight: FontWeight.bold,
    //                                     ),
    //                                   ),
    //                                   Text(
    //                                     Provider.of<AppInfo>(context).userPickUpLocation != null ? "${(Provider.of<AppInfo>(context).userPickUpLocation!.locationName!).substring(0, 24)}..." : "Not getting address",
    //                                     style: const TextStyle(color: Colors.grey, fontSize: 14),
    //                                   )
    //                                 ],
    //                               )
    //                             ],
    //                           ),
    //                           ),
    //                         ),
    //                     ],
    //                   ),
    //                 )
    //               ],
    //             ),
    //           ),
    //         ),
            
            
            // Positioned(
            //   top: 40,
            //   right: 20,
            //   left: 20,
            //   child: Container(
            //     decoration: BoxDecoration(
            //       border: Border.all(color: Colors.black),
            //       color: Colors.white,
            //     ),
            //     padding: const EdgeInsets.all(20.0),
            //     child: Text(
            //       Provider.of<AppInfo>(context).userPickUpLocation != null ? "${(Provider.of<AppInfo>(context).userPickUpLocation!.locationName!).substring(0, 24)}..." : "Not getting addresses",
            //       overflow: TextOverflow.visible,
            //       softWrap: true,
            //     ),
            //   ),
            // )
    //       ],
    //     ),
    //   ),
    // );
  }
}
