import 'package:flutter/material.dart';

class ItemFilterProvider extends ChangeNotifier {
  List<String> itemFilter = [''];
  void changeItemFilter({String newValue}) {
    itemFilter = newValue.split(' ');
    notifyListeners();
  }
}
