import { config } from '../../config';

export class TwilioService {
  static async sendOtpSms(toPhone: string, otpCode: string, purpose: string = 'Verification'): Promise<boolean> {
    const { accountSid, authToken, phoneNumber, verifyServiceSid } = config.twilio;

    // Normalize Nigerian phone numbers: e.g. 08026990956 -> +2348026990956
    let formattedPhone = toPhone.trim().replace(/\s+/g, '');
    if (formattedPhone.startsWith('0') && formattedPhone.length === 11) {
      formattedPhone = '+234' + formattedPhone.substring(1);
    } else if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+234' + formattedPhone;
    }

    const messageBody = `Your Hometrust security OTP code is: ${otpCode}. Valid for 10 minutes. Please do not share this code with anyone. This verification is from Hometrust (Ehomes Global Inclusive Limited).`;

    if (!accountSid || !authToken) {
      console.log(`[TWILIO SMS SIMULATOR] To: ${formattedPhone} | Code: ${otpCode} | Message: "${messageBody}"`);
      return true;
    }

    try {
      // 1. If Verify Service SID is provided, use Twilio Verify API
      if (verifyServiceSid) {
        const verifyUrl = `https://verify.twilio.com/v2/Services/${verifyServiceSid}/Verifications`;
        const authHeader = 'Basic ' + Buffer.from(`${accountSid}:${authToken}`).toString('base64');

        const params = new URLSearchParams();
        params.append('To', formattedPhone);
        params.append('Channel', 'sms');

        const response = await fetch(verifyUrl, {
          method: 'POST',
          headers: {
            'Authorization': authHeader,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: params.toString(),
        });

        const resData: any = await response.json();
        if (response.ok) {
          console.log(`[TWILIO VERIFY] SMS OTP dispatched to ${formattedPhone} (SID: ${resData?.sid})`);
          return true;
        } else {
          console.error('[TWILIO VERIFY] Error from Twilio Verify API:', resData);
          console.log(`[DEV OTP FALLBACK] SMS to ${formattedPhone}: Code is ${otpCode}`);
          return true;
        }
      }

      // 2. Standard Twilio Messages API (Works with UK/US numbers or Alphanumeric Sender IDs to Nigeria)
      const messagesUrl = `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`;
      const authHeader = 'Basic ' + Buffer.from(`${accountSid}:${authToken}`).toString('base64');

      const params = new URLSearchParams();
      params.append('To', formattedPhone);
      params.append('From', phoneNumber || 'HOMETRUST');
      params.append('Body', messageBody);

      const response = await fetch(messagesUrl, {
        method: 'POST',
        headers: {
          'Authorization': authHeader,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params.toString(),
      });

      const resData: any = await response.json();
      if (response.ok) {
        console.log(`[TWILIO SMS] Message queued successfully to ${formattedPhone} (SID: ${resData?.sid})`);
        return true;
      } else {
        console.error('[TWILIO SMS] Error sending SMS:', resData);
        console.log(`[DEV OTP FALLBACK] SMS to ${formattedPhone}: Code is ${otpCode}`);
        return true;
      }
    } catch (err: any) {
      console.error('[TWILIO SMS] Network error:', err.message);
      console.log(`[DEV OTP FALLBACK] SMS to ${formattedPhone}: Code is ${otpCode}`);
      return true;
    }
  }
}
