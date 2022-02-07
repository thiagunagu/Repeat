import 'package:repeat/CustomWidgets/ItemFilterProvider.dart';
import 'package:repeat/CustomWidgets/UserTypeProvider.dart';
import 'package:flutter/material.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:another_flushbar/flushbar.dart';

import 'package:provider/provider.dart';

import 'package:repeat/CustomWidgets/ErrorAlert.dart';

import 'package:repeat/Models/UserDocument.dart';

import 'package:repeat/Services/DatabaseServices.dart';

import 'package:in_app_review/in_app_review.dart';

class AddItem extends StatefulWidget {
  @override
  _AddItemState createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  TextEditingController _itemController = TextEditingController();
  bool _nullOrInvalidItem = true;
  bool _numOfItemsLimitReached = false;
  bool _star = false;
  FocusNode _focusNode;
  final InAppReview _inAppReview = InAppReview.instance;
  final _addItemKey = GlobalKey<FormState>();


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _addItemKey,
      child: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              //stops: [0.1,1],
              colors: [
                Colors.blue[100],
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
            )),
        padding: EdgeInsets.only(
          top: 16.0,
            left: 8.0,
            right: 8.0,
            bottom:8.0),
        child: Consumer<UserDocument>(
          builder: (_, data, __) {
            if (data is LoadingUserDocument) {
              return const CircularProgressIndicator();
            } else if (data is ErrorFetchingUserDocument) {
              String err = data.err;
              FirebaseCrashlytics.instance
                  .log('Error loading data for Add Item route: $err');
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                      'Oops! Something went wrong. Please restart the app and try again.'),
                ),
              );
            } else if (data is UserData) {
              if (data.items.length >= 300) {
                _numOfItemsLimitReached = true;
              } else {
                _numOfItemsLimitReached = false;
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 4, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        autofocus: true,
                        focusNode: _focusNode,
                        controller: _itemController,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (text) {
                          Provider.of<ItemFilterProvider>(context, listen: false)
                              .changeItemFilter(newValue: text.toLowerCase());
                          if (text == null || text.isEmpty) {
                            setState(() {
                              _nullOrInvalidItem = true;
                            });
                            return null;
                          } else {
                            setState(() {
                              _nullOrInvalidItem = false;
                            });
                            return null;
                          }
                        },
                        decoration: InputDecoration.collapsed(
                            hintText: 'Search/Add'),
                      ),
                    ),
                    IconButton(
                        icon:
                            Icon(_star ? Icons.star : Icons.star_border),
                        onPressed: () => setState(() => _star = !_star)),
                    IconButton(
                        iconSize: 35.0,
                        disabledColor: Colors.grey,
                        color: Colors.blue[900],
                        icon: Icon(
                          Icons.add,

                        ),
                        onPressed: _nullOrInvalidItem
                            ? null
                            : () async {
                          Provider.of<ItemFilterProvider>(context,
                              listen: false)
                              .changeItemFilter(newValue: '');
                                if (_numOfItemsLimitReached == true) {
                                  Flushbar(
                                    flushbarPosition:
                                        FlushbarPosition.TOP,
                                    message:
                                        'You have already reached the maximum number of items allowed. Delete some unused items to make room for new ones.',
                                    duration: Duration(seconds: 6),
                                    margin: EdgeInsets.all(8),
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(10)),
                                  )..show(context);
                                } else {
                                  try {
                                    await DatabaseService(
                                            dbDocId:
                                                data.docIdOfListInUse)
                                        .addItem(
                                      item: _itemController.text,
                                      star: _star,
                                    );
                                    Provider.of<ItemFilterProvider>(context, listen: false)
                                        .changeItemFilter(newValue:'');
                                    final String _item =
                                        _itemController.text;
                                    Flushbar(
                                      flushbarPosition:
                                          FlushbarPosition.TOP,
                                      message: 'Added \"$_item\"',
                                      duration: Duration(seconds: 2),
                                      margin: EdgeInsets.all(8),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10)),
                                    )..show(context);
                                    _focusNode.requestFocus();
                                    _itemController.text = '';
                                    setState(() {
                                      _nullOrInvalidItem = true;
                                    });
                                    final isAvailable =
                                        await _inAppReview.isAvailable();
                                    if (isAvailable &&
                                        Provider.of<UserTypeProvider>(
                                                    context,
                                                    listen: false)
                                                .launchNumber >
                                            6 &&
                                        Provider.of<UserTypeProvider>(
                                                    context,listen: false)
                                                .noOfDaysFromLaunch >
                                            6) {
                                      _inAppReview.requestReview();
                                    }
                                    FocusScope.of(context)
                                        .requestFocus(_focusNode);
                                  } catch (e, s) {
                                    await FirebaseCrashlytics.instance.log(
                                        'Add button pressed in add item route');
                                    await FirebaseCrashlytics.instance
                                        .recordError(e, s,
                                            reason:
                                                'Add button pressed in add item route');
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return ErrorAlert(
                                              errorMessage: e.toString());
                                        });
                                  }
                                }
                              }),
                  ],
                ),
              );
            }
            throw FallThroughError();
          },
        ),
      ),
    );
  }
}
