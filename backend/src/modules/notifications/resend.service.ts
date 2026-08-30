import { config } from '../../config';

export class ResendService {
  private static apiUrl = 'https://api.resend.com/emails';

  static async sendOtpEmail(to: string, otpCode: string, purpose: string = 'Verification'): Promise<boolean> {
    const apiKey = config.resend.apiKey;
    if (!apiKey) {
      console.warn('[RESEND] No API key configured. Logging OTP to console:', { to, otpCode, purpose });
      return true;
    }

    const title = purpose === 'LOGIN_2FA' ? 'Two-Factor Authentication Code' : 'Verify Your Email Address';
    const subText = purpose === 'LOGIN_2FA' 
      ? 'A sign-in attempt was initiated for your Hometrust account. Use the one-time security code below to complete your authentication.'
      : 'Welcome to Hometrust. Please enter the security verification code below to verify your email address and activate your account.';

    const htmlContent = `
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Hometrust Security Code</title>
        <style>
          body { margin: 0; padding: 0; background-color: #0b132b; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased; }
          .wrapper { width: 100%; table-layout: fixed; background-color: #0b132b; padding: 40px 0; }
          .main-card { max-width: 540px; margin: 0 auto; background: linear-gradient(180deg, #1c2541 0%, #111a33 100%); border-radius: 20px; border: 1px solid rgba(16, 185, 129, 0.25); box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4); overflow: hidden; padding: 40px 32px; }
          .logo-header { text-align: center; margin-bottom: 28px; }
          .brand-badge { display: inline-flex; align-items: center; justify-content: center; background: rgba(5, 150, 105, 0.15); border: 1px solid #10b981; border-radius: 12px; padding: 8px 18px; }
          .brand-name { font-size: 20px; font-weight: 900; letter-spacing: 2px; color: #10b981; text-transform: uppercase; }
          .title { font-size: 22px; font-weight: 800; color: #ffffff; text-align: center; margin: 20px 0 10px; }
          .subtitle { font-size: 14px; line-height: 1.6; color: #94a3b8; text-align: center; margin: 0 0 28px; }
          .otp-container { background: #0b132b; border: 2px dashed #10b981; border-radius: 16px; padding: 24px; text-align: center; margin-bottom: 28px; }
          .otp-code { font-family: 'Courier New', Courier, monospace; font-size: 38px; font-weight: 900; letter-spacing: 10px; color: #34d399; margin: 0; }
          .otp-timer { font-size: 12px; font-weight: 600; color: #64748b; margin-top: 10px; }
          .security-box { background: rgba(245, 158, 11, 0.08); border-left: 4px solid #f59e0b; border-radius: 6px; padding: 12px 16px; margin-bottom: 28px; }
          .security-text { font-size: 12px; color: #cbd5e1; line-height: 1.5; margin: 0; }
          .divider { border-top: 1px solid rgba(148, 163, 184, 0.15); margin: 28px 0; }
          .footer-section { text-align: center; }
          .footer-company { font-size: 12px; font-weight: 700; color: #94a3b8; margin-bottom: 6px; }
          .footer-sub { font-size: 11px; color: #64748b; line-height: 1.6; margin-bottom: 16px; }
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

            <div class="title">${title}</div>
            <div class="subtitle">${subText}</div>

            <div class="otp-container">
              <div class="otp-code">${otpCode}</div>
              <div class="otp-timer">⏱️ Expires in 10 minutes • Single-use code</div>
            </div>

            <div class="security-box">
              <p class="security-text">
                🔒 <strong>Security Warning:</strong> Hometrust staff will never ask for your OTP code or login credentials. If you did not initiate this request, please change your password immediately.
              </p>
            </div>

            <div class="divider"></div>

            <div class="footer-section">
              <div class="footer-company">Hometrust is a product of Ehomes Global Inclusive Ltd</div>
              <div class="footer-sub">
                Official Escrow Banking • Construction Milestone Audits • Verified Land Titles<br>
                No 4, Ehomes close, Zartech Area, Oluyole, Ibadan, Oyo state • info@hometrustng.com
              </div>
              <div class="footer-copy">
                &copy; ${new Date().getFullYear()} Ehomes Global Inclusive Ltd. All rights reserved.
              </div>
            </div>
          </div>
        </div>
      </body>
      </html>
    `;

    try {
      // First try sending from custom branded domain
      let response = await fetch(this.apiUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: config.resend.fromEmail,
          to: [to],
          subject: `${otpCode} is your Hometrust Security Code`,
          html: htmlContent,
        }),
      });

      let resData: any = await response.json();

      // If domain is unverified on Resend, retry with onboarding fallback address
      if (!response.ok && (resData?.message?.includes('domain') || resData?.message?.includes('not verified') || resData?.statusCode === 403)) {
        console.warn(`[RESEND] Branded domain not yet verified. Retrying with fallback sender: ${config.resend.fallbackFrom}`);
        response = await fetch(this.apiUrl, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            from: `Hometrust <${config.resend.fallbackFrom}>`,
            to: [to],
            subject: `${otpCode} is your Hometrust Security Code`,
            html: htmlContent,
          }),
        });
        resData = await response.json() as any;
      }

      if (response.ok) {
        console.log(`[RESEND] OTP email sent successfully to ${to} (ID: ${resData?.id})`);
        return true;
      } else {
        console.error('[RESEND] Failed to send email via Resend API:', resData);
        // Fallback console log in dev
        console.log(`[DEV OTP FALLBACK] Email to ${to}: Code is ${otpCode}`);
        return true;
      }
    } catch (err: any) {
      console.error('[RESEND] Error sending email:', err.message);
      console.log(`[DEV OTP FALLBACK] Email to ${to}: Code is ${otpCode}`);
      return true;
    }
  }
}
