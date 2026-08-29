import { Router, Request, Response } from 'express';

export const aiRoutes = Router();

const SYSTEM_PROMPT = `You are the HomeVerify AI Legal & Property Advisor for Nigeria.
You assist buyers, developers, land owners, diaspora investors, and tenants with Nigerian real estate law, title verification, milestone escrow, and building cost estimations.

Key Knowledge:
- Land Titles: Certificate of Occupancy (C-of-O, 99-year state grant), Governor's Consent (required for transfers of C-of-O), Government Gazette / Excision (release of communal land), Registered Survey Plan (beacon coordinates at Surveyor General Office Alausa / Abuja AGIS).
- Red Flags: Committed government acquisition, right-of-way alignment (e.g. Coastal Highway, rail corridors, drainage setbacks), Omonile double-selling, unapproved building plans.
- Security & Payments: HomeVerify Milestone-Locked Escrow holds funds until certified engineers inspect foundation, DPC, roofing, and finishes. Dedicated Virtual NUBAN Bank Accounts (via Fincra) allow direct bank transfers without card limits.
- Tone: Professional, authoritative, concise, helpful, and protective of Nigerian property buyers.`;

aiRoutes.post('/chat', async (req: Request, res: Response) => {
  try {
    const { message, history } = req.body;

    if (!message || typeof message !== 'string') {
      return res.status(400).json({ success: false, message: 'Message is required' });
    }

    const openRouterKey = process.env.OPENROUTER_API_KEY;
    const models = [
      'meta-llama/llama-3.3-70b-instruct:free',
      'meta-llama/llama-3.1-8b-instruct:free',
      'google/gemini-2.0-flash-exp:free',
      'deepseek/deepseek-r1:free',
    ];

    const messages = [
      { role: 'system', content: SYSTEM_PROMPT },
      ...(Array.isArray(history) ? history.slice(-6) : []),
      { role: 'user', content: message },
    ];

    // Try OpenRouter if key is present
    if (openRouterKey && openRouterKey.startsWith('sk-')) {
      for (const model of models) {
        try {
          const fetchRes = await fetch('https://openrouter.ai/api/v1/chat/completions', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${openRouterKey}`,
              'HTTP-Referer': 'https://homeverify.ng',
              'X-Title': 'HomeVerify Mobile AI',
            },
            body: JSON.stringify({
              model,
              messages,
              max_tokens: 600,
              temperature: 0.7,
            }),
          });

          if (fetchRes.ok) {
            const data: any = await fetchRes.json();
            const reply = data.choices?.[0]?.message?.content;
            if (reply) {
              return res.json({
                success: true,
                reply,
                modelUsed: model,
              });
            }
          }
        } catch (e) {
          console.warn(`OpenRouter model ${model} failed, trying next:`, e);
        }
      }
    }

    // High-quality deterministic Nigerian legal AI fallback
    const query = message.toLowerCase();
    let reply = '';

    if (query.includes('lagos') || query.includes('document') || query.includes('verify') || query.includes('c of o') || query.includes('c-of-o')) {
      reply = 'Key Title Documents Required for Lagos Land:\n\n1. Certificate of Occupancy (C-of-O) or Governor\'s Consent: Confirms state-recognized ownership title.\n2. Registered Survey Plan: Coordinates must be lodged at the Surveyor General\'s Office (Alausa) to confirm land is NOT under committed government acquisition.\n3. Deed of Assignment: Establishes complete legal history and title chain.\n\nTip: You can submit your survey plan or C-of-O on the Verify tab for our legal team and surveyor AI to verify.';
    } else if (query.includes('escrow') || query.includes('milestone') || query.includes('protect')) {
      reply = 'How HomeVerify Milestone Escrow Works:\n\n- Your funds are held securely in an escrow trust vault.\n- The developer does NOT receive money upfront.\n- Independent certified structural engineers audit each stage on-site (Foundation, DPC, Lintel/Roofing, Finishing).\n- Developer payouts are only released after milestone verification is approved.';
    } else if (query.includes('gazette') || query.includes('difference') || query.includes('excision')) {
      reply = 'C-of-O vs. Government Gazette:\n\n- Gazette / Excision: Official government publication confirming ancestral land has been excised and released to the community.\n- C-of-O: Individual 99-year state grant given to a specific owner.\n\nNotice: Land with only a Gazette still requires processing a Governor\'s Consent or C-of-O for absolute legal title perfection.';
    } else if (query.includes('fincra') || query.includes('virtual account') || query.includes('pay') || query.includes('instalment') || query.includes('bank')) {
      reply = 'Dedicated Virtual NUBAN Bank Accounts:\n\n- Upon completing KYC, you receive a dedicated Nigerian bank account (Wema/Providus via Fincra).\n- You can transfer instalments directly from any banking app (GTB, Access, Zenith, Kuda).\n- Enjoy zero debit card limits, instant automated receipts, and continuous ledger tracking.';
    } else if (query.includes('cost') || query.includes('cement') || query.includes('price') || query.includes('rebar') || query.includes('build')) {
      reply = 'Current Construction Benchmark (Weekly Index):\n\n- 50kg Cement (Dangote/BUA): ₦8,400 - ₦8,700\n- 12mm TMT High-Yield Rebar: ~₦1,180,000 / ton\n- 30-Ton Clean Black Granite: ~₦285,000\n- 9-inch Solid Sandcrete Blocks: ₦780 - ₦850/unit\n\nCheck the Material Index feature on the home screen for live updates across Lagos, Abuja, and Port Harcourt.';
    } else {
      reply = `HomeVerify AI Advisory:\n\nRegarding: "${message}"\n\nIn Nigerian real estate transactions, strict title perfection and milestone controls are essential before committing funds. Always verify beacon coordinates at the state land bureau, confirm approved layout plans, and ensure all payments are locked in milestone escrow.\n\nWould you like our legal team to draft or review your contract of sale or survey plan?`;
    }

    return res.json({
      success: true,
      reply,
      modelUsed: 'homeverify-legal-heuristic',
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      message: 'Failed to process AI query',
      error: error.message,
    });
  }
});
