import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../overlay/overlay_service.dart';

class SessionController extends GetxController {

  final RxBool isSessionActive = false.obs;
  final RxBool isLoading = true.obs;

  final Rx<DateTime?> sessionStartTime = Rx<DateTime?>(null);
  final Rx<Duration> elapsed = Duration.zero.obs;

  StreamSubscription? _userListener;
  String? _currentSessionId;

  // ------------------------------------------------
  // INIT
  // ------------------------------------------------

  @override
  void onInit() {
    super.onInit();

    FirebaseAuth.instance.authStateChanges().listen((user) async {

      if (user != null) {
        await bootstrapSession();
        attachRealtimeListeners();
      } else {
        isLoading.value = false;
      }
    });

    // Timer ticker
    Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (isSessionActive.value &&
          sessionStartTime.value != null) {
        elapsed.value =
            DateTime.now().difference(sessionStartTime.value!);
      }
    });
  }

  @override
  void onClose() {
    _userListener?.cancel();
    super.onClose();
  }

  // ------------------------------------------------
  // BOOTSTRAP (Cold Start)
  // ------------------------------------------------

  Future<void> bootstrapSession() async {
    isLoading.value = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      isLoading.value = false;
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      await _handleSessionEnd();
      isLoading.value = false;
      return;
    }

    final sessionId = userDoc.data()?['currentSessionId'];

    if (sessionId == null) {
      await _handleSessionEnd();
      isLoading.value = false;
      return;
    }

    _currentSessionId = sessionId;

    final sessionDoc = await userRef
        .collection('sessions')
        .doc(sessionId)
        .get();

    if (!sessionDoc.exists) {
      await _handleSessionEnd();
      isLoading.value = false;
      return;
    }

    final data = sessionDoc.data()!;
    final startMillis = data['startTime'];

    if (startMillis is int) {
      final startTime =
          DateTime.fromMillisecondsSinceEpoch(startMillis);

      sessionStartTime.value = startTime;
      elapsed.value =
          DateTime.now().difference(startTime);

      isSessionActive.value = true;
      
      // Start overlay for active session on app restart
      await OverlayService.showOverlay();
    } else {
      await _handleSessionEnd();
    }

    isLoading.value = false;
  }

  // ------------------------------------------------
  // REALTIME SYNC
  // ------------------------------------------------

void attachRealtimeListeners() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final userRef =
      FirebaseFirestore.instance.collection('users').doc(user.uid);

  _userListener = userRef.snapshots().listen((doc) async {
    final sessionId = doc.data()?['currentSessionId'];

    // CASE 1: Session ended
    if (sessionId == null) {
      _currentSessionId = null;
      await _handleSessionEnd();
      return;
    }

    // CASE 2: New session started
    if (_currentSessionId != sessionId) {
      _currentSessionId = sessionId;

      final sessionDoc = await userRef
          .collection('sessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) return;

      final data = sessionDoc.data()!;
      final startMillis = data['startTime'];

      if (startMillis is int) {
        final startTime =
            DateTime.fromMillisecondsSinceEpoch(startMillis);

        sessionStartTime.value = startTime;
        elapsed.value =
            DateTime.now().difference(startTime);

        isSessionActive.value = true;
        
        // Start overlay for new session detected via realtime sync
        await OverlayService.showOverlay();
      }
    }
  });
}

  // ------------------------------------------------
  // START SESSION
  // ------------------------------------------------

  Future<void> startNewSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final sessionRef = userRef.collection('sessions').doc();

    await FirebaseFirestore.instance.runTransaction((tx) async {
      tx.set(sessionRef, {
        "startTime": DateTime.now().millisecondsSinceEpoch,
        "createdAt": FieldValue.serverTimestamp(),
        "topic": "extension",
        "distractions": 0,
        "distractionTime": 0,
        "focusScore": 100,
      });

      tx.update(userRef, {
        "currentSessionId": sessionRef.id,
      });
    });

    // Show overlay when session starts
    await OverlayService.showOverlay();
  }

  // ------------------------------------------------
  // END SESSION
  // ------------------------------------------------

  Future<void> endCurrentSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentSessionId == null) return;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final sessionRef =
        userRef.collection('sessions').doc(_currentSessionId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      tx.update(sessionRef, {
        "endTime": DateTime.now().millisecondsSinceEpoch,
      });

      tx.update(userRef, {
        "currentSessionId": FieldValue.delete(),
      });
    });

    // Close overlay when session ends
    await OverlayService.closeOverlay();
  }

  // ------------------------------------------------
  // SESSION STATE HANDLERS
  // ------------------------------------------------

  Future<void> _handleSessionEnd() async {
    isSessionActive.value = false;
    sessionStartTime.value = null;
    elapsed.value = Duration.zero;
    
    // Close overlay when session ends
    await OverlayService.closeOverlay();
  }

  // ------------------------------------------------
  // FORMAT TIMER
  // ------------------------------------------------

  String formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h == '00' ? '$m:$s' : '$h:$m:$s';
  }
}