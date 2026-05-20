import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_model.dart';
import '../models/member_model.dart';
import '../models/expense_model.dart';
import '../models/payment_model.dart';

/// Central Firestore service for all CRUD operations
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── TRIPS ───────────────────────────────────────────────

  /// Stream all trips for an admin
  Stream<List<TripModel>> streamTrips(String adminId) {
    return _db
        .collection('trips')
        .where('adminId', isEqualTo: adminId)
        .snapshots()
        .map((snap) {
          final trips = snap.docs.map((d) => TripModel.fromFirestore(d)).toList();
          trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return trips;
        });
  }

  /// Get a single trip by ID
  Future<TripModel?> getTrip(String tripId) async {
    final doc = await _db.collection('trips').doc(tripId).get();
    if (!doc.exists) return null;
    return TripModel.fromFirestore(doc);
  }

  /// Get trip by trip code (for member login)
  Future<TripModel?> getTripByCode(String tripCode) async {
    final snap = await _db
        .collection('trips')
        .where('tripCode', isEqualTo: tripCode.trim().toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return TripModel.fromFirestore(snap.docs.first);
  }

  /// Stream a single trip
  Stream<TripModel?> streamTrip(String tripId) {
    return _db
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .map((doc) => doc.exists ? TripModel.fromFirestore(doc) : null);
  }

  /// Create a trip
  Future<String> createTrip(TripModel trip) async {
    final doc = await _db.collection('trips').add(trip.toFirestore());
    return doc.id;
  }

  /// Update a trip
  Future<void> updateTrip(TripModel trip) async {
    await _db.collection('trips').doc(trip.id).update(trip.toFirestore());
  }

  /// Delete a trip and all its related data
  Future<void> deleteTrip(String tripId) async {
    final batch = _db.batch();
    // Delete members
    final members = await _db
        .collection('members')
        .where('tripId', isEqualTo: tripId)
        .get();
    for (final doc in members.docs) {
      batch.delete(doc.reference);
    }
    // Delete expenses
    final expenses = await _db
        .collection('expenses')
        .where('tripId', isEqualTo: tripId)
        .get();
    for (final doc in expenses.docs) {
      batch.delete(doc.reference);
    }
    // Delete payments
    final payments = await _db
        .collection('payments')
        .where('tripId', isEqualTo: tripId)
        .get();
    for (final doc in payments.docs) {
      batch.delete(doc.reference);
    }
    // Delete the trip
    batch.delete(_db.collection('trips').doc(tripId));
    await batch.commit();
  }

  // ─── MEMBERS ─────────────────────────────────────────────

  /// Stream members for a trip
  Stream<List<MemberModel>> streamMembers(String tripId) {
    return _db
        .collection('members')
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snap) {
          final members = snap.docs.map((d) => MemberModel.fromFirestore(d)).toList();
          members.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          return members;
        });
  }

  /// Add a member
  Future<String> addMember(MemberModel member) async {
    final doc = await _db.collection('members').add(member.toFirestore());
    // Update trip's total members count
    await _updateTripMemberCount(member.tripId);
    return doc.id;
  }

  /// Update a member
  Future<void> updateMember(MemberModel member) async {
    await _db.collection('members').doc(member.id).update(member.toFirestore());
  }

  /// Delete a member
  Future<void> deleteMember(String memberId, String tripId) async {
    await _db.collection('members').doc(memberId).delete();
    await _updateTripMemberCount(tripId);

    // Also delete any payments associated with this member
    final payments = await _db
        .collection('payments')
        .where('memberId', isEqualTo: memberId)
        .get();
    final batch = _db.batch();
    for (final doc in payments.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Recalculate and update trip member count
  Future<void> _updateTripMemberCount(String tripId) async {
    final snap = await _db
        .collection('members')
        .where('tripId', isEqualTo: tripId)
        .get();
    await _db.collection('trips').doc(tripId).update({
      'totalMembers': snap.docs.length,
    });
  }

  // ─── EXPENSES ────────────────────────────────────────────

  /// Stream expenses for a trip
  Stream<List<ExpenseModel>> streamExpenses(String tripId) {
    return _db
        .collection('expenses')
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snap) {
          final expenses = snap.docs.map((d) => ExpenseModel.fromFirestore(d)).toList();
          expenses.sort((a, b) => b.date.compareTo(a.date));
          return expenses;
        });
  }

  /// Add an expense
  Future<String> addExpense(ExpenseModel expense) async {
    final doc = await _db.collection('expenses').add(expense.toFirestore());
    return doc.id;
  }

  /// Update an expense
  Future<void> updateExpense(ExpenseModel expense) async {
    await _db
        .collection('expenses')
        .doc(expense.id)
        .update(expense.toFirestore());
  }

  /// Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    await _db.collection('expenses').doc(expenseId).delete();
  }

  // ─── PAYMENTS ────────────────────────────────────────────

  /// Stream payments for a trip
  Stream<List<PaymentModel>> streamPayments(String tripId) {
    return _db
        .collection('payments')
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snap) {
          final payments = snap.docs.map((d) => PaymentModel.fromFirestore(d)).toList();
          payments.sort((a, b) => b.date.compareTo(a.date));
          return payments;
        });
  }

  /// Add a payment and update member's contribution
  Future<String> addPayment(PaymentModel payment) async {
    final doc = await _db.collection('payments').add(payment.toFirestore());
    
    // Atomically increment the member's paid amount instantly
    await _db.collection('members').doc(payment.memberId).update({
      'amountPaid': FieldValue.increment(payment.amount),
      'updatedAt': Timestamp.now(),
    });
    
    // Recalculate full sum in the background with a delay to settle indices
    _recalculateMemberPayments(payment.memberId, payment.tripId);
    
    return doc.id;
  }

  /// Update a payment and update member's contribution
  Future<void> updatePayment(PaymentModel payment) async {
    final doc = await _db.collection('payments').doc(payment.id).get();
    double diff = payment.amount;
    if (doc.exists) {
      final oldAmount = (doc.data()?['amount'] ?? 0).toDouble();
      diff = payment.amount - oldAmount;
    }

    await _db
        .collection('payments')
        .doc(payment.id)
        .update(payment.toFirestore());

    if (diff != 0) {
      await _db.collection('members').doc(payment.memberId).update({
        'amountPaid': FieldValue.increment(diff),
        'updatedAt': Timestamp.now(),
      });
    }

    _recalculateMemberPayments(payment.memberId, payment.tripId);
  }

  /// Delete a payment and update member's contribution
  Future<void> deletePayment(
    String paymentId,
    String memberId,
    String tripId,
  ) async {
    final doc = await _db.collection('payments').doc(paymentId).get();
    double amount = 0;
    if (doc.exists) {
      amount = (doc.data()?['amount'] ?? 0).toDouble();
    }

    await _db.collection('payments').doc(paymentId).delete();

    if (amount > 0) {
      await _db.collection('members').doc(memberId).update({
        'amountPaid': FieldValue.increment(-amount),
        'updatedAt': Timestamp.now(),
      });
    }

    _recalculateMemberPayments(memberId, tripId);
  }

  /// Helper to recalculate a member's total payments and status (with indexing safety delay)
  Future<void> _recalculateMemberPayments(
    String memberId,
    String tripId,
  ) async {
    // Add a slight delay to allow Firestore indexes to fully settle
    await Future.delayed(const Duration(milliseconds: 300));

    final paymentsSnap = await _db
        .collection('payments')
        .where('memberId', isEqualTo: memberId)
        .get();

    double totalPaid = 0;
    for (final doc in paymentsSnap.docs) {
      totalPaid += (doc.data()['amount'] ?? 0).toDouble();
    }

    if (totalPaid < 0) totalPaid = 0;

    final tripDoc = await _db.collection('trips').doc(tripId).get();
    double budgetPerHead = 0;
    if (tripDoc.exists) {
      budgetPerHead = (tripDoc.data()?['budgetPerHead'] ?? 0).toDouble();
    }

    String status = 'Pending';
    if (totalPaid >= budgetPerHead && budgetPerHead > 0) {
      status = 'Paid';
    } else if (totalPaid > 0) {
      status = 'Partial';
    }

    await _db.collection('members').doc(memberId).update({
      'amountPaid': totalPaid,
      'paymentStatus': status,
      'updatedAt': Timestamp.now(),
    });
  }

  // ─── ANALYTICS HELPERS ──────────────────────────────────

  /// Get total expenses for a trip
  Future<double> getTotalExpenses(String tripId) async {
    final snap = await _db
        .collection('expenses')
        .where('tripId', isEqualTo: tripId)
        .get();
    double total = 0;
    for (final doc in snap.docs) {
      total += (doc.data()['amount'] ?? 0).toDouble();
    }
    return total;
  }

  /// Get total collected from members
  Future<double> getTotalCollected(String tripId) async {
    final snap = await _db
        .collection('members')
        .where('tripId', isEqualTo: tripId)
        .get();
    double total = 0;
    for (final doc in snap.docs) {
      total += (doc.data()['amountPaid'] ?? 0).toDouble();
    }
    return total;
  }
}

/// Global provider for FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
