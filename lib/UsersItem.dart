import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'AuctionForm.dart';
import 'ItemDetails.dart';
import 'Posts.dart';
import 'HomePage.dart';

class UsersItem extends StatefulWidget {
  final String current_user_id = null;

  @override
  _UsersItemState createState() => _UsersItemState();
}

class _UsersItemState extends State<UsersItem> {
  List<Posts> postsList = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final databaseRef = FirebaseDatabase.instance.reference().child("User");
  FirebaseStorage storage = FirebaseStorage.instance;
  User user;

  bool isloggedin = false;
  final Future<FirebaseApp> _future = Firebase.initializeApp();

  checkAuthentification() async {
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        Navigator.of(context).pushReplacementNamed("start");
      }
    });
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

  @override
  void initState() {
    super.initState();
    this.checkAuthentification();
    this.getUser();
    DatabaseReference postsRef =
        FirebaseDatabase.instance.reference().child("User");
    final String current_user_id = _auth.currentUser.uid;

    postsRef.once().then((DataSnapshot snap) {
      var KEYS = snap.value.keys;
      var DATA = snap.value;

      postsList.clear();

      for (var individualKey in KEYS) {
        Posts posts = new Posts(
            DATA[individualKey]['Name'],
            DATA[individualKey]['Description'],
            DATA[individualKey]['Minimum_Bid_Price'],
            DATA[individualKey]['ImageURL'],
            DATA[individualKey]['End_Date'],
            DATA[individualKey]['AuctionID']);

        print(current_user_id);
        if (DATA[individualKey]['UserID'] == current_user_id) {
          postsList.add(posts);
        }
      }

      setState(() {
        print('Length : $postsList.length');
      });
    });
  }

  signOut() async {
    _auth.signOut();

    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
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
            Text("My Items")
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
        ), value: '3'),
      ],
      elevation: 8.0,
    ).then<void>((String itemSelected) {
      if (itemSelected == null) return;

      if (itemSelected == "1") {
        //code here
      } else {
        //code here
        signOut();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        centerTitle: true,
        title: Text('My Items'),
        leading: IconButton(
          onPressed: () {
            debugPrint("Form button clicked");
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return HomePage();
            }));
          },
          icon: Icon(Icons.home),
        ),
        actions: [
          IconButton(
            onPressed: showPopupMenu,
            icon: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: new Container(
        child: postsList.length == 0
            ? new Text("")
            : new ListView.builder(
                itemCount: postsList.length,
                itemBuilder: (_, index) {
                  return PostUI(
                      index,
                      postsList[index].ImageURL,
                      postsList[index].Description,
                      postsList[index].End_Date,
                      postsList[index].Minimum_Bid_Price,
                      postsList[index].Name,
                      postsList[index].AuctionID);
                }),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          debugPrint("Form button clicked");
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return AuctionForm();
          }));
        },
      ),
    );
  }

  Widget PostUI(int index, String image, String description, String date,
      String minBid, String name, String auctionID) {
    return new GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetails(),
              settings: RouteSettings(
                arguments: postsList[index],
              ),
            ),
          );
        },
        child: Card(
          elevation: 10.0,
          margin: EdgeInsets.all(15.0),
          child: new Container(
            padding: new EdgeInsets.all(14.0),
            child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      new Text(
                        name,
                        style: Theme.of(context).textTheme.subtitle1,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  new Image.network(image, fit: BoxFit.cover),
                  SizedBox(
                    height: 10.0,
                  ),
                ]),
          ),
        ));
  }
}
