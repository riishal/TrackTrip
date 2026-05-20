import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final String id;
  final String name;
  final String location;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final double budgetPerHead;
  final int totalMembers;
  final String adminId;
  final String tripCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripModel({
    required this.id,
    required this.name,
    required this.location,
    this.description = '',
    required this.startDate,
    required this.endDate,
    required this.budgetPerHead,
    required this.totalMembers,
    required this.adminId,
    required this.tripCode,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalBudget => budgetPerHead * totalMembers;

  TripModel copyWith({
    String? id,
    String? name,
    String? location,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    double? budgetPerHead,
    int? totalMembers,
    String? adminId,
    String? tripCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budgetPerHead: budgetPerHead ?? this.budgetPerHead,
      totalMembers: totalMembers ?? this.totalMembers,
      adminId: adminId ?? this.adminId,
      tripCode: tripCode ?? this.tripCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TripModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TripModel(
      id: doc.id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      budgetPerHead: (data['budgetPerHead'] ?? 0).toDouble(),
      totalMembers: data['totalMembers'] ?? 0,
      adminId: data['adminId'] ?? '',
      tripCode: data['tripCode'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'location': location,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'budgetPerHead': budgetPerHead,
      'totalMembers': totalMembers,
      'adminId': adminId,
      'tripCode': tripCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
