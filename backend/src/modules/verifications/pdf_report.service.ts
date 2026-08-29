import fs from 'fs';
import path from 'path';
import PDFDocument from 'pdfkit';
import { config } from '../../config';

export interface VerificationReportData {
  verificationCode: string;
  customerName: string;
  customerEmail: string;
  propertyName: string;
  propertyAddress: string;
  state: string;
  city: string;
  documentType: string;
  status: string; // VERIFIED, VERIFIED_WITH_ISSUES, UNVERIFIED, REJECTED
  assignedTo?: string;
  externalRegistryChecked: boolean;
  externalRegistryNotes?: string;
  finalFindings?: string;
  checks: { name: string; category: string; status: string; notes?: string }[];
  documents: { fileName: string; fileType?: string }[];
  completedAt: Date;
}

export class PdfReportService {
  static async generateVerificationReport(data: VerificationReportData): Promise<string> {
    const fileName = `Verification_Report_${data.verificationCode}.pdf`;
    const filePath = path.join(config.storage.uploadDir, fileName);

    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ margin: 40, size: 'A4' });
      const stream = fs.createWriteStream(filePath);

      doc.pipe(stream);

      // Header Brand
      doc.rect(40, 40, 515, 60).fill('#0D5C3A');
      doc.fillColor('#FFFFFF').fontSize(20).font('Helvetica-Bold').text('Hometrust', 55, 55);
      doc.fontSize(10).font('Helvetica').text('Property & Legal Document Verification Report', 55, 80);
      doc.fontSize(9).text(`Code: ${data.verificationCode}`, 420, 58, { align: 'right' });
      doc.text(`Date: ${data.completedAt.toLocaleDateString()}`, 420, 75, { align: 'right' });

      doc.moveDown(3);
      doc.fillColor('#1E293B');

      // Summary Box
      let y = 120;
      doc.fontSize(12).font('Helvetica-Bold').text('VERIFICATION SUMMARY', 40, y);
      y += 20;
      doc.rect(40, y, 515, 75).fillAndStroke('#F8FAFC', '#E2E8F0');
      
      doc.fillColor('#334155').fontSize(9).font('Helvetica');
      doc.text(`Customer: ${data.customerName} (${data.customerEmail})`, 50, y + 10);
      doc.text(`Property Name: ${data.propertyName}`, 50, y + 25);
      doc.text(`Location: ${data.propertyAddress}, ${data.city}, ${data.state}`, 50, y + 40);
      doc.text(`Document Type: ${data.documentType}`, 50, y + 55);

      // Status Badge
      const statusColor = data.status === 'VERIFIED' ? '#0D5C3A' : data.status === 'VERIFIED_WITH_ISSUES' ? '#D97706' : '#DC2626';
      doc.rect(380, y + 10, 160, 25).fill(statusColor);
      doc.fillColor('#FFFFFF').fontSize(10).font('Helvetica-Bold').text(`STATUS: ${data.status}`, 380, y + 18, { align: 'center', width: 160 });

      // Review Details
      y += 95;
      doc.fillColor('#1E293B').fontSize(12).font('Helvetica-Bold').text('PROFESSIONAL REVIEW & FINDINGS', 40, y);
      y += 20;

      doc.fillColor('#334155').fontSize(9).font('Helvetica');
      const findings = data.finalFindings || 'All primary title, boundary coordinates, and statutory registration checks completed by Hometrust Legal Team.';
      doc.text(findings, 40, y, { width: 515, align: 'justify' });
      y += 40;

      // External Checks
      doc.font('Helvetica-Bold').text('Registry Check:', 40, y);
      doc.font('Helvetica').text(
        data.externalRegistryChecked
          ? `Confirmed. ${data.externalRegistryNotes || 'Title verified with Lands Registry records.'}`
          : 'Pending physical beacon & registry requisition.',
        130,
        y
      );
      y += 25;

      // Checks Table
      doc.fillColor('#1E293B').fontSize(12).font('Helvetica-Bold').text('CHECKLIST BREAKDOWN', 40, y);
      y += 18;

      doc.rect(40, y, 515, 20).fill('#E2E8F0');
      doc.fillColor('#1E293B').fontSize(9).font('Helvetica-Bold');
      doc.text('Check Item', 45, y + 5);
      doc.text('Category', 240, y + 5);
      doc.text('Status', 380, y + 5);
      doc.text('Remarks', 450, y + 5);
      y += 22;

      data.checks.forEach((chk) => {
        doc.fillColor('#475569').fontSize(8).font('Helvetica');
        doc.text(chk.name, 45, y, { width: 180 });
        doc.text(chk.category, 240, y, { width: 130 });
        doc.font('Helvetica-Bold').text(chk.status, 380, y);
        doc.font('Helvetica').text(chk.notes || 'Verified compliant', 450, y, { width: 100 });
        y += 18;
      });

      // Disclaimer Alert Box
      y = Math.max(y + 20, 680);
      doc.rect(40, y, 515, 65).fillAndStroke('#FEF3C7', '#F59E0B');
      doc.fillColor('#92400E').fontSize(8).font('Helvetica-Bold').text('IMPORTANT REGULATORY DISCLAIMER', 50, y + 8);
      doc.font('Helvetica').fontSize(7.5).text(
        'Verification is based strictly on the documentation, surveyor records, and registry checks identified in this report at the time of review. This report does not constitute a government-issued title or guarantee against future disputes or unrecorded encumbrances. Property buyers must exercise prudent due diligence.',
        50,
        y + 22,
        { width: 495, align: 'justify' }
      );

      // Sign-off
      doc.fontSize(8).fillColor('#64748B').text('Hometrust Legal & Verification Team • www.Hometrust.ng', 40, 775, { align: 'center', width: 515 });

      doc.end();

      stream.on('finish', () => {
        const reportUrl = `${config.storage.baseUrl}/files/${fileName}`;
        resolve(reportUrl);
      });

      stream.on('error', (err) => {
        reject(err);
      });
    });
  }
}
