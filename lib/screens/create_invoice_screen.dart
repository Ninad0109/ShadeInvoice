import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shadeinvoice/models/invoice_model.dart';
import 'package:shadeinvoice/models/client_model.dart';
import 'package:shadeinvoice/models/invoice_item_model.dart';
import 'package:shadeinvoice/services/invoice_service.dart';
import 'package:shadeinvoice/screens/invoice_preview_screen.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientAddressController = TextEditingController();
  final _clientCompanyController = TextEditingController();
  final _notesController = TextEditingController();
  final _paymentMethodController = TextEditingController(text: 'Bank Transfer');
  
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  final List<InvoiceItem> _items = [];
  Client? _selectedClient;

  @override
  void initState() {
    super.initState();
    _addInitialItem();
  }

  void _addInitialItem() {
    _items.add(InvoiceItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: '',
      quantity: 1,
      unitPrice: 0,
    ));
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: '',
        quantity: 1,
        unitPrice: 0,
      ));
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

  void _updateItem(int index, InvoiceItem item) {
    setState(() {
      _items[index] = item;
    });
  }

  void _selectClient(Client client) {
    setState(() {
      _selectedClient = client;
      _clientNameController.text = client.name;
      _clientEmailController.text = client.email;
      _clientPhoneController.text = client.phone;
      _clientAddressController.text = client.address;
      _clientCompanyController.text = client.company;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isInvoiceDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isInvoiceDate ? _invoiceDate : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isInvoiceDate) {
          _invoiceDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _createInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    final invoiceService = context.read<InvoiceService>();
    final companyInfo = invoiceService.companyInfo;

    final client = Client(
      id: _selectedClient?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _clientNameController.text.trim(),
      email: _clientEmailController.text.trim(),
      phone: _clientPhoneController.text.trim(),
      address: _clientAddressController.text.trim(),
      company: _clientCompanyController.text.trim(),
      createdAt: _selectedClient?.createdAt ?? DateTime.now(),
    );

    // Save new client if it's not an existing one
    if (_selectedClient == null) {
      await invoiceService.saveClient(client);
    }

    final validItems = _items.where((item) => item.description.isNotEmpty).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    final invoice = Invoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      invoiceNumber: invoiceService.generateInvoiceNumber(),
      invoiceDate: _invoiceDate,
      dueDate: _dueDate,
      client: client,
      items: validItems,
      notes: _notesController.text.trim(),
      paymentMethod: _paymentMethodController.text.trim(),
      status: InvoiceStatus.draft,
      fromCompany: companyInfo['name'] ?? 'Your Company Name',
      fromAddress: companyInfo['address'] ?? 'Your Company Address',
      fromEmail: companyInfo['email'] ?? 'contact@yourcompany.com',
      fromPhone: companyInfo['phone'] ?? '+1 (555) 123-4567',
      createdAt: DateTime.now(),
    );

    await invoiceService.saveInvoice(invoice);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InvoicePreviewScreen(invoice: invoice),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        actions: [
          TextButton(
            onPressed: _createInvoice,
            child: const Text('Create'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Client Information', style: Theme.of(context).textTheme.titleLarge),
                          TextButton.icon(
                            onPressed: () => _showClientSelector(context),
                            icon: const Icon(Icons.person_search),
                            label: const Text('Select Client'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _clientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Client Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Please enter client name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _clientCompanyController,
                        decoration: const InputDecoration(
                          labelText: 'Company (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _clientEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value?.isEmpty ?? true ? 'Please enter email' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _clientPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) => value?.isEmpty ?? true ? 'Please enter phone' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _clientAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) => value?.isEmpty ?? true ? 'Please enter address' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Invoice Details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invoice Details', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Invoice Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(DateFormat('MMM dd, yyyy').format(_invoiceDate)),
                                    const Icon(Icons.calendar_today),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, false),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Due Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(DateFormat('MMM dd, yyyy').format(_dueDate)),
                                    const Icon(Icons.calendar_today),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _paymentMethodController,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Please enter payment method' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Items
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Items', style: Theme.of(context).textTheme.titleLarge),
                          TextButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Item'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(_items.length, (index) => _buildItemRow(index)),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total: ${NumberFormat.currency(symbol: '\$').format(_calculateTotal())}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notes', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Additional Notes (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final item = _items[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                initialValue: item.description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _updateItem(index, item.copyWith(description: value));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: item.quantity.toString(),
                decoration: const InputDecoration(
                  labelText: 'Qty',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final qty = double.tryParse(value) ?? 0;
                  _updateItem(index, item.copyWith(quantity: qty));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: item.unitPrice.toString(),
                decoration: const InputDecoration(
                  labelText: 'Rate',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value) ?? 0;
                  _updateItem(index, item.copyWith(unitPrice: price));
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _removeItem(index),
              icon: const Icon(Icons.delete),
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotal() => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  void _showClientSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer<InvoiceService>(
        builder: (context, invoiceService, child) {
          final clients = invoiceService.clients;
          return Container(
            height: 400,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Select Client', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                Expanded(
                  child: clients.isEmpty
                      ? const Center(child: Text('No clients found'))
                      : ListView.builder(
                          itemCount: clients.length,
                          itemBuilder: (context, index) {
                            final client = clients[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(client.name.isNotEmpty ? client.name[0].toUpperCase() : '?'),
                              ),
                              title: Text(client.name),
                              subtitle: Text(client.email),
                              onTap: () {
                                _selectClient(client);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}