import { config } from '../../config';

export class ResendService {
  private static apiUrl = 'https://api.resend.com/emails';

  static async sendOtpEmail(to: string, otpCode: string, purpose: string = 'Verification'): Promise<boolean> {
    const apiKey = config.resend.apiKey;
    if (!apiKey) {
      console.warn('[RESEND] No API key configured. Logging OTP to console:', { to, otpCode, purpose });
      return true;
    }

    const title = purpose === 'LOGIN_2FA' ? 'Your Login Security Code' : 'Verify Your Email Address';
    const subText = purpose === 'LOGIN_2FA' 
      ? 'Use the code below to complete your two-factor authentication login to Hometrust.'
      : 'Welcome to Hometrust. Use the verification code below to verify your email address and activate your account.';

    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #0f172a; color: #ffffff; margin: 0; padding: 20px; }
          .container { max-width: 520px; margin: 0 auto; background: #1e293b; border-radius: 16px; border: 1px solid #334155; padding: 32px; }
          .header { text-align: center; margin-bottom: 24px; }
          .shield-icon { display: inline-block; background: #059669; width: 48px; height: 48px; line-height: 48px; border-radius: 12px; font-size: 24px; }
          .title { font-size: 20px; font-weight: 800; color: #ffffff; margin-top: 16px; margin-bottom: 8px; }
          .text { font-size: 14px; color: #94a3b8; line-height: 1.5; margin-bottom: 24px; text-align: center; }
          .otp-box { background: #0f172a; border: 2px dashed #059669; border-radius: 12px; padding: 20px; text-align: center; margin-bottom: 24px; }
          .otp-code { font-family: 'Courier New', Courier, monospace; font-size: 32px; font-weight: 900; letter-spacing: 8px; color: #10b981; }
          .expiry { font-size: 12px; color: #64748b; margin-top: 8px; }
          .footer { font-size: 12px; color: #64748b; text-align: center; border-top: 1px solid #334155; padding-top: 20px; margin-top: 24px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="shield-icon">🛡️</div>
            <div class="title">${title}</div>
          </div>
          <div class="text">${subText}</div>
          <div class="otp-box">
            <div class="otp-code">${otpCode}</div>
            <div class="expiry">Expires in 10 minutes • Do not share this code</div>
          </div>
          <div class="footer">
            If you did not request this verification code, please ignore this email or contact support@hometrust.ng.<br><br>
            &copy; 2026 Hometrust Technologies Ltd. CBN Real Estate Escrow & Title Verification.
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
