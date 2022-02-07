import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:repeat/Models/InvitationPendingResponse.dart';
import 'package:repeat/Models/Item.dart';
import 'package:repeat/Models/ListInUse.dart';
import 'package:repeat/Models/UserDocument.dart';

class DatabaseService {
  final String dbOwner;
  final String dbDocId;
  DatabaseService({this.dbOwner, this.dbDocId});

  static CollectionReference<Map<String, dynamic>> collectionReference =
      FirebaseFirestore.instance.collection('repeat');

  // static CollectionReference collectionReference =
  // FirebaseFirestore.instance.collection('beyyaTest');

  //create a firestore doc with example data when the user creates an account
  Future createUserDocumentWhileSigningUp() async {
    return await collectionReference.doc(dbDocId).set(
      {
        'owner': dbOwner,
        'docId': dbDocId,
        'ownerOfListInUse': dbOwner,
        'docIdOfListInUse': dbDocId,
        'removedByInviter': null,
        'inviteesWhoJoined': [],
        'uidsOfInviteesWhoJoined': {},
        'inviteesYetToRespond': [],
        'inviteesWhoDeclined': [],
        'inviteesWhoLeft': [],

        'items': {
          "Tomatoes": {
            'item': 'Tomatoes',
            'star': true,
          },
          "Onion": {
            'item': 'Onion',
            'star': false,
          },
          "Avocados": {
            'item': 'Avocados',
            'star': true,
          },
          'Hand%20Soap': {
            'item': 'Hand Soap',
            'star': false,
          },
          'Milk': {
            'item': 'Milk',
            'star': true,
          },
          'Yogurt': {
            'item': 'Yogurt',
            'star': false,
          }
        },
      },
    );
  }
//add userEmail while converting from anonymous to authenticated user
  Future addUserEmail({String email}) async {
    await collectionReference
        .doc(dbDocId)
        .update({'owner': email, 'ownerOfListInUse':email});
  }

  //get stream of document snapshots and map it to "UserDocument" objects
  Stream<UserDocument> get userDocument {
    return collectionReference
        .doc(dbDocId)
        .snapshots()
        .map(_userDocumentFromSnapshot);
  }

