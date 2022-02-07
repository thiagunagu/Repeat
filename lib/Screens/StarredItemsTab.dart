
import 'package:flutter/material.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:provider/provider.dart';

import 'package:repeat/CustomWidgets/ErrorAlert.dart';
import 'package:repeat/CustomWidgets/ItemTile.dart';
import 'package:repeat/CustomWidgets/SwipeLeftBackground.dart';
import 'package:repeat/CustomWidgets/SwipeRightBackground.dart';
import 'package:repeat/CustomWidgets/ItemFilterProvider.dart';

import 'package:repeat/Models/Item.dart';
import 'package:repeat/Models/UserDocument.dart';

import 'package:repeat/Services/DatabaseServices.dart';

class StarredItemsTab extends StatefulWidget {
  @override
  _StarredItemsTabState createState() => _StarredItemsTabState();
}

class _StarredItemsTabState extends State<StarredItemsTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserDocument>(
      builder: (_, data, __) {
        if (data is LoadingUserDocument) {
          return const CircularProgressIndicator();
        } else if (data is ErrorFetchingUserDocument) {
          String err = data.err;
          FirebaseCrashlytics.instance
              .log('Error loading data for Starred items route: $err');
          return Center(
            child: Text(
                'Oops! Something went wrong. Please restart the app and try again.'),
          );
        } else if (data is UserData) {
          DatabaseService _db = DatabaseService(dbDocId: data.docIdOfListInUse);
          final List<Item> _items = List.from(data.items);
          final List<Item> _starredItems =
              _items.where((element) => element.star).toList();
          if (_starredItems.isNotEmpty) {
            _items.sort(
                    (a, b) => a.item.toLowerCase().compareTo(b.item.toLowerCase()));
            return ListView.builder(
                    padding: EdgeInsets.all(2.0),
                    itemBuilder: (context, itemIndex) {
                      String itemName = _items[itemIndex].item;
                      return _items[itemIndex].star ==
                                  true && //filter for starred _items
                          Provider.of<ItemFilterProvider>(context).itemFilter.any((filter) => _items[itemIndex].item.toLowerCase().split(' ').any((word) => word.startsWith(filter)))
                          ? Dismissible(
                              key: ObjectKey(_items[itemIndex]),
                              //use the corresponding object as the key for each dismissible widget,
                              //if the ternary operator returns true, build list of dismissible itemTiles
                              child: ItemTile(
                                docIdOfListInUse: data.docIdOfListInUse,
                                item: _items[itemIndex].item,
                                star: _items[itemIndex].star,
                                toggleStar: () {
                                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                  String encodedItem = _db.encodeAsFirebaseKey(
                                      text: _items[itemIndex].item);
                                  _db.toggleStar(
                                      star: _items[itemIndex].star,
                                      id: encodedItem);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Unstarred "$itemName"'),
                                    action: SnackBarAction(
                                      label: 'UNDO',
                                      textColor: Colors.amber,
                                      onPressed: () {
                                        _db.toggleStar(
                                            star: !_items[itemIndex].star,
                                            id: encodedItem);
                                      },
                                    ),
                                  ));
                                },
                              ),
                              background: SwipeRightBackground(),
                              secondaryBackground: SwipeLeftBackground(),
                              onDismissed: (direction) async {
                                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                try {
                                  String encodedItem = _db.encodeAsFirebaseKey(
                                      text: _items[itemIndex].item);
                                  String encodedCategory =
                                      _db.encodeAsFirebaseKey(
                                          text: _items[itemIndex].category);
                                  String encodedStore = _db.encodeAsFirebaseKey(
                                      text: _items[itemIndex].store);
                                  await _db.deleteItem(
                                      id: encodedItem +
                                          encodedCategory +
                                          encodedStore);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Deleted "$itemName"'),
                                    action: SnackBarAction(
                                      label: 'UNDO',
                                      textColor: Colors.amber,
                                      onPressed: () {
                                        _db.addItem(
                                          item: _items[itemIndex].item,
                                          star: _items[itemIndex].star,
                                        );
                                      },
                                    ),
                                  ));
                                } catch (e, s) {
                                  await FirebaseCrashlytics.instance
                                      .log('Item dismissed');
                                  await FirebaseCrashlytics.instance
                                      .recordError(e, s,
                                          reason: 'Item dismissed');
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return ErrorAlert(
                                            errorMessage: e.toString());
                                      });
                                }
                              })
                          : SizedBox(); //return an empty box when the ternary operator returns false
                    },
                    itemCount: _items.length,
                  );
          } else {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        'You\'re all done!',
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 18.0),
                      ),
                    )
                  ],
                ),
              ),
            );
          }
        }
        throw FallThroughError();
      },
    );
  }
}
