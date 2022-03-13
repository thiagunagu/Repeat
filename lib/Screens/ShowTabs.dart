import 'package:repeat/CustomWidgets/ItemFilterProvider.dart';
import 'package:repeat/CustomWidgets/UserTypeProvider.dart';
import 'package:flutter/material.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:another_flushbar/flushbar.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';

import 'package:repeat/Models/InvitationPendingResponse.dart';
import 'package:repeat/Models/SignedInUser.dart';
import 'package:repeat/Models/UserDocument.dart';

import 'package:repeat/Screens/AddItem.dart';
import 'package:repeat/Screens/CheckList.dart';
import 'package:repeat/Screens/StarredItemsTab.dart';

import 'package:in_app_review/in_app_review.dart';


class ShowTabs extends StatefulWidget {
  @override
  _ShowTabsState createState() => _ShowTabsState();
}

class _ShowTabsState extends State<ShowTabs> {
  GlobalKey<ScaffoldState> _drawerKey = GlobalKey();
  final InAppReview inAppReview = InAppReview.instance;
  bool bottomSheetActive = false;
  double bottomSheetHeight=0;
  final bottomSheetKey = GlobalKey();


  @override
  Widget build(BuildContext context) {
    bool _numOfItemsLimitReached = false;
    var userEmail = Provider.of<SignedInUser>(context, listen: true).userEmail;

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      final sheetHeight=bottomSheetKey.currentContext?.size?.height??0;
      if(sheetHeight!=bottomSheetHeight&&bottomSheetActive){
        setState(() {
          bottomSheetHeight=sheetHeight;
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.menu,
                color: Colors.white,
              ),
              alignment: Alignment.bottomRight,
              onPressed: () => _drawerKey.currentState.openDrawer(),
            ),
            Consumer<UserDocument>(
              builder: (_, data, __) {
                if (data is UserData &&
                    (data.removedByInviter != null ||
                        Provider.of<InvitationPendingResponse>(context)
                                .emailOfInviter !=
                            null)) {
                  return PositionedRedBall();
                } else {
                  return SizedBox();
                }
              },
            )
          ],
        ),
        bottom: TabBar(tabs: [
          Tab(
            child: Text(
              'CHECKLIST',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Tab(
            child: Consumer<UserDocument>(
              builder: (_, data, __) {
                if (data is LoadingUserDocument) {
                  return Text(
                    'TO BUY',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  );
                } else if (data is ErrorFetchingUserDocument) {
                  String err = data.err;
                  FirebaseCrashlytics.instance
                      .log('Error loading data for To buy counter: $err');
                  return Text(
                    'TO BUY',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  );
                } else if (data is UserData) {
                  int _countOfStarredItems =
                      data.items.where((i) => i.star).toList().length;
                  if (data.items.length == 300) {
                    _numOfItemsLimitReached = true;
                  } else {
                    _numOfItemsLimitReached = false;
                  }
                  return Text(
                    'TO BUY ($_countOfStarredItems)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  );
                } else {
                  return Text(
                    'TO BUY',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  );
                }
              },
              child: Text(
                'TO BUY',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          )
        ]),
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: bottomSheetHeight),
        child: SafeArea(
          child: TabBarView(
            children: <Widget>[CheckList(), StarredItemsTab()],
          ),
        ),
      ),
      key: _drawerKey,
      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.all(0.0),
          children: <Widget>[
            userEmail == 'anonymousUser'
                ? Container(
                    height: MediaQuery.of(context).padding.top * 2,
                    child: DrawerHeader(
                      child: Container(),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  )
                : DrawerHeader(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: CircleAvatar(
                            child: Text(
                              userEmail[0].toUpperCase(),
                              style: GoogleFonts.baumans(
                                  textStyle: TextStyle(
                                      color: Colors.blue[900],
                                      fontSize: 45.0,
                                      fontWeight: FontWeight.w400)),
                            ),
                            foregroundColor: Colors.blue[900],
                            backgroundColor: Colors.white,
                            maxRadius: 35,
                          ),
                        ),
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: Colors.white54,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
            ListTile(
              leading: Icon(Icons.group),
              title: Text('Share'),
              trailing: Consumer<UserDocument>(
                builder: (_, data, __) {
                  if (data is UserData &&
                      (data.removedByInviter != null ||
                          (Provider.of<InvitationPendingResponse>(context)
                                      .emailOfInviter !=
                                  null &&
                              data.inviteesWhoJoined.isEmpty &&
                              data.inviteesYetToRespond.isEmpty &&
                              Provider.of<SignedInUser>(context).userEmail ==
                                  data.ownerOfListInUse))) {
                    return RedBallNotification();
                  } else {
                    return SizedBox();
                  }
                },
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/Share');
              },
            ),
            userEmail == 'anonymousUser'
                ? ListTile(
                    leading: Icon(Icons.app_registration),
                    title: Text('Login/Register'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, '/Register');
                    })
                : SizedBox(),
            Consumer<UserDocument>(
              builder: (_, data, __) {
                if (data is UserData &&
                    (Provider.of<InvitationPendingResponse>(context)
                                .emailOfInviter !=
                            null &&
                        (data.inviteesWhoJoined.isNotEmpty ||
                            data.inviteesYetToRespond.isNotEmpty ||
                            Provider.of<SignedInUser>(context).userEmail !=
                                data.ownerOfListInUse))) {
                  return ListTile(
                    leading: Icon(Icons.notification_important),
                    title: Text('Alert'),
                    trailing: RedBallNotification(),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, '/Alert');
                    },
                  );
                } else {
                  return SizedBox();
                }
              },
            ),
            userEmail == 'anonymousUser'
                ? SizedBox()
                : ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Profile'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Provider.of<UserTypeProvider>(context, listen: false)
                          .setConvertedUserToTrue();
                      Navigator.pushNamed(context, '/Settings');
                    }),
            // userEmail == 'anonymousUser'
            //     ? SizedBox()
            //     : ListTile(
            //         leading: Icon(Icons.exit_to_app),
            //         title: Text('Sign out'),
            //         onTap: () async {
            //           try {
            //             await showDialog(
            //                 barrierDismissible: false,
            //                 context: context,
            //                 builder: (context) {
            //                   Future.delayed(Duration(seconds: 2), () {
            //                     Navigator.of(context).pop(true);
            //                   });
            //                   return StatusAlert(
            //                     statusMessage: 'Signing out..',
            //                   );
            //                 });
            //             Provider.of<UserTypeProvider>(
            //                 context,
            //                 listen: false)
            //                 .setConvertedUserToTrue();
            //             await AuthService().signOut();
            //           } catch (e, s) {
            //             await FirebaseCrashlytics.instance
            //                 .log('Sign out button pressed');
            //             await FirebaseCrashlytics.instance.recordError(e, s,
            //                 reason: 'Sign out button pressed');
            //             showDialog(
            //                 context: context,
            //                 builder: (BuildContext context) {
            //                   return ErrorAlert(errorMessage: e.toString());
            //                 });
            //           } //signs out
            //         },
            //       )
          ],
        ),
      ),
      floatingActionButton: Builder(builder: (context) {
        return FloatingActionButton(
          child: bottomSheetActive ? Icon(Icons.close) : Icon(Icons.add),
          onPressed: () async {
            if (!bottomSheetActive) {
              if (_numOfItemsLimitReached == true) {
                Flushbar(
                  flushbarPosition: FlushbarPosition.TOP,
                  message:
                      'You have already reached the maximum number of items allowed. Delete some unused items to make room for new ones.',
                  duration: Duration(seconds: 6),
                  margin: EdgeInsets.all(8),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                )..show(context);
              } else {
                // Scaffold.of(context)
                //     .showBottomSheet<void>((BuildContext context) {
                //   return SingleChildScrollView(child: AddItem());
                // });
                var bottomSheetController = showBottomSheet(
                    context: context,
                    builder: (context) => SingleChildScrollView(key:bottomSheetKey,child: AddItem()));
                bottomSheetController.closed.then((value) {
                  Provider.of<ItemFilterProvider>(context,
                      listen: false)
                      .changeItemFilter(newValue: '');
                  setState(() {
                    bottomSheetActive = false;
                    bottomSheetHeight=0;
                  });
                });
                setState(() {
                  bottomSheetActive = true;
                });
              }
            } else {
              Navigator.pop(context);
              Provider.of<ItemFilterProvider>(context,
                  listen: false)
                  .changeItemFilter(newValue: '');
              setState(() {
                bottomSheetActive = false;
                bottomSheetHeight=0;
              });
            }
          },
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
//
// class FloatingButton extends StatelessWidget {
//   const FloatingButton({Key key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container();
//   }
// }

class RedBallNotification extends StatelessWidget {
  const RedBallNotification({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12.0,
      width: 12.0,
      padding: EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(6),
      ),
      constraints: BoxConstraints(
        minWidth: 12,
        minHeight: 12,
      ),
    );
  }
}

class PositionedRedBall extends StatelessWidget {
  const PositionedRedBall({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      right: 15,
      child: Container(
        width: 14,
        height: 14,
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.red[500],
          borderRadius: BorderRadius.circular(7),
        ),
        constraints: BoxConstraints(
          minWidth: 14,
          minHeight: 14,
        ),
      ),
    );
  }
}
