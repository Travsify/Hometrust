import fs from 'fs';
import path from 'path';
import PDFDocument from 'pdfkit';
import { config } from '../../config';

export class BankingPdfService {
  static async generateStatementPdf(data: {
    userName: string;
    email: string;
    accountNumber: string;
    bankName: string;
    balance: number;
    transactions: any[];
    filterType?: string;
  }): Promise<{ filePath: string; fileName: string }> {
    const filterSuffix = data.filterType && data.filterType !== 'ALL' ? `_${data.filterType}` : '';
    const fileName = `Hometrust_Statement${filterSuffix}_${Date.now()}.pdf`;
    const uploadDir = config.storage?.uploadDir || path.join(process.cwd(), 'uploads');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    const filePath = path.join(uploadDir, fileName);

    let subtitle = 'ESCROW & PROPERTY STATEMENT OF ACCOUNT';
    if (data.filterType === 'CREDIT' || data.filterType === 'INFLOW') {
      subtitle = 'ESCROW STATEMENT: INFLOW & DEPOSIT TRANSACTIONS';
    } else if (data.filterType === 'DEBIT' || data.filterType === 'OUTFLOW') {
      subtitle = 'ESCROW STATEMENT: OUTFLOW & WITHDRAWAL TRANSACTIONS';
    }

    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ margin: 40, size: 'A4' });
      const stream = fs.createWriteStream(filePath);
      doc.pipe(stream);

      // Header Banner
      doc.rect(40, 40, 515, 65).fill('#059669');
      doc.fillColor('#FFFFFF').fontSize(22).font('Helvetica-Bold').text('HOMETRUST', 55, 52);
      doc.fontSize(8.5).font('Helvetica').text(subtitle, 55, 78);
      doc.fontSize(8.5).font('Helvetica').text(`Generated: ${new Date().toLocaleString()}`, 380, 55, { align: 'right' });
      doc.text('Security: Bank-Grade NDPR Verified', 380, 72, { align: 'right' });

      // User & Account Overview Box
      let y = 120;
      doc.rect(40, y, 515, 75).fillAndStroke('#F8FAFC', '#E2E8F0');
      doc.fillColor('#0F172A').fontSize(10).font('Helvetica-Bold').text('ACCOUNT SUMMARY', 52, y + 10);
      
      doc.fillColor('#334155').fontSize(9).font('Helvetica');
      doc.text(`Account Holder: ${data.userName}`, 52, y + 26);
      doc.text(`Email: ${data.email}`, 52, y + 40);
      doc.text(`Dedicated Bank: ${data.bankName}`, 52, y + 54);

      doc.text(`NUBAN Account: ${data.accountNumber}`, 320, y + 26);
      doc.text(`Currency: Nigerian Naira (NGN)`, 320, y + 40);
      doc.font('Helvetica-Bold').fillColor('#059669');
      doc.text(`Available Balance: NGN ${data.balance.toLocaleString('en-NG', { minimumFractionDigits: 2 })}`, 320, y + 54);

      // Transactions Ledger Table Header
      y += 95;
      doc.fillColor('#0F172A').fontSize(11).font('Helvetica-Bold').text('TRANSACTION LEDGER', 40, y);
      y += 18;

      doc.rect(40, y, 515, 22).fill('#0F172A');
      doc.fillColor('#FFFFFF').fontSize(8.5).font('Helvetica-Bold');
      doc.text('Date', 48, y + 6);
      doc.text('Description / Reference', 120, y + 6);
      doc.text('Type', 340, y + 6);
      doc.text('Amount (NGN)', 410, y + 6);
      doc.text('Status', 485, y + 6);
      y += 22;

      // Table Rows
      doc.font('Helvetica').fontSize(8);
      let isEven = false;
      for (const tx of data.transactions.slice(0, 30)) {
        if (y > 720) {
          doc.addPage();
          y = 40;
        }

        doc.rect(40, y, 515, 20).fill(isEven ? '#F8FAFC' : '#FFFFFF');
        isEven = !isEven;

        const dateStr = tx.createdAt ? new Date(tx.createdAt).toLocaleDateString() : 'N/A';
        const isCredit = tx.type === 'CREDIT';
        const amountStr = `${isCredit ? '+' : '-'}NGN ${Number(tx.amount || 0).toLocaleString('en-NG', { minimumFractionDigits: 2 })}`;

        doc.fillColor('#475569').text(dateStr, 48, y + 5);
        doc.fillColor('#0F172A').text((tx.description || tx.reference || 'Escrow Activity').substring(0, 38), 120, y + 5);
        
        doc.fillColor(isCredit ? '#059669' : '#DC2626').font('Helvetica-Bold').text(tx.type || 'TX', 340, y + 5);
        doc.text(amountStr, 410, y + 5);
        doc.font('Helvetica').fillColor('#059669').text(tx.status || 'SUCCESS', 485, y + 5);

        y += 20;
      }

      // Footer Stamp
      y = Math.max(y + 20, 720);
      doc.rect(40, y, 515, 45).fillAndStroke('#ECFDF5', '#6EE7B7');
      doc.fillColor('#065F46').fontSize(8).font('Helvetica');
      doc.text('Official Hometrust Verification Seal: This statement is an authentic record of CBN-regulated escrow transactions in Nigerian Naira (NGN).', 50, y + 10);
      doc.text('Questions or dispute inquiries? Email: finance@hometrustng.com | Web: https://hometrustng.com', 50, y + 25);

      doc.end();
      stream.on('finish', () => resolve({ filePath, fileName }));
      stream.on('error', reject);
    });
  }

  static async generateReceiptPdf(data: {
    userName: string;
    email: string;
    txId: string;
    reference: string;
    type: string;
    amount: number;
    purpose: string;
    status: string;
    channel?: string;
    createdAt: Date | string;
    bankName?: string;
    accountNumber?: string;
  }): Promise<{ filePath: string; fileName: string }> {
    const fileName = `Receipt_${data.reference}.pdf`;
    const uploadDir = config.storage?.uploadDir || path.join(process.cwd(), 'uploads');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    const filePath = path.join(uploadDir, fileName);

    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ margin: 40, size: 'A4' });
      const stream = fs.createWriteStream(filePath);
      doc.pipe(stream);

      // Header Banner
      doc.rect(40, 40, 515, 65).fill('#059669');
      doc.fillColor('#FFFFFF').fontSize(22).font('Helvetica-Bold').text('HOMETRUST', 55, 52);
      doc.fontSize(9).font('Helvetica').text('OFFICIAL ESCROW PAYMENT RECEIPT', 55, 78);
      doc.fontSize(8.5).font('Helvetica').text(`Receipt No: ${data.reference}`, 360, 55, { align: 'right' });
      doc.text(`Issued: ${new Date(data.createdAt).toLocaleString()}`, 360, 72, { align: 'right' });

      // Receipt Box
      let y = 130;
      doc.rect(40, y, 515, 340).fillAndStroke('#FFFFFF', '#E2E8F0');

      // Amount Banner inside receipt
      doc.rect(60, y + 20, 475, 55).fill('#ECFDF5');
      doc.fillColor('#065F46').fontSize(10).font('Helvetica-Bold').text('TOTAL TRANSACTION AMOUNT (NGN)', 75, y + 30);
      doc.fontSize(18).fillColor('#059669').text(`NGN ${Number(data.amount).toLocaleString('en-NG', { minimumFractionDigits: 2 })}`, 75, y + 46);

      // Detail Rows
      let rowY = y + 95;
      const details = [
        { label: 'Transaction Status', value: 'SUCCESSFUL & VERIFIED', isGreen: true },
        { label: 'Currency / Denomination', value: 'Nigerian Naira (NGN)' },
        { label: 'Transaction Reference', value: data.reference },
        { label: 'Payment Type / Purpose', value: data.purpose || data.type },
        { label: 'Account Holder / Customer', value: `${data.userName} (${data.email})` },
        { label: 'Payment Channel', value: data.channel || 'Direct NUBAN Bank Transfer' },
        { label: 'Settlement Date', value: new Date(data.createdAt).toUTCString() },
        { label: 'Escrow Security Status', value: 'Guaranteed by CBN Licensed Partner Bank' },
      ];

      for (const d of details) {
        doc.fillColor('#64748B').fontSize(9).font('Helvetica').text(d.label, 75, rowY);
        doc.fillColor(d.isGreen ? '#059669' : '#0F172A').font('Helvetica-Bold').text(d.value, 260, rowY);
        doc.moveTo(75, rowY + 16).lineTo(515, rowY + 16).strokeColor('#F1F5F9').stroke();
        rowY += 28;
      }

      // Security Seal & Verification Note
      y = 500;
      doc.rect(40, y, 515, 60).fillAndStroke('#F8FAFC', '#CBD5E1');
      doc.fillColor('#0F172A').fontSize(8.5).font('Helvetica-Bold').text('AUTHENTICITY & ESCROW WARRANTY', 55, y + 12);
      doc.fillColor('#475569').fontSize(8).font('Helvetica').text('This document serves as an electronic legal confirmation of funds processed through Hometrust escrow services in Nigerian Naira (NGN). Retain this receipt for tax, audit, and property allocation records.', 55, y + 26);
      doc.text('Direct verification: https://hometrustng.com/receipts/verify | Support: finance@hometrustng.com', 55, y + 42);

      doc.end();
      stream.on('finish', () => resolve({ filePath, fileName }));
      stream.on('error', reject);
    });
  }
}
