import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserCredential> signInWithEmailAndPassword(String email, String password);
  Future<UserCredential> signUpWithEmailAndPassword(String email, String password);
  Future<UserCredential> signInWithGoogle();
  Future<void> upsertUserProfile(AuthUserModel user);
  Future<String?> getUserRole(String uid);
  Future<void> signOut();
  Stream<User?> get authStateChanges;
  User? get currentUser;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.googleSignIn,
  });

  @override
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) {
    return firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> signUpWithEmailAndPassword(String email, String password) {
    return firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign_in_canceled',
        message: 'Google sign in was canceled.',
      );
    }

    final googleAuthentication = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuthentication.accessToken,
      idToken: googleAuthentication.idToken,
    );

    return firebaseAuth.signInWithCredential(credential);
  }

  @override
  Future<void> upsertUserProfile(AuthUserModel user) async {
    final ref = firestore.collection('users').doc(user.uid);
    final snap = await ref.get();
    final data = <String, dynamic>{
      ...user.toMap(),
      'last_sign_in_at': FieldValue.serverTimestamp(),
    };
    if (!snap.exists) {
      data['created_at'] = FieldValue.serverTimestamp();
      data['role'] = user.role ?? 'customer';
    } else if (user.role != null) {
      data['role'] = user.role;
    }
    await ref.set(data, SetOptions(merge: true));
  }

  @override
  Future<String?> getUserRole(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return 'customer';
    final r = data['role'] as String?;
    return r ?? 'customer';
  }

  @override
  Future<void> signOut() {
    return Future.wait([
      firebaseAuth.signOut(),
      googleSignIn.signOut(),
    ]).then((_) {});
  }

  @override
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  @override
  User? get currentUser => firebaseAuth.currentUser;
}
