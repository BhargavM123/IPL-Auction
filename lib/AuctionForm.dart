import 'dart:math';
import 'HomePage.dart';
import 'UsersItem.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuctionForm extends StatefulWidget {
  @override
  _AuctionFormState createState() => _AuctionFormState();
}

class _AuctionFormState extends State<AuctionForm> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Future<FirebaseApp> _future = Firebase.initializeApp();
  User user;
  final databaseRef = FirebaseDatabase.instance.reference().child("User");
  bool isloggedin = false;
  bool isloading = false;
  final name = TextEditingController();
  final description = TextEditingController();
  final min_bidprice = TextEditingController();
  final _date = TextEditingController();
  DateTime _selectedDate;
  final picker = ImagePicker();
  File sampleImage;

  Future getImage() async {
    var tempImage = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      sampleImage = tempImage;
    });
  }

  checkAuthentification() async {
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        Navigator.of(context).pushReplacementNamed("start");
      }
    });
  }

  Future<void> addData(File sampleImage, String name, String des, String min_bid, String date) async {
    String fileName = sampleImage.path;
    StorageReference firebaseStorageRef =
        FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = firebaseStorageRef.putFile(sampleImage);
    StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
    String url = (await taskSnapshot.ref.getDownloadURL());
    print('URL Is $url');
    databaseRef.push().set({
      'Name': name,
      'Description': des,
      'Minimum_Bid_Price': min_bid,
      'ImageURL': url,
      'End_Date': date,
      'UserID': user.uid,
      'AuctionID': randomID()
    });
    gotoHomePage();
  }

  String randomID() {
    var r = Random();
    return String.fromCharCodes(
        List.generate(7, (index) => r.nextInt(33) + 89));
  }

  void gotoHomePage() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return new HomePage();
    }));
  }

  getUser() async {
    User firebaseUser = _auth.currentUser;
    await firebaseUser?.reload();
    firebaseUser = _auth.currentUser;

    if (firebaseUser != null) {
      setState(() {
        this.user = firebaseUser;
        this.isloggedin = true;
      });
    }
  }

  signOut() async {
    _auth.signOut();

    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
  }

  @override
  void initState() {
    super.initState();
    this.checkAuthentification();
    this.getUser();
  }

  void printFirebase() {
    databaseRef.once().then((DataSnapshot snapshot) {
      print('Data : ${snapshot.value}');
    });
  }

  showPopupMenu() {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(25.0, 25.0, 0.0, 0.0),
      //position where you want to show the menu on screen
      items: [
        PopupMenuItem<String>(child: Row(
          children: [
            Icon(Icons.chrome_reader_mode),
            SizedBox(
              // sized box with width 10
              width: 10,
            ),
            Text("My Items"),
          ],
        ), value: '1'),
        PopupMenuItem<String>(child: Row(
          children: [
            Icon(Icons.logout),
            SizedBox(
              // sized box with width 10
              width: 10,
            ),
            Text("Logout")
          ],
        ), value: '2'),
      ],
      elevation: 8.0,
    ).then<void>((String itemSelected) {
      if (itemSelected == null) return;

      if (itemSelected == "1") {
        userItems();
      } else {
        //code here
        signOut();
      }
    });
  }

  void userItems() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return new UsersItem();
    }));
  }

  Widget enableUpload() {
    return Container(
      child: Column(
        children: <Widget>[
          Image.file(sampleImage, height: 200.0, width: 300.0),
        ],
      ),
    );
  }

  _selectDate(BuildContext context) async {
    DateTime newSelectedDate = await showDatePicker(
        context: context,
        initialDate: _selectedDate != null ? _selectedDate : DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2040),
        builder: (BuildContext context, Widget child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: Colors.deepPurple,
                onPrimary: Colors.white,
                surface: Colors.lightBlueAccent,
                onSurface: Colors.black54,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child,
          );
        });

    if (newSelectedDate != null) {
      _selectedDate = newSelectedDate;
      _date
        ..text = DateFormat.yMMMd().format(_selectedDate)
        ..selection = TextSelection.fromPosition(TextPosition(
            offset: _date.text.length, affinity: TextAffinity.upstream));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.teal.shade50,
        appBar: AppBar(
          title: Text("Player Auction Form"),
          actions: [
            IconButton(
              onPressed: showPopupMenu,
              icon: Icon(Icons.more_vert),
            ),
          ],
        ),
        body: FutureBuilder(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              } else {
                return Container(
                  margin: EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: !isloggedin
                      ? SizedBox(
                          height: MediaQuery.of(context).size.height / 1.3,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Column(
                          children: <Widget>[
                            SizedBox(height: 10.0),
                            Padding(
                              padding: EdgeInsets.all(10.0),
                              child: ElevatedButton(
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        Colors.teal)),
                                child: sampleImage == null
                                    ? Text('Upload Player Image')
                                    : enableUpload(),
                                onPressed: getImage,
                              ),
                            ),
                            SizedBox(height: 10.0),
                            Padding(
                              padding: EdgeInsets.all(10.0),
                              child: TextField(
                                  controller: name,
                                  decoration: InputDecoration(
                                    hintText: 'Player Name',
                                  )),
                            ),
                            SizedBox(height: 10.0),
                            Padding(
                              padding: EdgeInsets.all(10.0),
                              child: TextField(
                                  controller: description,
                                  decoration: InputDecoration(
                                    hintText: 'Player Description',
                                  )),
                            ),
                            SizedBox(height: 10.0),
                            Padding(
                              padding: EdgeInsets.all(10.0),
                              child: TextField(
                                  controller: min_bidprice,
                                  decoration: InputDecoration(
                                    hintText: 'Base Value',
                                  )),
                            ),
                            SizedBox(height: 10.0),
                            Padding(
                              padding: EdgeInsets.all(10.0),
                              child: TextField(
                                focusNode: AlwaysDisabledFocusNode(),
                                decoration: InputDecoration(
                                    hintText: 'Auction End DateTime'),
                                controller: _date,
                                onTap: () {
                                  _selectDate(context);
                                },
                              ),
                            ),
                            SizedBox(height: 20.0),
                            Center(
                                child: ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                                Colors.teal)),
                                    child: Text("SUBMIT"),
                                    onPressed: () {
                                      addData(
                                          sampleImage,
                                          name.text,
                                          description.text,
                                          min_bidprice.text,
                                          _date.text);
                                      //CircularProgressIndicator();//call method flutter upload
                                    })),
                          ],
                        ),
                );
              }
            }));
  }
}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}
