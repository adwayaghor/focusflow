import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rxn<User> firebaseUser = Rxn<User>();
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
  }

  User? get user => firebaseUser.value;
  bool get isLoggedIn => firebaseUser.value != null;

  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;
      error.value = '';
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      error.value = e.message ?? 'Login failed';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String name,
    required String college,
    required String course,
    required String year,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _firestore.collection('users').doc(cred.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'college': college.trim(),
        'course': course.trim(),
        'year': year.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } on FirebaseAuthException catch (e) {
      error.value = e.message ?? 'Signup failed';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  void clearError() {
    error.value = '';
  }
}
