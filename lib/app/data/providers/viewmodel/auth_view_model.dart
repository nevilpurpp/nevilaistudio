import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/utils/utils.dart';
import 'base_model.dart';
import 'chat_view_model.dart';

class AuthViewModel extends BaseModel{
    TextEditingController nameController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

  
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    
Stream<User?> get userState => _auth.authStateChanges();
  get user => _auth.currentUser;
  get username => _auth.currentUser?.displayName;
  get useremail => _auth.currentUser?.email;
  get userphoto => _auth.currentUser?.photoURL;
  keyboard(bool value){
    Function(bool value) keyboard = ChatViewModel().keyboardAppear;
    return keyboard;
  }
  
  void listenToAuthState(){
    _auth.authStateChanges().listen(user);
  }

  Future<UserCredential?> registerWithEmailAndPassword(
      String name, String email, String password) async {
    if (!AppUtils.validateEmail(email)) {
      AppUtils.showError('Please enter a valid email address.');
      return null;
    }

    if (password.length < 6) {
      AppUtils.showError('Password must be at least 6 characters long.');
      return null;
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user data in Firestore (optional)
      final userDoc = _firestore.collection('users').doc(credential.user!.uid);
      await userDoc.set({
        'name': name,
        'email': email,
        // Add other relevant user data fields
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      handleFirebaseAuthError(e);
      return null;
    } catch (e) {
      AppUtils.showError('An error occurred: $e');
      return null;
    }
  }

  //SIGN IN METHOD
    Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    if (!AppUtils.validateEmail(email)) {
      AppUtils.showError('Please enter a valid email address.');
      return null;
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      handleFirebaseAuthError(e);
      return null;
    } catch (e) {
      AppUtils.showError('An error occurred: $e');
      return null;
    }
  }

Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      AppUtils.showSuccess('Password reset email sent!');
    } on FirebaseAuthException catch (e) {
      handleFirebaseAuthError(e);
    } catch (e) {
      AppUtils.showError('An error occurred: $e');
    }
  }

// Google SIGN IN

Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      AppUtils.showError('Google sign-in cancelled.');
      return Future.error('Google sign-in cancelled');
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser.authentication;

    if (googleAuth == null) {
      AppUtils.showError('An error occurred during Google sign-in.');
      return Future.error('An error occurred during Google sign-in');
    }

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    try {
      final userCredential = await _auth.signInWithCredential(credential);

      // Store user data in Firestore
      if (userCredential.user != null) {
        final userDoc = _firestore.collection('users').doc(userCredential.user!.uid);
        await userDoc.set({
          'name': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'photoUrl': userCredential.user!.photoURL,
          // Add other relevant user data fields
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      handleFirebaseAuthError(e);
      return Future.error('Firebase authentication error: ${e.code}');
    } catch (e) {
      AppUtils.showError('An error occurred: $e');
      return Future.error('An error occurred: $e');
    }
  }

  //SIGN OUT METHOD
  Future signOut() async {
    await _auth.signOut();
    
    print('signout');
  }

   void handleFirebaseAuthError(FirebaseAuthException e) {
    if (e.code == 'weak-password') {
      AppUtils.showError('The password provided is too weak.');
    } else if (e.code == 'email-already-in-use') {
      AppUtils.showError('The account already exists for that email.');
    } else if (e.code == 'user-not-found') {
      AppUtils.showError('user not found');

  }
   }
}