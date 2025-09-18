// To view the saved PDF in Android Studio:
// 1. Go to View > Tool Windows > Device File Explorer
// 2. Navigate to data > data > my.edu.tarumt.workshoppro_manager > app_flutter
// 3. Right-click the PDF file and choose "Save As..." to download or double click to open it

import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../models/invoice.dart';
import '../../models/service_model.dart';

class InvoicePdfService {
  static final _currency = NumberFormat.currency(
    locale: 'ms_MY',
    symbol: 'RM',
    decimalDigits: 2,
  );

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  static Future<Uint8List> generateInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(invoice),
          pw.SizedBox(height: 30),
          _buildInvoiceInfo(invoice),
          pw.SizedBox(height: 30),
          _buildCustomerInfo(invoice),
          pw.SizedBox(height: 30),
          if (invoice.parts.isNotEmpty) ...[
            _buildPartsTable(invoice.parts),
            pw.SizedBox(height: 20),
          ],
          if (invoice.labor.isNotEmpty) ...[
            _buildLaborTable(invoice.labor),
            pw.SizedBox(height: 20),
          ],
          _buildTotalSection(invoice),
          pw.SizedBox(height: 30),
          if (invoice.notes.isNotEmpty) _buildNotes(invoice.notes),
          pw.Spacer(),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'WORKSHOP PRO MANAGER',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Workshop Management System',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Status: ${invoice.status.toUpperCase()}',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _getStatusColor(invoice.status),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceInfo(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Invoice Number',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                invoice.invoiceId,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Issue Date',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                _dateFormat.format(invoice.issueDate),
                style: pw.TextStyle(fontSize: 14),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Job ID',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(invoice.jobId, style: pw.TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCustomerInfo(Invoice invoice) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Bill To:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                invoice.customerName,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Vehicle: ${invoice.vehiclePlate}',
                style: pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Service Details:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Mechanic: ${invoice.assignedMechanicId}',
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Created By: ${invoice.createdBy}',
                style: pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPartsTable(List<PartLine> parts) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Parts & Components',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue700,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableHeader('Description'),
                _buildTableHeader('Qty'),
                _buildTableHeader('Unit Price'),
                _buildTableHeader('Total'),
              ],
            ),
            // Parts rows
            ...parts.map(
              (part) => pw.TableRow(
                children: [
                  _buildTableCell(part.name),
                  _buildTableCell(
                    part.quantity.toString(),
                    align: pw.Alignment.center,
                  ),
                  _buildTableCell(
                    _currency.format(part.unitPrice),
                    align: pw.Alignment.centerRight,
                  ),
                  _buildTableCell(
                    _currency.format(part.unitPrice * part.quantity),
                    align: pw.Alignment.centerRight,
                  ),
                ],
              ),
            ),
            // Parts subtotal
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Parts Subtotal', bold: true),
                _buildTableCell(''),
                _buildTableCell(''),
                _buildTableCell(
                  _currency.format(
                    parts.fold<double>(
                      0,
                      (sum, part) => sum + (part.unitPrice * part.quantity),
                    ),
                  ),
                  align: pw.Alignment.centerRight,
                  bold: true,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildLaborTable(List<LaborLine> labor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Labor & Services',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue700,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableHeader('Description'),
                _buildTableHeader('Hours'),
                _buildTableHeader('Rate/Hr'),
                _buildTableHeader('Total'),
              ],
            ),
            // Labor rows
            ...labor.map(
              (laborItem) => pw.TableRow(
                children: [
                  _buildTableCell(laborItem.name),
                  _buildTableCell(
                    laborItem.hours.toStringAsFixed(1),
                    align: pw.Alignment.center,
                  ),
                  _buildTableCell(
                    _currency.format(laborItem.rate),
                    align: pw.Alignment.centerRight,
                  ),
                  _buildTableCell(
                    _currency.format(laborItem.hours * laborItem.rate),
                    align: pw.Alignment.centerRight,
                  ),
                ],
              ),
            ),
            // Labor subtotal
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Labor Subtotal', bold: true),
                _buildTableCell(''),
                _buildTableCell(''),
                _buildTableCell(
                  _currency.format(
                    labor.fold<double>(
                      0,
                      (sum, laborItem) =>
                          sum + (laborItem.hours * laborItem.rate),
                    ),
                  ),
                  align: pw.Alignment.centerRight,
                  bold: true,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTotalSection(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Subtotal:', style: pw.TextStyle(fontSize: 12)),
              pw.Text(
                _currency.format(invoice.subtotal),
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Tax (6%):', style: pw.TextStyle(fontSize: 12)),
              pw.Text(
                _currency.format(invoice.tax),
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.Divider(color: PdfColors.blue300, thickness: 1),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TOTAL AMOUNT:',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
              pw.Text(
                _currency.format(invoice.grandTotal),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildNotes(String notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Additional Notes:',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue700,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Text(notes, style: pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.Text(
          'This is a computer-generated invoice and does not require a signature.',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Generated on ${_dateFormat.format(DateTime.now())} by Workshop Pro Manager',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    pw.Alignment? align,
    bool bold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align == pw.Alignment.centerRight
            ? pw.TextAlign.right
            : align == pw.Alignment.center
            ? pw.TextAlign.center
            : pw.TextAlign.left,
      ),
    );
  }

  static PdfColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return PdfColors.blue700;
      case 'pending':
        return PdfColors.orange;
      case 'rejected':
        return PdfColors.red;
      default:
        return PdfColors.grey600;
    }
  }

  static Future<String> saveInvoicePdf(
    Invoice invoice,
    Uint8List pdfBytes,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = '${invoice.invoiceId}_$timestamp.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }

  static Future<void> shareInvoicePdf(Invoice invoice) async {
    try {
      final pdfBytes = await generateInvoicePdf(invoice);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = '${invoice.invoiceId}_$timestamp.pdf';

      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } catch (e) {
      throw Exception('Failed to share PDF: $e');
    }
  }
}
