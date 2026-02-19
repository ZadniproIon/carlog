import 'package:cloud_firestore/cloud_firestore.dart';

import '../mock_data.dart';
import '../models.dart';

class CarlogDataSnapshot {
  const CarlogDataSnapshot({
    required this.vehicles,
    required this.expenses,
    required this.reminders,
    required this.isLocalOnly,
  });

  final List<Vehicle> vehicles;
  final List<CarExpense> expenses;
  final List<MaintenanceReminder> reminders;
  final bool isLocalOnly;
}

class CarlogRepository {
  CarlogRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  bool get hasFirebase => _firestore != null;

  Future<CarlogDataSnapshot> loadInitialData({
    required MockAuthUser user,
  }) async {
    if (!_canUseCloud(user)) {
      return _buildMockSnapshot(isLocalOnly: true);
    }

    try {
      final userRef = _userRef(user.uid!);
      await userRef.set({
        'email': user.email,
        'displayName': user.name,
        'lastSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final vehiclesFuture = userRef.collection('vehicles').get();
      final expensesFuture = userRef.collection('expenses').get();
      final remindersFuture = userRef.collection('reminders').get();

      final vehiclesDocs = await vehiclesFuture;
      final expensesDocs = await expensesFuture;
      final remindersDocs = await remindersFuture;

      final vehicles = vehiclesDocs.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] ??= doc.id;
        return Vehicle.fromMap(data);
      }).toList();

      final expenses = expensesDocs.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] ??= doc.id;
        return CarExpense.fromMap(data);
      }).toList();

      final reminders = remindersDocs.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] ??= doc.id;
        return MaintenanceReminder.fromMap(data);
      }).toList();

      final isFirstCloudSession =
          vehicles.isEmpty && expenses.isEmpty && reminders.isEmpty;
      if (isFirstCloudSession) {
        await _seedMockDataForUser(user.uid!);
        return _buildMockSnapshot(isLocalOnly: false);
      }

      expenses.sort((a, b) => b.date.compareTo(a.date));
      reminders.sort((a, b) {
        final aDate = a.dueDate ?? DateTime(9999);
        final bDate = b.dueDate ?? DateTime(9999);
        return aDate.compareTo(bDate);
      });

      return CarlogDataSnapshot(
        vehicles: vehicles,
        expenses: expenses,
        reminders: reminders,
        isLocalOnly: false,
      );
    } catch (_) {
      return _buildMockSnapshot(isLocalOnly: true);
    }
  }

  Future<void> addVehicle({
    required MockAuthUser user,
    required Vehicle vehicle,
  }) async {
    if (!_canUseCloud(user)) {
      return;
    }

    await _userRef(user.uid!)
        .collection('vehicles')
        .doc(vehicle.id)
        .set(vehicle.toMap(), SetOptions(merge: true));
  }

  Future<void> addExpense({
    required MockAuthUser user,
    required CarExpense expense,
  }) async {
    if (!_canUseCloud(user)) {
      return;
    }

    await _userRef(user.uid!)
        .collection('expenses')
        .doc(expense.id)
        .set(expense.toMap(), SetOptions(merge: true));
  }

  bool _canUseCloud(MockAuthUser user) {
    return _firestore != null && !user.isGuest && user.uid != null;
  }

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _firestore!.collection('users').doc(uid);
  }

  CarlogDataSnapshot _buildMockSnapshot({required bool isLocalOnly}) {
    return CarlogDataSnapshot(
      vehicles: List<Vehicle>.from(mockVehicles),
      expenses: List<CarExpense>.from(mockExpenses)
        ..sort((a, b) => b.date.compareTo(a.date)),
      reminders: List<MaintenanceReminder>.from(mockReminders),
      isLocalOnly: isLocalOnly,
    );
  }

  Future<void> _seedMockDataForUser(String uid) async {
    final userRef = _userRef(uid);
    final batch = _firestore!.batch();

    for (final vehicle in mockVehicles) {
      batch.set(
        userRef.collection('vehicles').doc(vehicle.id),
        vehicle.toMap(),
        SetOptions(merge: true),
      );
    }
    for (final expense in mockExpenses) {
      batch.set(
        userRef.collection('expenses').doc(expense.id),
        expense.toMap(),
        SetOptions(merge: true),
      );
    }
    for (final reminder in mockReminders) {
      batch.set(
        userRef.collection('reminders').doc(reminder.id),
        reminder.toMap(),
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }
}
