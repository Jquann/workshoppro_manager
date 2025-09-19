import 'dart:typed_data';
import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/invoice.dart';

class InvoiceGmailService {
  static const String _gmailUsername = 'workshopmanagera@gmail.com';
  static const String _gmailAppPassword = 'yxdb xpgx otmt nlbk';

  static Future<void> sendInvoicePdf({
    required String recipientEmail,
    required String recipientName,
    required Invoice invoice,
    required Uint8List pdfBytes,
  }) async {
    // Configure SMTP server
    final smtpServer = gmail(_gmailUsername, _gmailAppPassword);

    // Create temporary file for attachment
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/Invoice_${invoice.invoiceId}.pdf');
    await tempFile.writeAsBytes(pdfBytes);

    // Create the email message
    final message = Message()
      ..from = Address(_gmailUsername, 'Workshop Pro Manager')
      ..recipients.add(recipientEmail)
      ..subject = 'Invoice ${invoice.invoiceId} - Workshop Pro Manager'
      ..html = _buildEmailBody(recipientName, invoice)
      ..attachments = [
        FileAttachment(tempFile)
          ..location = Location.inline
          ..cid = 'invoice_pdf',
      ];

    try {
      // Send the email
      final sendReport = await send(message, smtpServer);
      print('Email sent successfully: ${sendReport.toString()}');

      // Clean up temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      // Clean up temporary file even if email fails
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      print('Failed to send email: $e');
      rethrow;
    }
  }

  static String _buildEmailBody(String recipientName, Invoice invoice) {
    return '''
    <html lang="en">
      <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #2c5aa0;">Workshop Pro Manager</h2>
          
          <p>Dear $recipientName,</p>
          
          <p>Thank you for choosing our services. Please find your invoice attached to this email.</p>
          
          <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <h3 style="margin-top: 0; color: #2c5aa0;">Invoice Details:</h3>
            <p><strong>Invoice ID:</strong> ${invoice.invoiceId}</p>
            <p><strong>Vehicle:</strong> ${invoice.vehiclePlate}</p>
            <p><strong>Issue Date:</strong> ${invoice.issueDate.day}/${invoice.issueDate.month}/${invoice.issueDate.year}</p>
            <p><strong>Total Amount:</strong> RM ${invoice.grandTotal.toStringAsFixed(2)}</p>
            <p><strong>Status:</strong> ${invoice.status}</p>
            <p><strong>Payment Status:</strong> ${invoice.paymentStatus}</p>
          </div>
          
          <p>If you have any questions regarding this invoice, please don't hesitate to contact us.</p>
          
          <p>Best regards,<br>
          Workshop Pro Manager Team</p>
          
          <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
          <p style="font-size: 12px; color: #666;">
            This is an automated email. Please do not reply to this email address.
          </p>
        </div>
      </body>
    </html>
    ''';
  }
}
