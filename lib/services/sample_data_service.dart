import 'package:wanderhome/models/client_model.dart';
import 'package:wanderhome/models/invoice_model.dart';
import 'package:wanderhome/models/invoice_item_model.dart';
import 'package:wanderhome/services/invoice_service.dart';

class SampleDataService {
  static Future<void> addSampleData(InvoiceService invoiceService) async {
    // Add sample company info
    final sampleCompanyInfo = {
      'name': 'WanderHome Solutions',
      'address': '123 Business Ave\nSuite 100\nCity, State 12345',
      'email': 'contact@wanderhome.com',
      'phone': '+1 (555) 123-4567',
    };
    await invoiceService.saveCompanyInfo(sampleCompanyInfo);
    // Add sample clients
    final clients = [
      Client(
        id: 'client1',
        name: 'John Smith',
        email: 'john.smith@email.com',
        phone: '+1 (555) 123-4567',
        address: '123 Main St\nNew York, NY 10001',
        company: 'Smith Enterprises',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Client(
        id: 'client2',
        name: 'Sarah Johnson',
        email: 'sarah.johnson@techcorp.com',
        phone: '+1 (555) 987-6543',
        address: '456 Oak Ave\nSan Francisco, CA 94102',
        company: 'TechCorp Solutions',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Client(
        id: 'client3',
        name: 'Mike Davis',
        email: 'mike.davis@startup.io',
        phone: '+1 (555) 456-7890',
        address: '789 Pine St\nAustin, TX 78701',
        company: 'Startup Innovations',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];

    for (final client in clients) {
      await invoiceService.saveClient(client);
    }

    // Add sample invoices
    final companyInfo = invoiceService.companyInfo;
    final invoices = [
      Invoice(
        id: 'invoice1',
        invoiceNumber: 'INV-2025-001',
        invoiceDate: DateTime.now().subtract(const Duration(days: 10)),
        dueDate: DateTime.now().add(const Duration(days: 20)),
        client: clients[0],
        items: [
          InvoiceItem(
            id: 'item1',
            description: 'Website Design and Development',
            quantity: 1,
            unitPrice: 2500.00,
          ),
          InvoiceItem(
            id: 'item2',
            description: 'Logo Design',
            quantity: 1,
            unitPrice: 500.00,
          ),
        ],
        notes: 'Payment due within 30 days of invoice date. Thank you for your business!',
        paymentMethod: 'Bank Transfer',
        status: InvoiceStatus.sent,
        fromCompany: companyInfo['name'] ?? 'Your Company Name',
        fromAddress: companyInfo['address'] ?? 'Your Company Address',
        fromEmail: companyInfo['email'] ?? 'contact@yourcompany.com',
        fromPhone: companyInfo['phone'] ?? '+1 (555) 123-4567',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Invoice(
        id: 'invoice2',
        invoiceNumber: 'INV-2025-002',
        invoiceDate: DateTime.now().subtract(const Duration(days: 5)),
        dueDate: DateTime.now().add(const Duration(days: 25)),
        client: clients[1],
        items: [
          InvoiceItem(
            id: 'item3',
            description: 'Mobile App Development',
            quantity: 1,
            unitPrice: 5000.00,
          ),
          InvoiceItem(
            id: 'item4',
            description: 'UI/UX Design',
            quantity: 1,
            unitPrice: 1500.00,
          ),
          InvoiceItem(
            id: 'item5',
            description: 'Testing and QA',
            quantity: 20,
            unitPrice: 100.00,
          ),
        ],
        notes: 'Project includes 3 months of support and maintenance.',
        paymentMethod: 'Credit Card',
        status: InvoiceStatus.draft,
        fromCompany: companyInfo['name'] ?? 'Your Company Name',
        fromAddress: companyInfo['address'] ?? 'Your Company Address',
        fromEmail: companyInfo['email'] ?? 'contact@yourcompany.com',
        fromPhone: companyInfo['phone'] ?? '+1 (555) 123-4567',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Invoice(
        id: 'invoice3',
        invoiceNumber: 'INV-2025-003',
        invoiceDate: DateTime.now().subtract(const Duration(days: 45)),
        dueDate: DateTime.now().subtract(const Duration(days: 15)),
        client: clients[2],
        items: [
          InvoiceItem(
            id: 'item6',
            description: 'Consulting Services',
            quantity: 10,
            unitPrice: 150.00,
          ),
        ],
        notes: 'Hourly consulting for technical architecture review.',
        paymentMethod: 'PayPal',
        status: InvoiceStatus.paid,
        fromCompany: companyInfo['name'] ?? 'Your Company Name',
        fromAddress: companyInfo['address'] ?? 'Your Company Address',
        fromEmail: companyInfo['email'] ?? 'contact@yourcompany.com',
        fromPhone: companyInfo['phone'] ?? '+1 (555) 123-4567',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
    ];

    for (final invoice in invoices) {
      await invoiceService.saveInvoice(invoice);
    }
  }

  static Future<void> clearAllData(InvoiceService invoiceService) async {
    // Clear all invoices
    final invoices = invoiceService.invoices;
    for (final invoice in invoices) {
      await invoiceService.deleteInvoice(invoice.id);
    }

    // Clear all clients
    final clients = invoiceService.clients;
    for (final client in clients) {
      await invoiceService.deleteClient(client.id);
    }
  }
}