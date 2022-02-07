import 'package:flutter/material.dart';

import 'package:repeat/Screens/EditItem.dart';

class ItemTile extends StatelessWidget {
  final String docIdOfListInUse;
  final String item; //potato, avocado, etc
  final bool star;// starred item or unstarred item
  final Function toggleStar;

  ItemTile({
    this.docIdOfListInUse,
    this.item,
    this.star,
    this.toggleStar
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.fromLTRB(0, 0.1, 0, 0.1),
      child: ListTile(
        title: Text(item),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(star ? Icons.star : Icons.star_border),
          ],
        ),
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => SingleChildScrollView(
              child: EditItem(
                currentItem: item,
                currentStar: star,
              ),
            ),
          );
        },
        onTap: toggleStar,
      ),
    );
  }
}
