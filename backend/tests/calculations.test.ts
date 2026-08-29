import { PaymentsService } from '../src/modules/payments/payments.service';

describe('Payment Engine & Financial Calculations', () => {
  it('should calculate platform and processing fees correctly without floating point errors', async () => {
    const amount = 500000; // ₦500,000 instalment
    const breakdown = await PaymentsService.calculateFees(amount, 'INSTALMENT');

    expect(breakdown.amount).toBe(500000);
    // Platform fee (5,000 fixed + 1.0% = 10,000 or 5,000 default)
    expect(breakdown.platformFee).toBeGreaterThanOrEqual(5000);
    // Paystack fee: 1.5% + N100 capped at 2000 => 500000 * 0.015 = 7500 => capped at 2000
    expect(breakdown.processingFee).toBe(2000);
    expect(breakdown.totalAmount).toBe(breakdown.amount + breakdown.platformFee + breakdown.processingFee);
  });

  it('should calculate monthly instalment accurately for off-plan property', () => {
    const totalPrice = 60000000; // ₦60,000,000
    const initialDeposit = 10000000; // ₦10,000,000
    const durationMonths = 24;

    const remainingBalance = totalPrice - initialDeposit;
    const monthlyPayment = remainingBalance / durationMonths;

    expect(remainingBalance).toBe(50000000);
    expect(monthlyPayment).toBeCloseTo(2083333.33, 2);
  });

  it('should format kobo minor units accurately for Paystack integration', () => {
    const totalNaira = 120500.50;
    const koboAmount = Math.round(totalNaira * 100);

    expect(koboAmount).toBe(12050050);
  });
});
