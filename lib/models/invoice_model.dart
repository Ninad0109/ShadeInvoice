import 'package:billsnap/models/client_model.dart';
import 'package:billsnap/models/invoice_item_model.dart';

enum InvoiceStatus { draft, sent, paid, overdue }

class Invoice {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final Client client;
  final List<InvoiceItem> items;
  final String notes;
  final String paymentMethod;
  final InvoiceStatus status;
  final String fromCompany;
  final String fromAddress;
  final String fromEmail;
  final String fromPhone;
  final DateTime createdAt;

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get tax => subtotal * 0.0; // No tax for simplicity
  double get total => subtotal + tax;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.client,
    required this.items,
    required this.notes,
    required this.paymentMethod,
    required this.status,
    required this.fromCompany,
    required this.fromAddress,
    required this.fromEmail,
    required this.fromPhone,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoiceNumber': invoiceNumber,
    'invoiceDate': invoiceDate.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'client': client.toJson(),
    'items': items.map((item) => item.toJson()).toList(),
    'notes': notes,
    'paymentMethod': paymentMethod,
    'status': status.index,
    'fromCompany': fromCompany,
    'fromAddress': fromAddress,
    'fromEmail': fromEmail,
    'fromPhone': fromPhone,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    id: json['id'],
    invoiceNumber: json['invoiceNumber'],
    invoiceDate: DateTime.parse(json['invoiceDate']),
    dueDate: DateTime.parse(json['dueDate']),
    client: Client.fromJson(json['client']),
    items: (json['items'] as List).map((item) => InvoiceItem.fromJson(item)).toList(),
    notes: json['notes'],
    paymentMethod: json['paymentMethod'],
    status: InvoiceStatus.values[json['status']],
    fromCompany: json['fromCompany'],
    fromAddress: json['fromAddress'],
    fromEmail: json['fromEmail'],
    fromPhone: json['fromPhone'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    Client? client,
    List<InvoiceItem>? items,
    String? notes,
    String? paymentMethod,
    InvoiceStatus? status,
    String? fromCompany,
    String? fromAddress,
    String? fromEmail,
    String? fromPhone,
    DateTime? createdAt,
  }) => Invoice(
    id: id ?? this.id,
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    invoiceDate: invoiceDate ?? this.invoiceDate,
    dueDate: dueDate ?? this.dueDate,
    client: client ?? this.client,
    items: items ?? this.items,
    notes: notes ?? this.notes,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    status: status ?? this.status,
    fromCompany: fromCompany ?? this.fromCompany,
    fromAddress: fromAddress ?? this.fromAddress,
    fromEmail: fromEmail ?? this.fromEmail,
    fromPhone: fromPhone ?? this.fromPhone,
    createdAt: createdAt ?? this.createdAt,
  );
}