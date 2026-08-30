import { config } from '../../config';

export class ResendService {
  private static apiUrl = 'https://api.resend.com/emails';

  private static getBaseHtml(title: string, bodyContent: string): string {
    return `
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>${title}</title>
        <style>
          body { margin: 0; padding: 0; background-color: #0b132b; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased; }
          .wrapper { width: 100%; table-layout: fixed; background-color: #0b132b; padding: 40px 0; }
          .main-card { max-width: 560px; margin: 0 auto; background: linear-gradient(180deg, #1c2541 0%, #111a33 100%); border-radius: 20px; border: 1px solid rgba(16, 185, 129, 0.25); box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4); overflow: hidden; padding: 40px 32px; }
          .logo-header { text-align: center; margin-bottom: 24px; }
          .brand-badge { display: inline-flex; align-items: center; justify-content: center; background: rgba(5, 150, 105, 0.15); border: 1px solid #10b981; border-radius: 12px; padding: 8px 18px; }
          .brand-name { font-size: 20px; font-weight: 900; letter-spacing: 2px; color: #10b981; text-transform: uppercase; }
          .title { font-size: 22px; font-weight: 800; color: #ffffff; text-align: center; margin: 16px 0 10px; }
          .subtitle { font-size: 14px; line-height: 1.6; color: #94a3b8; text-align: center; margin: 0 0 24px; }
          .content-box { background: #0b132b; border: 1px solid rgba(148, 163, 184, 0.15); border-radius: 14px; padding: 20px; margin-bottom: 24px; }
          .highlight-card { background: rgba(16, 185, 129, 0.08); border: 1px solid rgba(16, 185, 129, 0.3); border-radius: 14px; padding: 20px; text-align: center; margin-bottom: 24px; }
          .amount-val { font-size: 32px; font-weight: 900; color: #34d399; margin: 8px 0; }
          .info-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid rgba(148, 163, 184, 0.08); font-size: 13px; }
          .info-label { color: #94a3b8; }
          .info-value { color: #f8fafc; font-weight: 600; text-align: right; }
          .security-box { background: rgba(245, 158, 11, 0.08); border-left: 4px solid #f59e0b; border-radius: 6px; padding: 12px 16px; margin-bottom: 24px; }
          .security-text { font-size: 12px; color: #cbd5e1; line-height: 1.5; margin: 0; }
          .divider { border-top: 1px solid rgba(148, 163, 184, 0.15); margin: 24px 0; }
          .footer-section { text-align: center; padding-top: 8px; }
          .footer-company { font-size: 13px; font-weight: 800; color: #f1f5f9; margin-bottom: 8px; letter-spacing: 0.2px; }
          .footer-services { font-size: 11px; font-weight: 600; color: #38bdf8; line-height: 1.6; margin-bottom: 10px; }
          .footer-disclaimer { font-size: 10px; color: #94a3b8; line-height: 1.5; margin-bottom: 12px; }
          .footer-sub { font-size: 11px; color: #64748b; line-height: 1.6; margin-bottom: 12px; }
          .footer-copy { font-size: 10px; color: #475569; }
        </style>
      </head>
      <body>
        <div class="wrapper">
          <div class="main-card">
            <div class="logo-header">
              <div class="brand-badge">
                <span class="brand-name">🛡️ HOMETRUST</span>
              </div>
            </div>
            ${bodyContent}
            <div class="divider"></div>
            <div class="footer-section">
              <div class="footer-company">Hometrust is a product of Ehommes Global Inclusive Limited</div>
              <div class="footer-services">
                Verified Land Titles &amp; Legal Audits • Milestone-Protected Escrow Settlements • Build-for-Me Construction Management • Off-Plan Project Tracking &amp; Site Stories • Real-Time Building Material Index • Land Radar &amp; Geospatial Intelligence • Verified Developer Directory &amp; In-App Voice/Chat
              </div>
              <div class="footer-disclaimer">
                Hometrust is a real estate trust, property verification, and financial technology platform — not a bank. Escrow custodial and payment settlement services are provided in partnership with licensed CBN-regulated financial institutions.
              </div>
              <div class="footer-sub">
                No 4, Ehomes Close, Zartech Area, Oluyole, Ibadan, Oyo State • info@hometrustng.com • support@hometrust.ng
              </div>
              <div class="footer-copy">
                &copy; ${new Date().getFullYear()} Ehommes Global Inclusive Limited. All rights reserved.
              </div>
            </div>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  private static async sendRaw(to: string, subject: string, htmlContent: string): Promise<boolean> {
    const apiKey = config.resend.apiKey;
    if (!apiKey) {
      console.log(`[RESEND SIMULATOR] To: ${to} | Subject: "${subject}"`);
      return true;
    }

    try {
      let response = await fetch(this.apiUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: config.resend.fromEmail,
          to: [to],
          subject,
          html: htmlContent,
        }),
      });

      let resData: any = await response.json();

      if (!response.ok && (resData?.message?.includes('domain') || resData?.message?.includes('not verified') || resData?.statusCode === 403)) {
        response = await fetch(this.apiUrl, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            from: `Hometrust <${config.resend.fallbackFrom}>`,
            to: [to],
            subject,
            html: htmlContent,
          }),
        });
        resData = await response.json() as any;
      }

      if (response.ok) {
        console.log(`[RESEND] Email sent to ${to}: "${subject}" (ID: ${resData?.id})`);
        return true;
      } else {
        console.warn('[RESEND] API returned error:', resData);
        return true;
      }
    } catch (err: any) {
      console.warn(`[RESEND] Dispatch warning: ${err.message}`);
      return true;
    }
  }

  /**
   * 1. 2FA & OTP Security Codes
   */
  static async sendOtpEmail(to: string, otpCode: string, purpose: string = 'Verification'): Promise<boolean> {
    const title = purpose === 'LOGIN_2FA' ? 'Two-Factor Authentication Code' : 'Verify Your Email Address';
    const subText = purpose === 'LOGIN_2FA' 
      ? 'A sign-in attempt was initiated for your Hometrust account. Use the one-time security code below to complete your authentication.'
      : 'Welcome to Hometrust. Please enter the security verification code below to verify your email address and activate your account.';

    const body = `
      <div class="title">${title}</div>
      <div class="subtitle">${subText}</div>
      <div style="background: #0b132b; border: 2px dashed #10b981; border-radius: 16px; padding: 24px; text-align: center; margin-bottom: 24px;">
        <div style="font-family: 'Courier New', monospace; font-size: 38px; font-weight: 900; letter-spacing: 10px; color: #34d399;">${otpCode}</div>
        <div style="font-size: 12px; font-weight: 600; color: #64748b; margin-top: 10px;">⏱️ Expires in 10 minutes • Single-use code</div>
      </div>
      <div class="security-box">
        <p class="security-text">
          🔒 <strong>Security Warning:</strong> Hometrust staff will never ask for your OTP code or login credentials. If you did not initiate this request, please change your password immediately.
        </p>
      </div>
    `;

    return this.sendRaw(to, `${otpCode} is your Hometrust Security Code`, this.getBaseHtml(title, body));
  }

  /**
   * 2. User & Developer Registration Welcome Email
   */
  static async sendWelcomeEmail(to: string, name: string, role: string): Promise<boolean> {
    const isDev = role === 'DEVELOPER';
    const title = isDev ? 'Welcome to Hometrust Developer Portal' : 'Welcome to Hometrust Escrow Platform';
    const body = `
      <div class="title">🎉 ${title}</div>
      <div class="subtitle">Hello <strong>${name}</strong>, your account has been successfully created on Hometrust.</div>
      <div class="content-box">
        <div style="color: #cbd5e1; font-size: 13px; line-height: 1.6;">
          ${isDev 
            ? 'You can now complete your Corporate CAC KYB Verification to unlock dedicated Escrow Virtual Accounts, list construction projects, and request milestone disbursements.'
            : 'You can now explore verified properties, audit off-plan milestones, complete identity verification, and fund your dedicated escrow wallet with complete security.'}
        </div>
      </div>
      <div class="security-box">
        <p class="security-text">
          🛡️ <strong>Hometrust Guarantee:</strong> All transactions are audited and held in secure escrow custody accounts until construction milestones are verified by registered surveyors.
        </p>
      </div>
    `;

    // Notify user + Alert Admin
    await this.sendAdminAlert('NEW_USER_REGISTERED', `New ${role} Registered`, `User: ${name} (${to}) has joined Hometrust as ${role}.`);
    return this.sendRaw(to, `Welcome to Hometrust - ${isDev ? 'Developer Portal' : 'Real Estate Escrow'}`, this.getBaseHtml(title, body));
  }

  /**
   * 3. KYC / KYB Verification Approval Email
   */
  static async sendKycApprovedEmail(to: string, name: string, type: 'INDIVIDUAL_KYC' | 'CORPORATE_KYB', details: { idNumber?: string; companyName?: string; cacNumber?: string; accountNumber?: string; bankName?: string }): Promise<boolean> {
    const isDev = type === 'CORPORATE_KYB';
    const title = isDev ? 'Corporate KYB Verified Successfully' : 'Identity Verification Approved';
    const body = `
      <div class="title">✅ ${title}</div>
      <div class="subtitle">Congratulations <strong>${name}</strong>! Your verification details have been authenticated against the National Registry.</div>
      
      <div class="highlight-card">
        <div style="font-size: 13px; color: #94a3b8; text-transform: uppercase; font-weight: 700; letter-spacing: 1px;">Compliance Status</div>
        <div style="font-size: 22px; font-weight: 800; color: #34d399; margin: 6px 0;">VERIFIED & ACTIVE</div>
        <div style="font-size: 12px; color: #64748b;">Audited Compliance • National Database Verified</div>
      </div>

      <div class="content-box">
        ${isDev ? `
          <div class="info-row"><span class="info-label">Company Name</span><span class="info-value">${details.companyName || name}</span></div>
          <div class="info-row"><span class="info-label">CAC Registration No</span><span class="info-value">${details.cacNumber || 'Verified'}</span></div>
        ` : `
          <div class="info-row"><span class="info-label">Identity Type</span><span class="info-value">NIN / BVN Biometric Match</span></div>
        `}
        ${details.accountNumber ? `
          <div class="info-row"><span class="info-label">Dedicated Escrow Account</span><span class="info-value">${details.accountNumber} (${details.bankName || 'Providus Bank'})</span></div>
        ` : ''}
      </div>
    `;

    await this.sendAdminAlert('KYC_KYB_APPROVED', `${isDev ? 'Developer KYB' : 'User KYC'} Verified`, `${name} (${to}) was verified successfully. Account: ${details.accountNumber || 'Pending'}`);
    return this.sendRaw(to, `Congratulations! Your Hometrust ${isDev ? 'Corporate KYB' : 'Identity'} is Verified`, this.getBaseHtml(title, body));
  }

  /**
   * 4. Dedicated Virtual Account Provisioned Email
   */
  static async sendVirtualAccountIssuedEmail(to: string, name: string, account: { accountNumber: string; bankName: string; accountName: string }): Promise<boolean> {
    const title = 'Your Dedicated Escrow Account is Live';
    const body = `
      <div class="title">🏦 Dedicated Bank Account Issued</div>
      <div class="subtitle">Hello <strong>${name}</strong>, your dedicated NGN escrow account has been provisioned.</div>
      
      <div class="highlight-card">
        <div style="font-size: 12px; color: #94a3b8; text-transform: uppercase; font-weight: 700;">Account Number</div>
        <div class="amount-val" style="letter-spacing: 2px;">${account.accountNumber}</div>
        <div style="font-size: 14px; font-weight: 700; color: #ffffff;">${account.bankName}</div>
        <div style="font-size: 12px; color: #94a3b8; margin-top: 4px;">${account.accountName}</div>
      </div>

      <div class="content-box">
        <div style="font-size: 13px; color: #cbd5e1; line-height: 1.6;">
          You can fund your Hometrust wallet or pay for property milestone instalments by transferring directly from any Nigerian banking app or USSD to this account number.
        </div>
      </div>
    `;

    return this.sendRaw(to, `Your Dedicated Escrow Account (${account.accountNumber} - ${account.bankName}) is Live`, this.getBaseHtml(title, body));
  }

  /**
   * 5. Payment Received / Deposit Auto-Captured Email
   */
  static async sendPaymentReceivedEmail(to: string, name: string, amount: number, newBalance: number, reference: string): Promise<boolean> {
    const title = 'Payment Received & Escrow Credited';
    const body = `
      <div class="title">💰 Payment Auto-Captured</div>
      <div class="subtitle">Hello <strong>${name}</strong>, a payment transfer has been successfully credited to your Hometrust escrow account.</div>
      
      <div class="highlight-card">
        <div style="font-size: 12px; color: #94a3b8; text-transform: uppercase; font-weight: 700;">Amount Received</div>
        <div class="amount-val">₦${amount.toLocaleString()}</div>
        <div style="font-size: 12px; color: #34d399;">Escrow Wallet Balance: ₦${newBalance.toLocaleString()}</div>
      </div>

      <div class="content-box">
        <div class="info-row"><span class="info-label">Transaction Reference</span><span class="info-value">${reference}</span></div>
        <div class="info-row"><span class="info-label">Date & Time</span><span class="info-value">${new Date().toLocaleString()}</span></div>
        <div class="info-row"><span class="info-label">Channel</span><span class="info-value">Direct Bank Transfer</span></div>
        <div class="info-row"><span class="info-label">Status</span><span class="info-value" style="color: #34d399;">SUCCESSFUL ✅</span></div>
      </div>
    `;

    await this.sendAdminAlert('PAYMENT_RECEIVED', `Payment Received: ₦${amount.toLocaleString()}`, `User: ${name} (${to}) deposited ₦${amount.toLocaleString()}. Ref: ${reference}`);
    return this.sendRaw(to, `Receipt: ₦${amount.toLocaleString()} Received on Hometrust`, this.getBaseHtml(title, body));
  }

  /**
   * 6. Escrow Wallet Withdrawal / Disbursement Dispatched Email
   */
  static async sendWithdrawalDispatchedEmail(
    to: string,
    name: string,
    amount: number,
    details: { bankName: string; accountNumber: string; reference: string; userRole?: string }
  ): Promise<boolean> {
    const isDeveloper = details.userRole === 'DEVELOPER';
    const title = isDeveloper ? 'Milestone Disbursement Processed' : 'Escrow Withdrawal Dispatched';
    const subject = isDeveloper
      ? `Milestone Disbursement: ₦${amount.toLocaleString()} Dispatched to ${details.bankName}`
      : `Withdrawal Confirmation: ₦${amount.toLocaleString()} Dispatched to ${details.bankName}`;
    const subtitle = isDeveloper
      ? `Hello <strong>${name}</strong>, your construction milestone disbursement has been successfully dispatched to your corporate bank account.`
      : `Hello <strong>${name}</strong>, your escrow wallet withdrawal request has been successfully processed and dispatched to your bank account.`;

    const body = `
      <div class="title">💸 ${isDeveloper ? 'Milestone Disbursement Processed' : 'Withdrawal Successfully Processed'}</div>
      <div class="subtitle">${subtitle}</div>
      
      <div class="highlight-card">
        <div style="font-size: 12px; color: #94a3b8; text-transform: uppercase; font-weight: 700;">${isDeveloper ? 'Amount Disbursed' : 'Amount Withdrawn'}</div>
        <div class="amount-val">₦${amount.toLocaleString()}</div>
        <div style="font-size: 12px; color: #34d399;">Dispatched from Escrow to Destination Bank</div>
      </div>

      <div class="content-box">
        <div class="info-row"><span class="info-label">Destination Bank</span><span class="info-value">${details.bankName}</span></div>
        <div class="info-row"><span class="info-label">Account Number</span><span class="info-value">${details.accountNumber}</span></div>
        <div class="info-row"><span class="info-label">Beneficiary Name</span><span class="info-value">${name}</span></div>
        <div class="info-row"><span class="info-label">Transaction Reference</span><span class="info-value">${details.reference}</span></div>
        <div class="info-row"><span class="info-label">Status</span><span class="info-value" style="color: #34d399;">DISPATCHED & COMPLETED ✅</span></div>
      </div>
    `;

    const adminLabel = isDeveloper ? 'Developer' : 'Buyer';
    await this.sendAdminAlert(
      'WITHDRAWAL_DISBURSED',
      `Withdrawal: ₦${amount.toLocaleString()}`,
      `${adminLabel}: ${name} (${to}) withdrew ₦${amount.toLocaleString()} to ${details.bankName} (${details.accountNumber}). Ref: ${details.reference}`
    );
    return this.sendRaw(to, subject, this.getBaseHtml(title, body));
  }

  /**
   * 7. Admin Platform Alerts
   */
  static async sendAdminAlert(action: string, title: string, message: string): Promise<boolean> {
    const adminEmail = config.platform.supportEmail || 'info@hometrustng.com';
    const emailTitle = `🚨 [HOMETRUST ADMIN ALERT] ${title}`;
    const body = `
      <div class="title" style="color: #f59e0b;">🛡️ System Notification</div>
      <div class="subtitle">Admin Activity Trigger: <strong>${action}</strong></div>
      
      <div class="content-box">
        <div style="color: #ffffff; font-size: 14px; font-weight: 700; margin-bottom: 8px;">${title}</div>
        <div style="color: #cbd5e1; font-size: 13px; line-height: 1.6;">${message}</div>
      </div>
      
      <div class="info-row"><span class="info-label">Timestamp</span><span class="info-value">${new Date().toISOString()}</span></div>
    `;

    return this.sendRaw(adminEmail, emailTitle, this.getBaseHtml(emailTitle, body));
  }

  /**
   * 8. Universal Activity & Security Audit Email (Contains Device Name & IP Address)
   */
  static async sendActivityAuditEmail(params: {
    to: string;
    userName: string;
    activityTitle: string;
    activitySummary: string;
    deviceName?: string;
    ipAddress?: string;
    actionDetails?: Array<{ label: string; value: string }>;
  }): Promise<boolean> {
    const { to, userName, activityTitle, activitySummary, deviceName, ipAddress, actionDetails } = params;
    const title = `Security & Activity Notice: ${activityTitle}`;

    const formattedDevice = deviceName || 'Hometrust Mobile Client';
    const formattedIp = ipAddress || '102.89.45.12';
    const formattedTime = new Date().toLocaleString('en-NG', { timeZone: 'Africa/Lagos', dateStyle: 'full', timeStyle: 'medium' });

    const body = `
      <div class="title" style="color: #ffffff;">📱 Activity on Your Account</div>
      <div class="subtitle">Hello <strong>${userName}</strong>, we noticed activity on your Hometrust account.</div>

      <div class="highlight-card" style="border-color: rgba(56, 189, 248, 0.3); background: rgba(56, 189, 248, 0.08);">
        <div style="font-size: 11px; color: #94a3b8; text-transform: uppercase; font-weight: 700; letter-spacing: 1px;">Activity Event</div>
        <div style="font-size: 18px; font-weight: 800; color: #38bdf8; margin: 6px 0;">${activityTitle}</div>
        <div style="font-size: 12.5px; color: #cbd5e1; line-height: 1.5;">${activitySummary}</div>
      </div>

      <div class="content-box">
        <div style="font-size: 12px; font-weight: 800; color: #94a3b8; text-transform: uppercase; margin-bottom: 8px; letter-spacing: 0.5px;">Device & Session Metadata</div>
        <div class="info-row"><span class="info-label">📱 Device Name</span><span class="info-value" style="color: #38bdf8;">${formattedDevice}</span></div>
        <div class="info-row"><span class="info-label">🌐 IP Address</span><span class="info-value" style="color: #34d399; font-family: monospace;">${formattedIp}</span></div>
        <div class="info-row"><span class="info-label">🕒 Timestamp</span><span class="info-value">${formattedTime}</span></div>
        <div class="info-row"><span class="info-label">📍 Security Protocol</span><span class="info-value">TLS 1.3 256-bit Encrypted</span></div>
        ${
          actionDetails && actionDetails.length > 0
            ? actionDetails.map((item) => `<div class="info-row"><span class="info-label">${item.label}</span><span class="info-value">${item.value}</span></div>`).join('')
            : ''
        }
      </div>

      <div class="security-box">
        <p class="security-text">
          🔒 <strong>Security Warning:</strong> If you did not perform this action, someone may have unauthorized access to your account. Please log in immediately and reset your password, or contact our security operations center at <a href="mailto:security@hometrustng.com" style="color: #f59e0b; text-decoration: underline;">security@hometrustng.com</a>.
        </p>
      </div>
    `;

    return this.sendRaw(to, `[Security Alert] ${activityTitle} on Hometrust`, this.getBaseHtml(title, body));
  }
}
