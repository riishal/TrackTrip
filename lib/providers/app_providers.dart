import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:track_tripp/data/models/trip_model.dart';
import 'package:track_tripp/data/models/member_model.dart';
import 'package:track_tripp/data/models/expense_model.dart';
import 'package:track_tripp/data/models/payment_model.dart';
import 'package:track_tripp/data/services/firestore_service.dart';
import 'package:track_tripp/data/services/auth_service.dart';

// ─── TRIP PROVIDERS ────────────────────────────────────────

/// Currently selected trip ID
final selectedTripIdProvider = StateProvider<String?>((ref) => null);

/// Active trip ID (either admin selected trip or logged in member trip)
final activeTripIdProvider = Provider<String?>((ref) {
  final adminSelectedId = ref.watch(selectedTripIdProvider);
  if (adminSelectedId != null) return adminSelectedId;
  final memberSession = ref.watch(memberSessionProvider);
  return memberSession?.tripId;
});

/// Stream all trips for the current admin
final tripsProvider = StreamProvider<List<TripModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).streamTrips(user.uid);
});

/// Stream the currently selected trip
final currentTripProvider = StreamProvider<TripModel?>((ref) {
  final tripId = ref.watch(activeTripIdProvider);
  if (tripId == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).streamTrip(tripId);
});

// ─── MEMBER PROVIDERS ──────────────────────────────────────

/// Stream members for the selected trip
final membersProvider = StreamProvider<List<MemberModel>>((ref) {
  final tripId = ref.watch(activeTripIdProvider);
  if (tripId == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).streamMembers(tripId);
});

/// Member search query
final memberSearchProvider = StateProvider<String>((ref) => '');

/// Member filter: 'all', 'paid', 'pending', 'partial'
final memberFilterProvider = StateProvider<String>((ref) => 'all');

