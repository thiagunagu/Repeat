import 'package:flutter/material.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:provider/provider.dart';

import 'package:another_flushbar/flushbar.dart';

import 'package:repeat/CustomWidgets/ErrorAlert.dart';

import 'package:repeat/Models/UserDocument.dart';

import 'package:repeat/Services/DatabaseServices.dart';

class EditItem extends StatefulWidget {
  final String currentItem;
  final bool currentStar;

  EditItem({
    this.currentItem,
    this.currentStar,
  });

  @override
  _EditItemState createState() => _EditItemState();
}

class _EditItemState extends State<EditItem> {
  String _item; //to save the item name after editing
  bool _star; //to save the new star
  final _editItemKey = GlobalKey<FormState>();
  TextEditingController _itemController;
  bool _nullOrInvalidItem = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _itemController = TextEditingController(text: widget.currentItem);
    _item = widget.currentItem;
    _star = widget.currentStar;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _itemController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _editItemKey,
      child: Container(
        color: Color(0xff757575),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
              )),
          padding: EdgeInsets.only(left: 20.0, right: 8.0, bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Consumer<UserDocument>(
            builder: (_, data, __) {
              if (data is LoadingUserDocument) {
                return const CircularProgressIndicator();
              } else if (data is ErrorFetchingUserDocument) {
                String err = data.err;
                FirebaseCrashlytics.instance
                    .log('Error loading data for Edit item route: $err');
                return Center(
                  child: Text(
                      'Oops! Something went wrong. Please restart the app and try again.'),
                );
              } else if (data is UserData) {
                return Row(
                  children: <Widget>[
                    Expanded(
                        child: TextField(
                            autofocus: true,
                            controller: _itemController,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (text) {
                              if (text == null ||
                                  text.isEmpty ||
                                  text == widget.currentItem) {
                                setState(() {
                                  _nullOrInvalidItem = true;
                                });
                                return null;
                              } else {
                                setState(() {
                                  _nullOrInvalidItem = false;
                                  _item = text;
                                });
                                return null;
                              }
                            },
                            decoration: InputDecoration.collapsed(
                                hintText: 'Add Item'))),
                    IconButton(
                      icon: Icon(_star ? Icons.star : Icons.star_border),
                      onPressed: () {
                        setState(() {
                          _star = !_star;
                          if (_star != widget.currentStar) {
                            _nullOrInvalidItem = false;
                          } else {
                            _nullOrInvalidItem = true;
                          }
                        });
                      },
                    ),
                    IconButton(
                      disabledColor: Colors.grey,
                      color: Colors.blue[900],
                      icon: Icon(
                        Icons.save,
                      ),
                      onPressed: _nullOrInvalidItem
                          ? null
                          : () async {
                              try {
                                String encodedItem = DatabaseService()
                                    .encodeAsFirebaseKey(
                                        text: widget.currentItem);
                                await DatabaseService(
                                        dbDocId: data.docIdOfListInUse)
                                    .editItem(
                                        item: _item,
                                        star: _star,
                                        id: encodedItem);
                                Navigator.pop(context);
                                Flushbar(
                                  flushbarPosition: FlushbarPosition.TOP,
                                  message: 'Updated \"$_item\"',
                                  duration: Duration(seconds: 2),
                                  margin: EdgeInsets.all(8),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                )..show(context);
                              } catch (e, s) {
                                await FirebaseCrashlytics.instance.log(
                                    'Save button pressed in edit item modal bottom sheet');
                                await FirebaseCrashlytics.instance.recordError(
                                    e, s,
                                    reason:
                                        'Save button pressed in edit item modal bottom sheet');
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return ErrorAlert(
                                          errorMessage: e.toString());
                                    });
                              }
                            },
                    ),
                  ],
                );
              }
              throw FallThroughError();
            },
          ),
        ),
      ),
    );
  }
}
