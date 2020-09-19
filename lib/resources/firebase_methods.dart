import 'dart:core';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:skype_clone/constants/string.dart';
import 'package:skype_clone/models/message.dart';
import 'package:skype_clone/models/user.dart';
import 'package:skype_clone/provider/image_upload_provider.dart';
import 'package:skype_clone/utils/utilities.dart';

class FirebaseMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn _googleSignIn = GoogleSignIn();
  static final Firestore firestore = Firestore.instance;

  //user class
  User user = User();

  StorageReference _storageReference;

  static final CollectionReference _userCollection =
      firestore.collection(USERS_COLLECTION);

  Future<FirebaseUser> getCurrentUser() async {
    FirebaseUser currentUser;
    currentUser = await _auth.currentUser();
    return currentUser;
  }

  Future<User> getUserDetails() async {
    FirebaseUser currentUser = await getCurrentUser();
    DocumentSnapshot documentSnapshot =
        await _userCollection.document(currentUser.uid).get();

    return User.fromMap(documentSnapshot.data);
  }

  Future<FirebaseUser> signIn() async {
    GoogleSignInAccount _signInAccount = await _googleSignIn.signIn();
    GoogleSignInAuthentication _signInAuthentication =
        await _signInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: _signInAuthentication.accessToken,
        idToken: _signInAuthentication.idToken);

    FirebaseUser user = await _auth.signInWithCredential(credential);
    return user;
  }

  Future<bool> authenticateUser(FirebaseUser user) async {
    QuerySnapshot result = await firestore
        .collection("users")
        .where("email", isEqualTo: user.email)
        .getDocuments();
    final List<DocumentSnapshot> docs = result.documents;
    //if user is registered then length of list > 0 or else less than 0
    return docs.length == 0 ? true : false;
  }

  Future<void> addDataToDb(FirebaseUser currentUser) async {
    String username = Utils.getUsername(currentUser.email);
    user = User(
        uid: currentUser.uid,
        email: currentUser.email,
        name: currentUser.displayName,
        profilePhoto: currentUser.photoUrl,
        username: username);

    firestore
        .collection(USERS_COLLECTION)
        .document(currentUser.uid)
        .setData(user.toMap(user));
  }

  Future<bool> signOut() async {
    try {
      await _googleSignIn.disconnect();
      await _googleSignIn.signIn();
      await _auth.signOut();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<List<User>> fetchAllUsers(FirebaseUser currentUser) async {
    List<User> userList = List<User>();
    QuerySnapshot querySnapshot =
        await firestore.collection(USERS_COLLECTION).getDocuments();

    for (var i = 0; i < querySnapshot.documents.length; i++) {
      //
      if (querySnapshot.documents[i].documentID != currentUser.uid) {
        userList.add(User.fromMap(querySnapshot.documents[i].data));
      }
    }

    return userList;
  }

  Future<void> addMessageToDb(
      Message message, User sender, User receiver) async {
    var map = message.toMap();

    await firestore
        .collection(MESSAGES_COLLECTION)
        .document(message.senderId)
        .collection(message.receiverId)
        .add(map);

    return await firestore
        .collection(MESSAGES_COLLECTION)
        .document(message.receiverId)
        .collection(message.senderId)
        .add(map);
  }

  Future<String> upLoadImageToStorage(File image) async {
    try {
      _storageReference = FirebaseStorage.instance
          .ref()
          .child('${DateTime.now().millisecondsSinceEpoch}');
      StorageUploadTask _storageuploadtask = _storageReference.putFile(image);

      var url =
          await (await _storageuploadtask.onComplete).ref.getDownloadURL();
      print(url);
      return url;
    } catch (e) {
      print(e);
      return null;
    }
  }

  void setImageMsg(String url, String receiverId, senderId) async {
    Message _message = Message();
    _message = Message.imageMessage(
      message: "IMAGE",
      receiverId: receiverId,
      senderId: senderId,
      photoUrl: url,
      timestamp: Timestamp.now(),
      type: 'image',
    );

    var map = _message.toImageMap();

    await firestore
        .collection(MESSAGES_COLLECTION)
        .document(_message.senderId)
        .collection(_message.receiverId)
        .add(map);

    await firestore
        .collection(MESSAGES_COLLECTION)
        .document(_message.receiverId)
        .collection(_message.senderId)
        .add(map);
  }

  void upLoadImage(File image, String receiverId, String senderId,
      ImageUploadProvider imageUploadProvider) async {
    imageUploadProvider.setToLoding();
    String url = await upLoadImageToStorage(image);

    imageUploadProvider.setToIdel();

    setImageMsg(url, receiverId, senderId);
  }
}
