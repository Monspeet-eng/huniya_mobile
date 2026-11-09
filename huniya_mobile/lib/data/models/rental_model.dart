import 'property_model.dart';

class RentalModel {
  final int id;
  final int tenantId;
  final int propertyId;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime nextDueDate;
  final double monthlyPrice;
  final String status;
  final PropertyModel? property;

  const RentalModel({
    required this.id,
    required this.tenantId,
    required this.propertyId,
    required this.startDate,
    required this.endDate,
    required this.nextDueDate,
    required this.monthlyPrice,
    required this.status,
    this.property,
  });

  factory RentalModel.fromJson(Map<String, dynamic> json) {
    return RentalModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      tenantId: int.tryParse(json['tenant_id']?.toString() ?? '0') ?? 0,
      propertyId: int.tryParse(json['property_id']?.toString() ?? '0') ?? 0,
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_date']?.toString() ?? '') ?? DateTime.now(),
      nextDueDate: DateTime.tryParse(json['next_due_date']?.toString() ?? '') ?? DateTime.now(),
      monthlyPrice: double.tryParse(json['monthly_price']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '',
      property: json['property'] is Map<String, dynamic>
          ? PropertyModel.fromJson(json['property'] as Map<String, dynamic>)
          : null,
    );
  }
}
