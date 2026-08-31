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
  private static getLogoPath(): string | null {
    const candidates = [
      path.join(process.cwd(), 'public', 'logo.png'),
      path.join(process.cwd(), 'public', 'assets', 'logo.png'),
      path.join(__dirname, '..', '..', '..', 'public', 'logo.png'),
      path.join(__dirname, '..', '..', '..', 'public', 'assets', 'logo.png'),
    ];
    for (const c of candidates) {
      if (fs.existsSync(c)) return c;
    }
    return null;
  }

  static async generateVerificationReport(data: VerificationReportData): Promise<string> {
    const fileName = `Verification_Report_${data.verificationCode}.pdf`;
    const uploadDir = config.storage?.uploadDir || path.join(process.cwd(), 'uploads');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    const filePath = path.join(uploadDir, fileName);

    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ margin: 40, size: 'A4' });
      const stream = fs.createWriteStream(filePath);

      doc.pipe(stream);

      // Header Banner with Bold Logo
      doc.rect(40, 40, 515, 75).fill('#059669');

      const logoPath = PdfReportService.getLogoPath();
      let textStartX = 55;
      if (logoPath) {
        try {
          doc.image(logoPath, 50, 48, { width: 58, height: 58 });
          textStartX = 118;
        } catch (_) {}
      }

      doc.fillColor('#FFFFFF').fontSize(22).font('Helvetica-Bold').text('HOMETRUST', textStartX, 50);
      doc.fontSize(8.5).font('Helvetica').fillColor('#D1FAE5').text('Ehomes Global Inclusive Limited', textStartX, 72);
      doc.fontSize(8).font('Helvetica-Bold').fillColor('#FEF08A').text('OFFICIAL PROPERTY & TITLE VERIFICATION REPORT', textStartX, 86);

      const exactTimeStr = new Date(data.completedAt).toLocaleString('en-GB', {
        timeZone: 'Africa/Lagos',
        day: '2-digit',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        hour12: true,
      });

      doc.fontSize(8.5).font('Helvetica').fillColor('#FFFFFF').text(`Code: ${data.verificationCode}`, 340, 52, { align: 'right' });
      doc.text(`Completed: ${exactTimeStr} (WAT)`, 340, 68, { align: 'right' });
      doc.fontSize(7.5).fillColor('#D1FAE5').text('Cadastral & Title Registry Verified', 340, 84, { align: 'right' });

      // Summary Box
      let y = 125;
      doc.fontSize(10).font('Helvetica-Bold').fillColor('#0F172A').text('PROPERTY VERIFICATION SUMMARY', 40, y);
      y += 18;
      doc.rect(40, y, 515, 75).fillAndStroke('#F8FAFC', '#E2E8F0');
      
      doc.fillColor('#334155').fontSize(9).font('Helvetica');
      doc.text(`Applicant: ${data.customerName}`, 50, y + 10);
      doc.text(`Property / Plot: ${data.propertyName}`, 50, y + 25);
      doc.text(`Location: ${data.propertyAddress}, ${data.city}, ${data.state}`, 50, y + 40);
      doc.text(`Document Type: ${data.documentType.replace(/_/g, ' ')}`, 50, y + 55);

      // Status Badge
      const statusColor = data.status === 'VERIFIED' ? '#059669' : data.status === 'VERIFIED_WITH_ISSUES' ? '#D97706' : '#DC2626';
      doc.rect(370, y + 12, 170, 26).fill(statusColor);
      doc.fillColor('#FFFFFF').fontSize(9.5).font('Helvetica-Bold').text(`STATUS: ${data.status.replace(/_/g, ' ')}`, 370, y + 20, { align: 'center', width: 170 });

      // Review Findings
      y += 95;
      doc.fillColor('#0F172A').fontSize(10).font('Helvetica-Bold').text('LEGAL & CADASTRAL FINDINGS', 40, y);
      y += 16;

      doc.fillColor('#334155').fontSize(8.5).font('Helvetica');
      const findings = data.finalFindings || 'All primary title, boundary coordinates, and statutory registration checks completed by Hometrust Legal & Surveyor Team.';
      doc.text(findings, 40, y, { width: 515, align: 'justify' });
      y += 35;

      // External Checks
      doc.font('Helvetica-Bold').fillColor('#0F172A').text('Land Registry Verification:', 40, y);
      doc.font('Helvetica').fillColor('#334155').text(
        data.externalRegistryChecked
          ? `Confirmed. ${data.externalRegistryNotes || 'Title verified with Lands Registry records.'}`
          : 'Pending physical beacon & registry requisition.',
        180,
        y
      );
      y += 24;

      // Checks Table
      doc.fillColor('#0F172A').fontSize(10).font('Helvetica-Bold').text('AUDIT CHECKLIST BREAKDOWN', 40, y);
      y += 16;

      doc.rect(40, y, 515, 20).fill('#0F172A');
      doc.fillColor('#FFFFFF').fontSize(8.5).font('Helvetica-Bold');
      doc.text('Check Item', 48, y + 5);
      doc.text('Category', 240, y + 5);
      doc.text('Status', 380, y + 5);
      doc.text('Remarks', 440, y + 5);
      y += 20;

      data.checks.forEach((chk) => {
        if (y > 720) {
          doc.addPage();
          y = 40;
        }
        doc.fillColor('#475569').fontSize(8).font('Helvetica');
        doc.text(chk.name, 48, y + 4, { width: 185 });
        doc.text(chk.category, 240, y + 4, { width: 130 });
        doc.fillColor(chk.status === 'PASSED' ? '#059669' : '#DC2626').font('Helvetica-Bold').text(chk.status, 380, y + 4);
        doc.fillColor('#64748B').font('Helvetica').text(chk.notes || '-', 440, y + 4, { width: 110 });
        y += 18;
      });

      // Footer Seal
      y = Math.max(y + 20, 715);
      doc.rect(40, y, 515, 50).fillAndStroke('#ECFDF5', '#6EE7B7');
      doc.fillColor('#065F46').fontSize(7.5).font('Helvetica');
      doc.text('Official Hometrust Verification Seal: This report is an authorized legal assessment conducted by Hometrust, a product of Ehomes Global Inclusive Limited. Legal and cadastral searches are conducted in compliance with relevant state land registration statutes.', 50, y + 8, { width: 495 });
      doc.text('Verification Portal: https://hometrustng.com/verify | Inquiries: legal@hometrustng.com', 50, y + 34);

      doc.end();
      stream.on('finish', () => resolve(filePath));
      stream.on('error', reject);
    });
  }
}
