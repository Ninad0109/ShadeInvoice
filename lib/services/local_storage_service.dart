import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billsnap/models/invoice_model.dart';
import 'package:billsnap/models/client_model.dart';

class LocalStorageService {
  static const String _invoicesKey = 'invoices';
  static const String _clientsKey = 'clients';
  static const String _companyInfoKey = 'company_info';

  static Future<List<Invoice>> loadInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final invoicesJson = prefs.getStringList(_invoicesKey) ?? [];
    return invoicesJson.map((json) => Invoice.fromJson(jsonDecode(json))).toList();
  }

  static Future<void> saveInvoices(List<Invoice> invoices) async {
    final prefs = await SharedPreferences.getInstance();
    final invoicesJson = invoices.map((invoice) => jsonEncode(invoice.toJson())).toList();
    await prefs.setStringList(_invoicesKey, invoicesJson);
  }

  static Future<void> saveInvoice(Invoice invoice) async {
    final invoices = await loadInvoices();
    final index = invoices.indexWhere((i) => i.id == invoice.id);
    if (index != -1) {
      invoices[index] = invoice;
    } else {
      invoices.add(invoice);
    }
    await saveInvoices(invoices);
  }

  static Future<void> deleteInvoice(String invoiceId) async {
    final invoices = await loadInvoices();
    invoices.removeWhere((invoice) => invoice.id == invoiceId);
    await saveInvoices(invoices);
  }

  static Future<List<Client>> loadClients() async {
    final prefs = await SharedPreferences.getInstance();
    final clientsJson = prefs.getStringList(_clientsKey) ?? [];
    return clientsJson.map((json) => Client.fromJson(jsonDecode(json))).toList();
  }

  static Future<void> saveClients(List<Client> clients) async {
    final prefs = await SharedPreferences.getInstance();
    final clientsJson = clients.map((client) => jsonEncode(client.toJson())).toList();
    await prefs.setStringList(_clientsKey, clientsJson);
  }

  static Future<void> saveClient(Client client) async {
    final clients = await loadClients();
    final index = clients.indexWhere((c) => c.id == client.id);
    if (index != -1) {
      clients[index] = client;
    } else {
      clients.add(client);
    }
    await saveClients(clients);
  }

  static Future<void> deleteClient(String clientId) async {
    final clients = await loadClients();
    clients.removeWhere((client) => client.id == clientId);
    await saveClients(clients);
  }

  static Future<Map<String, String>> loadCompanyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final companyInfoJson = prefs.getString(_companyInfoKey);
    if (companyInfoJson != null) {
      return Map<String, String>.from(jsonDecode(companyInfoJson));
    }
    return {
      'name': 'WanderHome Solutions',
      'address': '123 Business Ave\nSuite 100\nCity, State 12345',
      'email': 'contact@wanderhome.com',
      'phone': '+1 (555) 123-4567',
    };
  }

  static Future<void> saveCompanyInfo(Map<String, String> companyInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_companyInfoKey, jsonEncode(companyInfo));
  }
}