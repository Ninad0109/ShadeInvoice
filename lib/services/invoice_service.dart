import 'package:flutter/foundation.dart';
import 'package:shadeinvoice/models/invoice_model.dart';
import 'package:shadeinvoice/models/client_model.dart';
import 'package:shadeinvoice/services/local_storage_service.dart';

class InvoiceService extends ChangeNotifier {
  List<Invoice> _invoices = [];
  List<Client> _clients = [];
  Map<String, String> _companyInfo = {};

  List<Invoice> get invoices => _invoices;
  List<Client> get clients => _clients;
  Map<String, String> get companyInfo => _companyInfo;
  void _updateAllInvoiceStatuses() {
    final now = DateTime.now();
    for (int i = 0; i < _invoices.length; i++) {
      Invoice invoice = _invoices[i];
      if (invoice.status != InvoiceStatus.paid && invoice.status != InvoiceStatus.draft) {
        if (invoice.dueDate.isBefore(now) && invoice.status != InvoiceStatus.overdue) {
          _invoices[i] = invoice.copyWith(status: InvoiceStatus.overdue);
          // OR: invoice.status = InvoiceStatus.overdue;
        }
      }
    }
  }
  Future<void> loadData() async {
    _invoices = await LocalStorageService.loadInvoices();
    _clients = await LocalStorageService.loadClients();
    _companyInfo = await LocalStorageService.loadCompanyInfo();
    _updateAllInvoiceStatuses();
    notifyListeners();
  }

  Future<void> saveInvoice(Invoice invoice) async {
    await LocalStorageService.saveInvoice(invoice);
    await loadData();
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await LocalStorageService.deleteInvoice(invoiceId);
    await loadData();
  }

  Future<void> saveClient(Client client) async {
    await LocalStorageService.saveClient(client);
    await loadData();
  }

  Future<void> deleteClient(String clientId) async {
    await LocalStorageService.deleteClient(clientId);
    await loadData();
  }

  Future<void> saveCompanyInfo(Map<String, String> companyInfo) async {
    await LocalStorageService.saveCompanyInfo(companyInfo);
    await loadData();
  }

  String generateInvoiceNumber() {
    final year = DateTime.now().year;
    final existingNumbers = _invoices
        .where((invoice) => invoice.invoiceNumber.startsWith('INV-$year'))
        .map((invoice) => invoice.invoiceNumber)
        .toList();
    
    int nextNumber = 1;
    while (existingNumbers.contains('INV-$year-${nextNumber.toString().padLeft(3, '0')}')) {
      nextNumber++;
    }
    
    return 'INV-$year-${nextNumber.toString().padLeft(3, '0')}';
  }

  List<Invoice> getRecentInvoices() {
    final sortedInvoices = List<Invoice>.from(_invoices);
    sortedInvoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedInvoices.take(5).toList();
  }

  List<Invoice> getInvoicesByStatus(InvoiceStatus status) => 
      _invoices.where((invoice) => invoice.status == status).toList();

  Client? getClientById(String clientId) {
    try {
      return _clients.firstWhere((client) => client.id == clientId);
    } catch (e) {
      return null;
    }
  }

  Invoice? getInvoiceById(String invoiceId) {
    try {
      return _invoices.firstWhere((invoice) => invoice.id == invoiceId);
    } catch (e) {
      return null;
    }
  }
}