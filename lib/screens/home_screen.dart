import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:billsnap/models/invoice_model.dart';
import 'package:billsnap/services/invoice_service.dart';
import 'package:billsnap/screens/create_invoice_screen.dart';
import 'package:billsnap/screens/invoice_preview_screen.dart';
import 'package:billsnap/screens/client_management_screen.dart';
import 'package:billsnap/screens/settings_screen.dart';
import 'package:billsnap/widgets/invoice_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceService>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const DashboardTab(),
      const ClientManagementScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Clients',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CreateInvoiceScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New Invoice'),
            )
          : null,
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BillSnap"),
        centerTitle: true,
      ),
      body: Consumer<InvoiceService>(
        builder: (context, invoiceService, child) {
          final recentInvoices = invoiceService.getRecentInvoices();
          final draftInvoices =
              invoiceService.getInvoicesByStatus(InvoiceStatus.draft);
          final paidInvoices =
              invoiceService.getInvoicesByStatus(InvoiceStatus.paid);
          final overdueInvoices =
              invoiceService.getInvoicesByStatus(InvoiceStatus.overdue);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics Cards
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildStatCard(
                        'Total Invoices',
                        '${invoiceService.invoices.length}',
                        Icons.receipt_long,
                        context),
                    _buildStatCard('Draft', '${draftInvoices.length}',
                        Icons.edit_document, context),
                    _buildStatCard('Paid', '${paidInvoices.length}',
                        Icons.check_circle, context),
                    _buildStatCard('Overdue', '${overdueInvoices.length}',
                        Icons.warning, context),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Invoices
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Invoices',
                        style: Theme.of(context).textTheme.headlineSmall),
                    if (recentInvoices.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          // Navigate to all invoices view
                        },
                        child: const Text('View All'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                if (recentInvoices.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('No invoices yet',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text('Create your first invoice to get started',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentInvoices.length,
                    itemBuilder: (context, index) {
                      final invoice = recentInvoices[index];
                      return InvoiceCard(
                        invoice: invoice,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                InvoicePreviewScreen(invoice: invoice),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme
                .of(context)
                .colorScheme
                .primary),
            const SizedBox(height: 8),
            FittedBox( // Wrap the value Text
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme
                    .of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox( // Wrap the title Text
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: Theme
                    .of(context)
                    .textTheme
                    .bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
  }

