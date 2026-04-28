final Map<String, Map<String, String>> developerDocs = {
  'Getting Started': {
    'Overview': '''
# PesaCrow: The Complete Platform & Integration Guide

Welcome to the **PesaCrow Master Guide**. This document is designed to bridge the gap between business strategy and technical execution. 

Whether you are a **Business Owner** looking to understand how PesaCrow secures your revenue and increases sales, or a **Developer** tasked with integrating our system into your app or website, this guide contains everything you need to know from the first concept to going live.

## The Core Problem: Trust in Digital Commerce
In online business, a massive standoff exists:
*   **Buyers** are afraid to send money upfront via M-Pesa to a stranger, fearing they will be scammed and never receive the goods.
*   **Sellers** are afraid to dispatch valuable goods without being paid first, fearing the buyer will vanish or send fake payment screenshots.

This lack of trust leads to "Payment on Delivery" (which is expensive and risky for the seller) or abandoned shopping carts (lost revenue).

## The Solution: How PesaCrow Works
PesaCrow provides **"Trust-as-a-Service."** We act as an impartial digital middleman.

Here is the simple, 4-step lifecycle of a PesaCrow transaction:
1.  **Agreement**: The buyer checks out on your website.
2.  **Secure Payment**: The buyer pays via an M-Pesa prompt on their phone. *The money does not go to you yet.* It goes into PesaCrow's highly secure trust account.
3.  **Delivery**: Because the money is guaranteed to be waiting, you confidently ship the item to the buyer.
4.  **Release**: The buyer receives the item, inspects it, and approves the release. PesaCrow instantly deposits the funds into your M-Pesa account.

## Business Benefits
*   **Skyrocket Conversion Rates**: When buyers see "Protected by PesaCrow," their hesitation vanishes. Platforms see up to a 60% increase in completed checkouts.
*   **Zero Fraud & Reversal Protection**: You never have to worry about fake M-Pesa messages or buyers calling Safaricom to reverse funds. PesaCrow handles the M-Pesa collection directly; once we say the funds are held, they are cryptographically guaranteed.
*   **No Manual M-Pesa Accounting**: Stop checking your phone for payment messages. The API automatically links payments to specific orders in your database.
''',
    'Integration Approaches': '''
# Integration Approaches

PesaCrow is built on a modern, RESTful architecture designed for reliability, security, and developer experience (DevX).

## Two Ways to Integrate
You have two primary ways to integrate:
*   **The Drop-In UI (JS SDK)**: The easiest method for websites. Add one script tag, and we handle the M-Pesa phone number input, the loading spinners, and the success animations via a beautiful pop-up modal.
*   **The Custom API**: For mobile apps (Flutter/React Native) or custom flows, you can call our REST endpoints directly, giving you 100% control over the user interface.

## Environments: Sandbox vs. Production
You must never write your first lines of code using real money. 

*   **The Sandbox (`sandbox-api.escrow.pesacrow.top`)**: This is a safe testing environment. When you trigger an M-Pesa payment here, no prompt goes to your phone. Instead, you use our simulator to magically mark the transaction as "Success" or "Failed" to see how your website reacts.
*   **Production (`api.escrow.pesacrow.top`)**: The live environment. Real money moves, real M-Pesa prompts appear, and real fees are charged. 

## The 4-Step Technical Flow
1.  **Create Deal**: Your server securely tells PesaCrow the item price and description. PesaCrow returns a unique `Transaction ID`.
2.  **Initiate STK Push**: You send us the buyer's phone number. We trigger Safaricom to pop up the PIN prompt on their phone.
3.  **Webhooks (Listening)**: M-Pesa payments take a few seconds. When the user enters their PIN, PesaCrow sends an instant, automated HTTP `POST` request (a Webhook) to your server saying, *"Order 123 is paid. Ship it!"*
4.  **Deliver**: Your system calls our API to inform us the item has been shipped.
''',
    'Authentication & Security': '''
# Authentication & Security

You must register as a Platform Partner to obtain your credentials:
1.  **API Key (`apiKey`)**: Passed via the `x-api-key` header for all requests. Prefix: `pk_`.
2.  **API Secret (`apiSecret`)**: Used strictly to verify incoming webhooks. Prefix: `sk_`. Never expose this in frontend code.

## 🔑 Your Sandbox Credentials
Use these for all server-to-server calls (Shopify, WooCommerce, etc.) in your development environment:

| Field | Sandbox Value |
| :--- | :--- |
| **API Key (x-api-key)** | `pk_sandbox_6f52968378942b8e` |
| **API Secret** | `sk_sandbox_a928475261039485` |
| **Default Test Seller** | `254700000000` |

## Critical Technical Requirements
To integrate successfully, your tech team must implement the following:
*   **Idempotency Keys**: Network drops happen. To prevent a buyer from being charged twice if your server retries a request, you must pass a unique `Idempotency-Key` header when creating deals.
*   **Webhook Signatures**: To prevent hackers from faking payment confirmations, every webhook we send is cryptographically signed using your secret `API_SECRET`. Your server must verify this signature before marking an order as paid.
*   **HTTPS**: All webhooks must be received on a secure `https://` endpoint.
''',
    'Going Live': '''
# The "Going Live" Checklist

Transitioning from development to a live, money-moving application requires coordination between the business owner and the lead developer.

## Business Owner Checklist
- [ ] **KYC & Registration**: Complete the PesaCrow merchant verification process (providing business registration details if applicable).
- [ ] **Payout Configuration**: Verify that the primary merchant phone number registered with PesaCrow is correct. This is where your cleared funds will be deposited.
- [ ] **Customer Support Plan**: Ensure your website clearly explains the Escrow process so buyers know why they are paying PesaCrow instead of paying you directly.

## Developer Checklist
- [ ] **Environment Switch**: Change all Base URLs in your code from `sandbox-api...` to `api...`.
- [ ] **Swap API Keys**: Replace your Sandbox `apiKey` and `apiSecret` with your live Production keys.
- [ ] **Signature Verification Active**: Ensure the code that verifies the `x-pesacrow-signature` on incoming webhooks is enabled and strictly enforced.
- [ ] **Error Handling**: Verify that your application gracefully handles `429 Too Many Requests` (Rate Limits) and network timeouts.
- [ ] **End-to-End Live Test**: Perform a live transaction of KSh 100 with a real phone to verify the end-to-end flow, from payment to final payout release.
''',
  },
  'SDK & Tools': {
    'JS SDK (Web)': '''
# Embedded Checkout UI (JS SDK)

The fastest way to integrate is using our Drop-in UI. It handles phone number input, STK push triggers, loading spinners, and polling.

### Features
*   **Automatic Polling**: Updates UI instantly when the payment completes.
*   **Framework Agnostic**: Works perfectly with Vanilla HTML, React, Vue, Next.js, and other SPAs.
*   **Callbacks**: Complete control over the user journey with success, error, and cancellation hooks.

### Full HTML Demo

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>My Store Checkout</title>
    <!-- 1. Include the SDK -->
    <script src="https://api.escrow.pesacrow.top/pesacrow.js"></script>
</head>
<body>
    <h1>Checkout</h1>
    <p>Total: KSh 1,500</p>
    <button id="pay-btn">Pay Securely via PesaCrow</button>

    <script>
        document.getElementById('pay-btn').addEventListener('click', async () => {
            // 2. Your backend creates the deal and returns the ID
            const response = await fetch('/your-backend/create-deal', { method: 'POST' });
            const data = await response.json();
            const txId = data.transactionId; // e.g., 'ESC-KE-123456'

            // 3. Launch the UI
            PesaCrow.pay(txId, {
                onSuccess: function() {
                    alert('Payment successful! Your order is being processed.');
                    window.location.href = '/order-success';
                },
                onCancel: function() {
                    console.log('User closed the modal.');
                },
                onError: function(err) {
                    console.error('Payment failed:', err.message);
                },
                onStatusChange: function(status) {
                    console.log('Deal status changed to:', status);
                }
            });
        });
    </script>
</body>
</html>
```

### React / Next.js Considerations
Since the SDK attaches to the global `window` object, ensure you load it securely. In Next.js, use the `next/script` component:
```jsx
import Script from 'next/script';

export default function Checkout() {
  const handlePayment = () => {
    window.PesaCrow.pay('ESC-KE-123456', { onSuccess: () => console.log('Paid!') });
  };

  return (
    <>
      <Script src="https://api.escrow.pesacrow.top/pesacrow.js" strategy="lazyOnload" />
      <button onClick={handlePayment}>Pay</button>
    </>
  );
}
```
''',
    'Mobile Integrations': '''
# Mobile & Non-Web Integrations

If building in **Flutter** or **React Native**, the JS SDK cannot be used.
1.  Your backend creates the deal (`POST /deals/create`).
2.  Your app presents a native input for the phone number.
3.  Your app calls your backend, which calls `POST /payments/initiate-stk`.
4.  Your app polls `GET /open/deals/{transactionId}` every 3 seconds to update the UI.
5.  Your backend listens for webhooks to finalize the database state.
''',
  },
  'API Reference': {
    'Create Deal': '''
# Create Deal

Initializes the escrow agreement. Calculates fees dynamically. Returns a `transactionId` and a `shareLink` (useful for P2P sharing).

**Method & Path**: `POST /deals/create`

### Headers
| Header | Required | Description |
| :--- | :--- | :--- |
| `x-api-key` | Yes | Your Platform API Key (`pk_...`) |
| `Idempotency-Key` | Recommended | Unique string (e.g., `order_123`) to prevent duplicates. |

### Request Body
| Field | Type | Required | Description | Constraints |
| :--- | :--- | :--- | :--- | :--- |
| `sellerPhone` | String | Yes | Your platform/merchant M-Pesa number. | Valid Kenyan format (e.g., 2547XXXXXXXX). |
| `amount` | Number | Yes | Base price of goods in KSh. | Min: 100. |
| `description` | String | Yes | Item description shown in SMS. | 3-500 chars. |
| `buyerPhone` | String | No | Buyer's M-Pesa number. Pre-fills UIs. | Valid Kenyan format. |

### Success Response (201 Created)
```json
{
  "success": true,
  "message": "Deal created successfully.",
  "data": {
    "transactionId": "ESC-KE-584930",
    "amount": 1500,
    "description": "Nike Air Max Size 42",
    "sellerPhone": "254711XXXX44",
    "status": "pending_payment",
    "escrowFee": 45,
    "totalBuyerPays": 1545,
    "shareLink": "https://app.pesacrow.top/join/ESC-KE-584930"
  }
}
```
''',
    'Initiate STK Push': '''
# Initiate Payment (STK Push)

Triggers the M-Pesa PIN prompt on the buyer's phone.

**Method & Path**: `POST /payments/initiate-stk`

### Headers
| Header | Required | Description |
| :--- | :--- | :--- |
| `x-api-key` | Yes | Your Platform API Key |

### Request Body
| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `transactionId` | String | Yes | ID from Create Deal |
| `buyerPhone` | String | Yes | Buyer's Safaricom number |

### Success Response (200 OK)
```json
{
  "success": true,
  "message": "Payment prompt sent to 254799XXXX66. Please check your phone."
}
```
''',
    'Poll Status': '''
# Public Deal Status (Polling)

Safely poll deal status from frontend apps without exposing API keys.

**Method & Path**: `GET /open/deals/{transactionId}`

**Headers**: None required.

### Success Response (200 OK)
```json
{
  "success": true,
  "data": {
    "transactionId": "ESC-KE-584930",
    "status": "held",
    "amount": 1500,
    "totalBuyerPays": 1545
  }
}
```
''',
    'Mark Delivered': '''
# Mark as Delivered

Notifies PesaCrow that goods are shipped. Triggers SMS to buyer for approval.

**Method & Path**: `POST /deals/{transactionId}/deliver`

### Headers
| Header | Required | Description |
| :--- | :--- | :--- |
| `x-api-key` | Yes | Your Platform API Key |

### Success Response (200 OK)
```json
{
  "success": true,
  "message": "Deal marked as delivered successfully."
}
```
''',
    'Webhooks': '''
# Webhook Management

Webhooks are crucial for async M-Pesa updates.

### Event Types
*   `deal.status_updated`: Fired whenever a deal moves to `held`, `delivered`, `released`, `failed`, `disputed`, or `refunded`.

### Retry Policy
If your server returns an HTTP code >= 400 or times out (10 seconds), PesaCrow will retry using an exponential backoff strategy (up to 5 attempts over 24 hours).

### Idempotent Processing Advice
Webhook deliveries can occasionally duplicate. Ensure your backend logic is idempotent. Check your DB: `if (order.status === 'paid') return 200 OK;` before attempting to fulfill the order again.

### Signature Verification (Node.js)
```javascript
const crypto = require('crypto');
// ... inside express route
const signature = req.headers['x-pesacrow-signature'];
const expected = crypto.createHmac('sha256', 'sk_your_secret').update(req.body).digest('hex');
if (signature !== expected) return res.status(401).send("Bad Signature");
```
''',
    'Refunds & Disputes': '''
# Refunds & Disputes

### Automated Refunds
**POST `/deals/{transactionId}/refund`** (Headers: `x-api-key`)
If you run out of stock, call this. It reverses funds back to the buyer via M-Pesa B2C. The status changes to `refunded` asynchronously once Safaricom confirms.

### Proof of Delivery & Disputes
If a buyer disputes an order, status becomes `disputed`. You must provide Proof of Delivery via the Dashboard or API.
*   **Accepted Formats**: `.jpg`, `.jpeg`, `.png`, `.webp`, `.heic`
*   **Max Size**: 10MB (Ensure high-resolution waybills are clearly legible).
''',
  }
};