/// Filtered members based on search and filter
final filteredMembersProvider = Provider<List<MemberModel>>((ref) {
  final membersAsync = ref.watch(membersProvider);
  final search = ref.watch(memberSearchProvider).toLowerCase();
  final filter = ref.watch(memberFilterProvider);

  return membersAsync.when(
    data: (members) {
      var filtered = members;

      // Apply search
      if (search.isNotEmpty) {
        filtered = filtered
            .where((m) => m.name.toLowerCase().contains(search))
            .toList();
      }

      // Apply filter
      if (filter != 'all') {
        filtered = filtered
            .where((m) => m.paymentStatus.toLowerCase() == filter)
            .toList();
      }

      return filtered;
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

// ─── EXPENSE PROVIDERS ─────────────────────────────────────

/// Stream expenses for the selected trip
final expensesProvider = StreamProvider<List<ExpenseModel>>((ref) {
  final tripId = ref.watch(activeTripIdProvider);
  if (tripId == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).streamExpenses(tripId);
});

/// Expense search query
final expenseSearchProvider = StateProvider<String>((ref) => '');

/// Expense category filter: 'all', 'Vehicle Rent', 'Petrol', etc.
final expenseCategoryFilterProvider = StateProvider<String>((ref) => 'all');

/// Expense sort: 'date', 'amount', 'category'
final expenseSortProvider = StateProvider<String>((ref) => 'date');

/// Filtered and sorted expenses
final filteredExpensesProvider = Provider<List<ExpenseModel>>((ref) {
  final expensesAsync = ref.watch(expensesProvider);
  final search = ref.watch(expenseSearchProvider).toLowerCase();
  final categoryFilter = ref.watch(expenseCategoryFilterProvider);
  final sort = ref.watch(expenseSortProvider);

  return expensesAsync.when(
    data: (expenses) {
      var filtered = List<ExpenseModel>.from(expenses);

      // Apply search
      if (search.isNotEmpty) {
        filtered = filtered
            .where(
              (e) =>
                  e.title.toLowerCase().contains(search) ||
                  e.category.toLowerCase().contains(search),
            )
            .toList();
      }

      // Apply category filter
      if (categoryFilter != 'all') {
        filtered = filtered.where((e) => e.category == categoryFilter).toList();
      }

      // Apply sort
      switch (sort) {
        case 'amount':
          filtered.sort((a, b) => b.amount.compareTo(a.amount));
          break;
        case 'category':
          filtered.sort((a, b) => a.category.compareTo(b.category));
          break;
        default: // date
          filtered.sort((a, b) => b.date.compareTo(a.date));
      }

      return filtered;
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

// ─── PAYMENT PROVIDERS ─────────────────────────────────────

/// Stream payments for the selected trip
final paymentsProvider = StreamProvider<List<PaymentModel>>((ref) {
  final tripId = ref.watch(activeTripIdProvider);
  if (tripId == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).streamPayments(tripId);
});

// ─── ANALYTICS PROVIDERS ──────────────────────────────────

/// Total expense amount for the trip
final totalExpenseProvider = Provider<double>((ref) {
  final expenses = ref.watch(expensesProvider).value ?? [];
  return expenses.fold(0.0, (sum, e) => sum + e.amount);
});

/// Total collected from members
final totalCollectedProvider = Provider<double>((ref) {
  final members = ref.watch(membersProvider).value ?? [];
  return members.fold(0.0, (sum, m) => sum + m.amountPaid);
});

/// Category-wise breakdown
final categoryBreakdownProvider = Provider<Map<String, double>>((ref) {
  final expenses = ref.watch(expensesProvider).value ?? [];
  final map = <String, double>{};
  for (final e in expenses) {
    map[e.displayCategory] = (map[e.displayCategory] ?? 0) + e.amount;
  }
  return map;
});

/// Pending collection amount
final pendingCollectionProvider = Provider<double>((ref) {
  final trip = ref.watch(currentTripProvider).value;
  final collected = ref.watch(totalCollectedProvider);
  if (trip == null) return 0;
  return trip.totalBudget - collected;
});

/// Remaining budget (budget - spent)
final remainingBudgetProvider = Provider<double>((ref) {
  final trip = ref.watch(currentTripProvider).value;
  final spent = ref.watch(totalExpenseProvider);
  if (trip == null) return 0;
  return trip.totalBudget - spent;
});

/// Per-head expense
final perHeadExpenseProvider = Provider<double>((ref) {
  final trip = ref.watch(currentTripProvider).value;
  final spent = ref.watch(totalExpenseProvider);
  if (trip == null || trip.totalMembers == 0) return 0;
  return spent / trip.totalMembers;
});

// ─── MEMBER VIEW PROVIDERS ────────────────────────────────

/// Member session state for view-only access
class MemberSession {
  final String memberName;
  final String tripId;
  final String tripCode;

  const MemberSession({
    required this.memberName,
    required this.tripId,
    required this.tripCode,
  });
}

class MemberSessionNotifier extends StateNotifier<MemberSession?> {
  final SharedPreferences _prefs;
  static const String _keyName = 'member_name';
  static const String _keyTripId = 'member_trip_id';
  static const String _keyTripCode = 'member_trip_code';

  MemberSessionNotifier(this._prefs) : super(null) {
    _loadSession();
  }

  void _loadSession() {
    final name = _prefs.getString(_keyName);
    final tripId = _prefs.getString(_keyTripId);
    final tripCode = _prefs.getString(_keyTripCode);
    if (name != null && tripId != null && tripCode != null) {
      state = MemberSession(
        memberName: name,
        tripId: tripId,
        tripCode: tripCode,
      );
    }
  }

  Future<void> saveSession(MemberSession session) async {
    await _prefs.setString(_keyName, session.memberName);
    await _prefs.setString(_keyTripId, session.tripId);
    await _prefs.setString(_keyTripCode, session.tripCode);
    state = session;
  }

  Future<void> clearSession() async {
    await _prefs.remove(_keyName);
    await _prefs.remove(_keyTripId);
    await _prefs.remove(_keyTripCode);
    state = null;
  }
}

final memberSessionProvider =
    StateNotifierProvider<MemberSessionNotifier, MemberSession?>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return MemberSessionNotifier(prefs);
    });
