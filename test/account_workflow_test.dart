import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:soilsafe_app/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:soilsafe_app/features/admin/presentation/farmer_account_details_screen.dart';
import 'package:soilsafe_app/features/admin/presentation/pending_registrations_screen.dart';
import 'package:soilsafe_app/features/assessment/data/assessment_repository.dart';
import 'package:soilsafe_app/features/auth/data/firebase_auth_service.dart';
import 'package:soilsafe_app/features/auth/data/user_repository.dart';
import 'package:soilsafe_app/features/auth/domain/app_user.dart';
import 'package:soilsafe_app/features/auth/domain/auth_failure.dart';
import 'package:soilsafe_app/features/auth/domain/farmer_registration.dart';
import 'package:soilsafe_app/features/auth/presentation/auth_controller.dart';
import 'package:soilsafe_app/features/auth/presentation/auth_gate.dart';
import 'package:soilsafe_app/features/devices/data/device_repository.dart';
import 'package:soilsafe_app/features/devices/domain/soilsafe_device.dart';
import 'package:soilsafe_app/features/notifications/data/notification_repository.dart';
import 'package:soilsafe_app/features/notifications/data/push_notification_service.dart';
import 'package:soilsafe_app/features/notifications/domain/app_notification.dart';
import 'package:soilsafe_app/features/notifications/presentation/farmer_notifications_screen.dart';

class _FakeFirebaseUser extends Fake implements User {
  _FakeFirebaseUser(this.uid, this.email);

  @override
  final String uid;

  @override
  final String? email;
}

class _FakeAuthService implements FirebaseAuthService {
  final _authController = StreamController<User?>.broadcast();
  User? _current;
  bool signedOutCalled = false;

  @override
  bool get isReady => true;

  @override
  User? get currentUser => _current;

  @override
  Stream<User?> authStateChanges() => _authController.stream;

  void emitUser(User? user) {
    _current = user;
    _authController.add(user);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> registerFarmer(FarmerRegistration registration) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {
    signedOutCalled = true;
    emitUser(null);
  }

  void dispose() {
    _authController.close();
  }
}

class _FakeUserRepository implements UserRepository {
  final Map<String, StreamController<AppUser?>> _userStreams = {};
  final _listController = StreamController<List<AppUser>>.broadcast();
  final Map<String, AppUser> _users = {};

  final List<({String uid, AccountModerationAction action, String? reason})>
      moderationCalls = [];
  AuthFailure? moderationError;

  @override
  bool get isReady => true;

  void putUser(AppUser user) {
    _users[user.uid] = user;
    _userStreams[user.uid]?.add(user);
    _listController.add(_users.values.toList());
  }

  @override
  Stream<AppUser?> watchUser(String uid) {
    final controller =
        _userStreams.putIfAbsent(uid, () => StreamController.broadcast());
    Future.microtask(() {
      if (!controller.isClosed) {
        controller.add(_users[uid]);
      }
    });
    return controller.stream;
  }

  @override
  Future<AppUser?> getUser(String uid) async => _users[uid];

  @override
  Future<void> createFarmerProfile(AppUser profile) async {
    putUser(profile);
  }

  @override
  Future<void> updateOwnProfile({
    required String uid,
    required Map<String, dynamic> fields,
  }) async {}

  @override
  Stream<List<AppUser>> watchUsers({UserRole? role, AccountStatus? status}) {
    Future.microtask(() {
      if (!_listController.isClosed) {
        _listController.add(_users.values.toList());
      }
    });
    return _listController.stream.map((list) {
      return list.where((u) {
        if (role != null && u.role != role) return false;
        if (status != null && u.status != status) return false;
        return true;
      }).toList();
    });
  }

  @override
  Future<void> reviewFarmerAccount({
    required String uid,
    required AccountModerationAction action,
    String? reason,
  }) async {
    if (moderationError != null) {
      throw moderationError!;
    }
    moderationCalls.add((uid: uid, action: action, reason: reason));
    final current = _users[uid];
    if (current != null) {
      final nextStatus = switch (action) {
        AccountModerationAction.approve => AccountStatus.active,
        AccountModerationAction.reject => AccountStatus.rejected,
        AccountModerationAction.block => AccountStatus.blocked,
        AccountModerationAction.unblock => AccountStatus.active,
      };
      putUser(
        current.copyWith(
          status: nextStatus,
          rejectionReason:
              action == AccountModerationAction.reject ? reason : null,
        ),
      );
    }
  }

