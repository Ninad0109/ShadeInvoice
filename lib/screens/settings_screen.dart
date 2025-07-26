import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:billsnap/services/invoice_service.dart';
import 'package:billsnap/services/sample_data_service.dart';
import 'package:billsnap/models/invoice_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _companyPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCompanyInfo();
  }

  void _loadCompanyInfo() {
    final companyInfo = context.read<InvoiceService>().companyInfo;
    _companyNameController.text = companyInfo['name'] ?? '';
    _companyAddressController.text = companyInfo['address'] ?? '';
    _companyEmailController.text = companyInfo['email'] ?? '';
    _companyPhoneController.text = companyInfo['phone'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Consumer<InvoiceService>(
        builder: (context, invoiceService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Company Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _companyNameController,
                            decoration: const InputDecoration(
                              labelText: 'Company Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.business),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Please enter company name' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _companyAddressController,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            maxLines: 3,
                            validator: (value) => value?.isEmpty ?? true ? 'Please enter address' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _companyEmailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) => value?.isEmpty ?? true ? 'Please enter email' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _companyPhoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) => value?.isEmpty ?? true ? 'Please enter phone number' : null,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _saveCompanyInfo,
                              icon: const Icon(Icons.save),
                              label: const Text('Save Company Info'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Statistics
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistics',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow('Total Invoices', '${invoiceService.invoices.length}', Icons.receipt_long),
                        _buildStatRow('Total Clients', '${invoiceService.clients.length}', Icons.people),
                        _buildStatRow('Draft Invoices', '${invoiceService.getInvoicesByStatus(InvoiceStatus.draft).length}', Icons.edit_document),
                        _buildStatRow('Paid Invoices', '${invoiceService.getInvoicesByStatus(InvoiceStatus.paid).length}', Icons.check_circle),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // App Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.info),
                          title: const Text('Version'),
                          subtitle: const Text('1.0.0'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        ListTile(
                          leading: const Icon(Icons.description),
                          title: const Text('About'),
                          subtitle: const Text('WanderHome Invoice Generator - Create professional invoices with ease'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Data Management
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Management',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showAddSampleDataDialog,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Add Sample Data'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showClearDataDialog,
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear All Data'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _saveCompanyInfo() {
    if (_formKey.currentState!.validate()) {
      final companyInfo = {
        'name': _companyNameController.text.trim(),
        'address': _companyAddressController.text.trim(),
        'email': _companyEmailController.text.trim(),
        'phone': _companyPhoneController.text.trim(),
      };

      context.read<InvoiceService>().saveCompanyInfo(companyInfo);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company information saved')),
      );
    }
  }

  void _showAddSampleDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Sample Data'),
        content: const Text('This will add sample invoices and clients to help you get started. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addSampleData();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will permanently delete all invoices and clients. This action cannot be undone. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData();
            },
            child: const Text('Clear'),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );
  }

  void _addSampleData() async {
    await SampleDataService.addSampleData(context.read<InvoiceService>());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sample data added successfully')),
    );
  }

  void _clearAllData() async {
    await SampleDataService.clearAllData(context.read<InvoiceService>());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data cleared successfully')),
    );
  }
}