  UserDocument _userDocumentFromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    return UserData(
        docId: snapshot.data()['docId'],
        owner: snapshot.data()['owner'],
        docIdOfListInUse: snapshot.data()['docIdOfListInUse'],
        ownerOfListInUse: snapshot.data()['ownerOfListInUse'],
        removedByInviter: snapshot.data()['removedByInviter'],
        inviteesWhoJoined: snapshot.data()['inviteesWhoJoined'].cast<String>(),
        uidsOfInviteesWhoJoined: snapshot.data()['uidsOfInviteesWhoJoined'],
        inviteesWhoDeclined:
            snapshot.data()['inviteesWhoDeclined'].cast<String>(),
        inviteesYetToRespond:
            snapshot.data()['inviteesYetToRespond'].cast<String>(),
        inviteesWhoLeft: snapshot.data()['inviteesWhoLeft'].cast<String>(),
        items: snapshot.data()['items'].values.map<Item>((itemDetail) {
          return Item(
              item: decodeFirebaseKey(text: itemDetail['item']),
              star: itemDetail['star']);
        }).toList());
  }

  //Get a stream of invitations pending user response
  Stream<InvitationPendingResponse> get invitationPendingResponse {
    return collectionReference
        .where('inviteesYetToRespond', arrayContains: dbOwner)
        .snapshots()
        .map(_invitationPendingResponse);
  }

  InvitationPendingResponse _invitationPendingResponse(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return InvitationPendingResponse(
        emailOfInviter: snapshot.docs[0].data()['owner'],
        docIdOfInviter: snapshot.docs[0].data()['docId']);
  }

  //this stream provides the id of the list in use - will be same as the
  // signed in user's list if he/she hasn't joined any shared list
  Stream<ListInUse> get idOfListInUse {
    return collectionReference
        .doc(dbDocId)
        .snapshots()
        .map(_idOfListInUseFromSnapshot);
  }

  ListInUse _idOfListInUseFromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    return ListInUseId(
        ownerOfListInUse: snapshot.data()['ownerOfListInUse'],
        docIdOfListInUse: snapshot.data()['docIdOfListInUse']);
  }


  Future addItem({
    String item, //avocado, tomato, etc.
    bool star, // starred items will show up in the "To buy" tab
  }) async {
    String encodedItem = encodeAsFirebaseKey(text: item);
    await collectionReference.doc(dbDocId).set(
      {
        'items': {
          encodedItem : {
            'item': encodedItem,
            'star': star,
          }
        }
      },
      SetOptions(merge: true),
    );
  }

  Future deleteItem({String id}) async {
    await collectionReference
        .doc(dbDocId)
        .update({'items.$id': FieldValue.delete()}); //delete item
  }

  //edit details of an item =>first deletes the item, and adds the revised
  //version as a new item
  Future editItem({
    String item,
    bool star,
    String id,
  }) async {
    await deleteItem(id: id);
    await addItem(
      item: item,
      star: star,
    );
  }

  Future toggleStar({bool star, String id}) async {
    await collectionReference.doc(dbDocId).update({'items.$id.star': !star});
  }

  Future setListInUse(
      {String ownerOfListInUse, String docIdOfListInUse}) async {
    await collectionReference.doc(dbDocId).update(
      {
        'ownerOfListInUse': ownerOfListInUse,
        'docIdOfListInUse': docIdOfListInUse
      },
    );
  }

  Future setRemovedByInviter({String inviter}) async {
    await collectionReference.doc(dbDocId).update(
      {
        'removedByInviter': inviter,
      },
    );
  }

  Future addToInviteesYetToRespond({String invitee}) async {
    await collectionReference.doc(dbDocId).update({
      'inviteesYetToRespond': FieldValue.arrayUnion([invitee])
    });
  }

  Future removeFromInviteesYetToRespond({String invitee}) async {
    await collectionReference.doc(dbDocId).update({
      'inviteesYetToRespond': FieldValue.arrayRemove([invitee])
    });
  }

  Future addToInviteesWhoJoined({String invitee, String inviteeUid}) async {
    await collectionReference.doc(dbDocId).update({
      'inviteesWhoJoined': FieldValue.arrayUnion(
        [invitee],
      )
    });
    String encodedInvitee = encodeAsFirebaseKey(text: invitee);
    await collectionReference.doc(dbDocId).set(
      {
        'uidsOfInviteesWhoJoined': {encodedInvitee: inviteeUid}
      },
      SetOptions(merge: true),
    );
  }

  Future removeFromInviteesWhoJoined({String invitee}) async {
    String encodedInvitee = encodeAsFirebaseKey(text: invitee);
    await collectionReference.doc(dbDocId).update({
      'uidsOfInviteesWhoJoined.$encodedInvitee': FieldValue.delete(),
      'inviteesWhoJoined': FieldValue.arrayRemove([invitee])
    });
  }

  String encodeAsFirebaseKey({String text}) {
    return Uri.encodeComponent(text)
        .replaceAll('.', '%2E')
        .replaceAll('*', '%2A');
  }

  String decodeFirebaseKey({String text}) {
    return Uri.decodeComponent(text);
  }

  Future addToInviteesWhoDeclined({String invitee}) async {
    await collectionReference.doc(dbDocId).update({
      'inviteesWhoDeclined': FieldValue.arrayUnion([invitee])
    });
  }

  Future removeFromInviteesWhoDeclined({String invitee}) async {
    await collectionReference.doc(dbDocId).update({
      'inviteesWhoDeclined': FieldValue.arrayRemove([invitee])
    });
  }

  Future addToInviteesWhoLeft({String invitee}) async {
    await collectionReference.doc(dbDocId).update({
      'inviteesWhoLeft': FieldValue.arrayUnion([invitee])
    });
  }

  Future removeFromInviteesWhoLeft({String invitee}) async {
    await collectionReference.doc(dbDocId).update({
      'inviteesWhoLeft': FieldValue.arrayRemove([invitee])
    });
  }

  Future deleteUserDocument() async {
    await collectionReference.doc(dbDocId).delete();
  }
}