  void dispose() {
    for (final c in _userStreams.values) {
      c.close();
    }
    _listController.close();
  }
}

class _FakeNotificationRepository implements NotificationRepository {
  final _controller = StreamController<List<AppNotification>>.broadcast();
  List<AppNotification> _items = [];
  final List<({String id, String readerUid})> markedRead = [];

  @override
  bool get isReady => true;

  void setItems(List<AppNotification> items) {
    _items = items;
    _controller.add(items);
  }

  Stream<List<AppNotification>> _emitAndWatch() {
    Future.microtask(() {
      if (!_controller.isClosed) {
        _controller.add(_items);
      }
    });
    return _controller.stream;
  }

  @override
  Stream<List<AppNotification>> watchAdminNotifications() {
    return _emitAndWatch().map(
      (list) => list
          .where((n) => n.targetRole == NotificationTargetRole.admin)
          .toList(),
    );
  }

  @override
  Stream<int> watchAdminUnreadCount() {
    return watchAdminNotifications().map(
      (list) => list.where((n) => !n.isRead).length,
    );
  }

  @override
  Stream<List<AppNotification>> watchFarmerNotifications(String uid) {
    return _emitAndWatch().map(
      (list) => list
          .where((n) =>
              n.targetRole == NotificationTargetRole.farmer &&
              n.recipientUid == uid)
          .toList(),
    );
  }

  @override
  Stream<int> watchFarmerUnreadCount(String uid) {
    return watchFarmerNotifications(uid).map(
      (list) => list.where((n) => !n.isRead).length,
    );
  }

  @override
  Future<void> markAsRead({
    required String notificationId,
    required String readerUid,
  }) async {
    markedRead.add((id: notificationId, readerUid: readerUid));
    _items = _items
        .map(
          (n) => n.id == notificationId
              ? AppNotification(
                  id: n.id,
                  targetRole: n.targetRole,
                  recipientUid: n.recipientUid,
                  farmerUid: n.farmerUid,
                  farmerName: n.farmerName,
                  farmerEmail: n.farmerEmail,
                  title: n.title,
                  message: n.message,
                  type: n.type,
                  rejectionReason: n.rejectionReason,
                  isRead: true,
                  createdAt: n.createdAt,
                  registrationDate: n.registrationDate,
                  readBy: readerUid,
                )
              : n,
        )
        .toList();
    _controller.add(_items);
  }

  @override
  Future<void> markAllAsRead({
    required List<AppNotification> notifications,
    required String readerUid,
  }) async {
    for (final n in notifications.where((e) => !e.isRead)) {
      await markAsRead(notificationId: n.id, readerUid: readerUid);
    }
  }

  void dispose() {
    _controller.close();
  }
}

class _FakeDeviceRepository extends Fake implements DeviceRepository {
  @override
  Stream<List<SoilSafeDevice>> watchAll() => Stream.value(const []);
}

class _FakeAssessmentRepository extends Fake implements AssessmentRepository {
  @override
  Stream<List<SoilAssessmentRecord>> watchAll() => Stream.value(const []);

