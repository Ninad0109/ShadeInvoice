import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:shadeinvoice/models/invoice_model.dart';

class ExportService {
  static String generateTextInvoice(Invoice invoice) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('INVOICE');
    buffer.writeln('Invoice #: ${invoice.invoiceNumber}');
    buffer.writeln('');
    
    // Company info
    buffer.writeln('From:');
    buffer.writeln(invoice.fromCompany);
    buffer.writeln(invoice.fromAddress);
    buffer.writeln(invoice.fromEmail);
    buffer.writeln(invoice.fromPhone);
    buffer.writeln('');
    
    // Client info
    buffer.writeln('To:');
    buffer.writeln(invoice.client.name);
    if (invoice.client.company.isNotEmpty) {
      buffer.writeln(invoice.client.company);
    }
    buffer.writeln(invoice.client.address);
    buffer.writeln(invoice.client.email);
    buffer.writeln(invoice.client.phone);
    buffer.writeln('');
    
    // Invoice details
    buffer.writeln('Invoice Date: ${dateFormat.format(invoice.invoiceDate)}');
    buffer.writeln('Due Date: ${dateFormat.format(invoice.dueDate)}');
    buffer.writeln('');
    
    // Items
    buffer.writeln('SERVICES:');
    buffer.writeln('Description\t\t\tQty\tRate\tAmount');
    buffer.writeln('${'-' * 60}');
    
    for (final item in invoice.items) {
      buffer.writeln('${item.description}\t\t\t${item.quantity}\t${currencyFormat.format(item.unitPrice)}\t${currencyFormat.format(item.totalPrice)}');
    }
    
    buffer.writeln('${'-' * 60}');
    buffer.writeln('TOTAL: ${currencyFormat.format(invoice.total)}');
    buffer.writeln('');
    
    // Payment method
    buffer.writeln('Payment Method: ${invoice.paymentMethod}');
    buffer.writeln('');
    
    // Notes
    if (invoice.notes.isNotEmpty) {
      buffer.writeln('Notes:');
      buffer.writeln(invoice.notes);
      buffer.writeln('');
    }
    
    // Footer
    buffer.writeln('This is a system-generated invoice.');
    
    return buffer.toString();
  }

  static Future<pw.Document> generatePdfInvoice(Invoice invoice) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('INVOICE', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Invoice #: ${invoice.invoiceNumber}'),
                    pw.Text('Date: ${dateFormat.format(invoice.invoiceDate)}'),
                    pw.Text('Due: ${dateFormat.format(invoice.dueDate)}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Company and client info
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('From:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(invoice.fromCompany),
                      pw.Text(invoice.fromAddress),
                      pw.Text(invoice.fromEmail),
                      pw.Text(invoice.fromPhone),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(invoice.client.name),
                      if (invoice.client.company.isNotEmpty) pw.Text(invoice.client.company),
                      pw.Text(invoice.client.address),
                      pw.Text(invoice.client.email),
                      pw.Text(invoice.client.phone),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Items table
            pw.Table.fromTextArray(
              headers: ['Description', 'Qty', 'Rate', 'Amount'],
              data: invoice.items.map((item) => [
                item.description,
                item.quantity.toString(),
                currencyFormat.format(item.unitPrice),
                currencyFormat.format(item.totalPrice),
              ]).toList(),
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 10),

            // Total
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('TOTAL: ${currencyFormat.format(invoice.total)}', 
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 20),

            // Payment method
            pw.Text('Payment Method: ${invoice.paymentMethod}'),
            pw.SizedBox(height: 10),

            // Notes
            if (invoice.notes.isNotEmpty) ...[
              pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(invoice.notes),
              pw.SizedBox(height: 10),
            ],

            // Footer
            pw.Spacer(),
            pw.Center(
              child: pw.Text('This is a system-generated invoice.',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ),
          ],
        ),
      ),
    );

    return pdf;
  }
}