  @override
  Stream<List<SoilAssessmentRecord>> watchForOwner(String ownerUid) =>
      Stream.value(const []);
}

AppUser _sampleFarmer({
  String uid = 'farmer-1',
  AccountStatus status = AccountStatus.pending,
  String? rejectionReason,
}) {
  return AppUser(
    uid: uid,
    fullName: 'Juan Dela Cruz',
    email: 'farmer@example.com',
    contactNumber: '09171234567',
    farmName: 'Dela Cruz Banana Farm',
    farmLocation: 'Barangay Mabuhay',
    municipality: 'Panabo',
    province: 'Davao del Norte',
    role: UserRole.farmer,
    status: status,
    createdAt: DateTime(2026, 11, 20, 9, 30),
    rejectionReason: rejectionReason,
  );
}

AppUser _sampleAdmin() {
  return const AppUser(
    uid: 'admin-1',
    fullName: 'SoilSAFE Admin',
    email: 'admin@soilsafe.app',
    contactNumber: '09181112222',
    farmName: '',
    farmLocation: '',
    municipality: '',
    province: '',
    role: UserRole.admin,
    status: AccountStatus.active,
  );
}

Widget _wrapWithProviders({
  required Widget child,
  required AuthController authController,
  required UserRepository userRepository,
  required NotificationRepository notificationRepository,
}) {
  return MultiProvider(
    providers: [
      Provider<UserRepository>.value(value: userRepository),
      Provider<NotificationRepository>.value(value: notificationRepository),
      Provider<DeviceRepository>.value(value: _FakeDeviceRepository()),
      Provider<AssessmentRepository>.value(value: _FakeAssessmentRepository()),
      ChangeNotifierProvider<AuthController>.value(value: authController),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Farmer registration and security model', () {
    test('farmer registration map forces farmer role and pending status', () {
      final profile = AppUser(
        uid: 'uid-farmer',
        fullName: 'Juan Dela Cruz',
        email: 'farmer@example.com',
        contactNumber: '09171234567',
        farmName: 'Block A',
        farmLocation: 'Sitio Uno',
        municipality: 'Panabo',
        province: 'Davao del Norte',
        role: UserRole.farmer,
        status: AccountStatus.pending,
      );

      final createMap = profile.toCreateMap();
      expect(createMap['role'], 'farmer');
      expect(createMap['status'], 'pending');
      expect(createMap.containsKey('createdAt'), isTrue);
      expect(createMap.containsKey('updatedAt'), isTrue);

      // Profile updates never include role, status, uid, or email.
      final updateMap = profile.toProfileUpdateMap();
      expect(updateMap.containsKey('role'), isFalse);
      expect(updateMap.containsKey('status'), isFalse);
      expect(updateMap.containsKey('uid'), isFalse);
      expect(updateMap.containsKey('email'), isFalse);
    });

    test('notification model parses admin and farmer notifications', () {
      final adminNotif = AppNotification.fromMap('new_registration_f1', {
        'id': 'new_registration_f1',
        'targetRole': 'admin',
        'farmerUid': 'f1',
        'farmerName': 'Juan Dela Cruz',
        'farmerEmail': 'farmer@example.com',
        'title': 'New Farmer Registration',
        'message':
            'Juan Dela Cruz has submitted a registration request and is waiting for account approval.',
        'type': 'new_registration',
        'isRead': false,
        'createdAt': DateTime(2026, 11, 20, 9, 30),
      });

      expect(adminNotif.targetRole, NotificationTargetRole.admin);
      expect(adminNotif.type, NotificationType.newRegistration);
      expect(adminNotif.isRead, isFalse);

      final rejectedNotif = AppNotification.fromMap('notif-2', {
        'targetRole': 'farmer',
        'recipientUid': 'f1',
        'farmerUid': 'f1',
        'farmerName': 'Juan Dela Cruz',
        'title': 'SoilSAFE Account Not Approved',
        'message':
            'Your registration was not approved. Reason: Invalid location',
        'type': 'account_rejected',
        'rejectionReason': 'Invalid location',
        'isRead': false,
      });

      expect(rejectedNotif.targetRole, NotificationTargetRole.farmer);
      expect(rejectedNotif.type, NotificationType.accountRejected);
      expect(rejectedNotif.rejectionReason, 'Invalid location');
    });

    test('FCM token document ID is deterministic and collision-safe', () {
      final id1 = PushNotificationService.tokenDocumentId('token-abc-123');
      final id2 = PushNotificationService.tokenDocumentId('token-abc-123');
      final id3 = PushNotificationService.tokenDocumentId('token-xyz-789');

      expect(id1, id2);
      expect(id1, isNot(id3));
      expect(id1.startsWith('fcm_'), isTrue);
    });
  });

  group('Real-time approval and rejection routing (Scenarios A, B, C)', () {
    testWidgets(
      'pending farmer sees Waiting for Approval, cannot access dashboard, '
      'and automatically redirects to Farmer Dashboard when approved',
      (tester) async {
        final authService = _FakeAuthService();
        final userRepo = _FakeUserRepository();
        final notifRepo = _FakeNotificationRepository();
        final controller = AuthController(
          authService: authService,
          userRepository: userRepo,
        );

        userRepo.putUser(_sampleFarmer(status: AccountStatus.pending));
        authService.emitUser(
          _FakeFirebaseUser('farmer-1', 'farmer@example.com'),
        );

        await tester.pumpWidget(
          _wrapWithProviders(
            authController: controller,
            userRepository: userRepo,
            notificationRepository: notifRepo,
            child: const AuthGate(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.text('Your Account is Waiting for Approval'),
          findsOneWidget,
        );
        expect(find.text('PENDING APPROVAL'), findsOneWidget);
        expect(find.text('Log out'), findsOneWidget);
        expect(find.text('Start New Soil Scan'), findsNothing);
        expect(find.text('Your soil health overview'), findsNothing);

        // Admin approves account on the server -> Firestore stream updates.
        userRepo.putUser(_sampleFarmer(status: AccountStatus.active));
        await tester.pumpAndSettle();

        expect(find.text('Your soil health overview'), findsOneWidget);
        expect(find.text('Start New Soil Scan'), findsOneWidget);
        expect(
          find.text('Your Account is Waiting for Approval'),
          findsNothing,
        );

        controller.dispose();
        authService.dispose();
        userRepo.dispose();
        notifRepo.dispose();
      },
    );

    testWidgets(
      'rejected farmer automatically sees Rejected screen with rejection reason',
      (tester) async {
        final authService = _FakeAuthService();
        final userRepo = _FakeUserRepository();
        final notifRepo = _FakeNotificationRepository();
        final controller = AuthController(
          authService: authService,
          userRepository: userRepo,
        );

        userRepo.putUser(_sampleFarmer(status: AccountStatus.pending));
        authService.emitUser(
          _FakeFirebaseUser('farmer-1', 'farmer@example.com'),
        );

        await tester.pumpWidget(
          _wrapWithProviders(
            authController: controller,
            userRepository: userRepo,
            notificationRepository: notifRepo,
            child: const AuthGate(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Admin rejects with reason.
        userRepo.putUser(
          _sampleFarmer(
            status: AccountStatus.rejected,
            rejectionReason: 'Incomplete plantation address',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Registration Was Not Approved'), findsOneWidget);
        expect(find.text('Reason for Rejection'), findsOneWidget);
        expect(find.text('Incomplete plantation address'), findsOneWidget);
        expect(find.text('Start New Soil Scan'), findsNothing);

        controller.dispose();
        authService.dispose();
        userRepo.dispose();
        notifRepo.dispose();
      },
    );
  });

  group('Admin notifications, pending management, and authorization (Scenarios D, E)', () {
    testWidgets(
      'Admin Dashboard shows unread notification badge and pending count, '
      'and Admin Notifications screen opens farmer review and marks read',
      (tester) async {
        final authService = _FakeAuthService();
        final userRepo = _FakeUserRepository();
        final notifRepo = _FakeNotificationRepository();
        final controller = AuthController(
          authService: authService,
          userRepository: userRepo,
        );

        final farmer = _sampleFarmer(status: AccountStatus.pending);
        userRepo.putUser(_sampleAdmin());
        userRepo.putUser(farmer);
        notifRepo.setItems([
          AppNotification(
            id: 'new_registration_farmer-1',
            targetRole: NotificationTargetRole.admin,
            farmerUid: 'farmer-1',
            farmerName: 'Juan Dela Cruz',
            farmerEmail: 'farmer@example.com',
            title: 'New Farmer Registration',
            message:
                'Juan Dela Cruz has submitted a registration request and is waiting for account approval.',
            type: NotificationType.newRegistration,
            isRead: false,
            registrationDate: DateTime(2026, 11, 20, 9, 30),
            createdAt: DateTime(2026, 11, 20, 9, 30),
          ),
        ]);

        authService.emitUser(
          _FakeFirebaseUser('admin-1', 'admin@soilsafe.app'),
        );

        await tester.pumpWidget(
          _wrapWithProviders(
            authController: controller,
            userRepository: userRepo,
            notificationRepository: notifRepo,
            child: const AdminDashboardScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('1 farmer waiting for approval'), findsOneWidget);
        expect(find.text('1'), findsWidgets);

        await tester.tap(find.byTooltip('Admin Notifications'));
        await tester.pumpAndSettle();

        expect(find.text('Admin Notifications'), findsOneWidget);
        expect(find.text('New Farmer Registration'), findsOneWidget);
        expect(find.text('Farmer: Juan Dela Cruz'), findsOneWidget);

        await tester.tap(find.text('New Farmer Registration'));
        await tester.pumpAndSettle();

        expect(notifRepo.markedRead.length, 1);
        expect(notifRepo.markedRead.first.id, 'new_registration_farmer-1');
        await tester.scrollUntilVisible(
          find.text('Approve registration'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('Approve registration'), findsOneWidget);
        expect(find.text('Reject registration'), findsOneWidget);

        controller.dispose();
        authService.dispose();
        userRepo.dispose();
        notifRepo.dispose();
      },
    );

    testWidgets(
      'PendingRegistrationsScreen displays all required farmer fields and '
      'Admin can reject with a reason',
      (tester) async {
        final authService = _FakeAuthService();
        final userRepo = _FakeUserRepository();
        final notifRepo = _FakeNotificationRepository();
        final controller = AuthController(
          authService: authService,
          userRepository: userRepo,
        );

        final farmer = _sampleFarmer(status: AccountStatus.pending);
        userRepo.putUser(farmer);

        await tester.pumpWidget(
          _wrapWithProviders(
            authController: controller,
            userRepository: userRepo,
            notificationRepository: notifRepo,
            child: const PendingRegistrationsScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Juan Dela Cruz'), findsOneWidget);
        expect(find.text('farmer@example.com'), findsOneWidget);
        expect(find.text('09171234567'), findsOneWidget);
        expect(find.text('Dela Cruz Banana Farm'), findsOneWidget);
        expect(find.text('Panabo, Davao del Norte'), findsOneWidget);
        expect(find.text('Pending approval'), findsOneWidget);

        await tester.tap(find.text('Juan Dela Cruz'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Reject registration'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.text('Reject registration'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          'Missing barangay details',
        );
        await tester.tap(find.text('Reject account'));
        await tester.pumpAndSettle();

        expect(userRepo.moderationCalls.length, 1);
        expect(userRepo.moderationCalls.first.uid, 'farmer-1');
        expect(
          userRepo.moderationCalls.first.action,
          AccountModerationAction.reject,
        );
        expect(
          userRepo.moderationCalls.first.reason,
          'Missing barangay details',
        );

        controller.dispose();
        authService.dispose();
        userRepo.dispose();
        notifRepo.dispose();
      },
    );

    testWidgets(
      'Unauthorized user attempting approval receives permission-denied error',
      (tester) async {
        final authService = _FakeAuthService();
        final userRepo = _FakeUserRepository()
          ..moderationError = const AuthFailure(
            'Only an authorized administrator can perform this action.',
          );
        final notifRepo = _FakeNotificationRepository();
        final controller = AuthController(
          authService: authService,
          userRepository: userRepo,
        );

        final farmer = _sampleFarmer(status: AccountStatus.pending);
        userRepo.putUser(farmer);

        await tester.pumpWidget(
          _wrapWithProviders(
            authController: controller,
            userRepository: userRepo,
            notificationRepository: notifRepo,
            child: FarmerAccountDetailsScreen(farmer: farmer),
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Approve registration'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.text('Approve registration'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Approve'));
        await tester.pumpAndSettle();

        expect(
          find.text('Only an authorized administrator can perform this action.'),
          findsOneWidget,
        );

        controller.dispose();
        authService.dispose();
        userRepo.dispose();
        notifRepo.dispose();
      },
    );

    testWidgets('FarmerNotificationsScreen only shows notifications owned by the farmer',
        (tester) async {
      final authService = _FakeAuthService();
      final userRepo = _FakeUserRepository();
      final notifRepo = _FakeNotificationRepository();
      final controller = AuthController(
        authService: authService,
        userRepository: userRepo,
      );

      notifRepo.setItems([
        AppNotification(
          id: 'notif-farmer-1',
          targetRole: NotificationTargetRole.farmer,
          recipientUid: 'farmer-1',
          farmerUid: 'farmer-1',
          farmerName: 'Juan Dela Cruz',
          farmerEmail: 'farmer@example.com',
          title: 'SoilSAFE Account Approved',
          message:
              'Your account has been approved. You can now access your SoilSAFE dashboard.',
          type: NotificationType.accountApproved,
          isRead: false,
          createdAt: DateTime(2026, 11, 21, 10, 0),
        ),
        AppNotification(
          id: 'notif-farmer-2',
          targetRole: NotificationTargetRole.farmer,
          recipientUid: 'farmer-2',
          farmerUid: 'farmer-2',
          farmerName: 'Other Farmer',
          farmerEmail: 'other@example.com',
          title: 'Private Other Farmer Notification',
          message: 'Should not appear for farmer-1',
          type: NotificationType.accountApproved,
          isRead: false,
        ),
      ]);

      await tester.pumpWidget(
        _wrapWithProviders(
          authController: controller,
          userRepository: userRepo,
          notificationRepository: notifRepo,
          child: const FarmerNotificationsScreen(farmerUid: 'farmer-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SoilSAFE Account Approved'), findsOneWidget);
      expect(find.text('Private Other Farmer Notification'), findsNothing);

      controller.dispose();
      authService.dispose();
      userRepo.dispose();
      notifRepo.dispose();
    });

    test('firestore.rules enforces role, status, notification, and audit protections',
        () {
      final rules = File('firestore.rules').readAsStringSync();
      expect(rules, contains("request.resource.data.role == 'farmer'"));
      expect(rules, contains("request.resource.data.status == 'pending'"));
      expect(rules, contains('match /notifications/{notificationId}'));
      expect(rules, contains('allow create, delete: if false;'));
      expect(rules, contains('match /audit_logs/{logId}'));
      expect(rules, contains('allow create, update, delete: if false;'));
      expect(rules, contains('match /fcmTokens/{tokenId}'));
    });
  });
}
