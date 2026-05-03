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

### 🛑 Important: 403 Forbidden on Simulation
If you attempt to call `POST /api/sandbox/simulate-payment` on the **Production API**, you will receive a `403 Forbidden` error.

**The Reason**:
The "Simulate Payment" tool is strictly for development. Allowing it in production would allow anyone to "fake" a payment and trigger real fund releases.

**How to test in Production**:
To test the flow in live production, you must perform a real M-Pesa transaction:
1.  Create a small test deal (e.g., KSh 20).
2.  Call `POST /api/payments/initiate-stk`.
3.  Enter your M-Pesa PIN on your phone.
4.  Wait for the webhook to update the status to `held`.

*Note: If you are running a local testing server, ensure `NODE_ENV=development` is set in your `.env` for the simulator to function.*

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

---

## 🛠️ Postman & Troubleshooting

### 1. The Authorization Header Conflict
If you are testing via Postman, ensure you do not use the built-in "Basic Auth" or "Bearer Token" types in the **Authorization** tab.

*   **The Issue**: Postman's "Basic Auth" generates a standard `Authorization` header. However, PesaCrow strictly expects your API key in a custom header called `x-api-key`.
*   **The Fix**:
    1.  Go to the **Authorization** tab in Postman.
    2.  Change Auth Type to **No Auth**.
    3.  Go to the **Headers** tab.
    4.  Manually add a header: `x-api-key` with your valid key value.

### 2. Environment Variables
If you receive an `Invalid or inactive API key` error:
*   Ensure the variable value matches exactly what was generated in your Admin Dashboard.
*   Verify that your platform status is `isActive: true`.

### 3. Implementation Note: Managed Platforms
The `createOpenDeal` endpoint strictly requires a valid platform identity via the `x-api-key`. For a "Managed Platform" flow (where the platform initiates the escrow), this strict check ensures security and correct fee attribution.
''',
    'Going Live': '''
# The "Going Live" Checklist

Transitioning from development to a live, money-moving application requires coordination between the business owner and the lead developer.

## Developer Self-Service (User-Facing)
You can now automate your production request using our self-service endpoint.

*   **Endpoint**: `POST /api/platforms/request-go-live`
*   **Workflow**: Authenticated users can submit their platform details (Name, Email, Phone, Webhook) directly to our team for review.
*   **Validation**: Built-in validation ensures valid Kenyan phone numbers and HTTPS webhook URLs.
*   **Duplicate Prevention**: Users are restricted from submitting multiple pending requests.

Once submitted, our team will review your integration and provide your Production API Key upon approval.

---

## Business Owner Checklist
- [ ] **KYC Verification**: Complete the mandatory KRA-integrated verification (Manual or OCR).
- [ ] **Payout Configuration**: Verify that the primary merchant phone number registered with PesaCrow is correct. This is where your cleared funds will be deposited.
- [ ] **Customer Support Plan**: Ensure your website clearly explains the Escrow process so buyers know why they are paying PesaCrow instead of paying you directly.

## Developer Checklist
- [ ] **Environment Switch**: Change all Base URLs in your code from `sandbox-api...` to `api...`.
- [ ] **Swap API Keys**: Replace your Sandbox `apiKey` and `apiSecret` with your live Production keys.
- [ ] **Signature Verification Active**: Ensure the code that verifies the `x-pesacrow-signature` on incoming webhooks is enabled and strictly enforced.
- [ ] **Error Handling**: Verify that your application gracefully handles `429 Too Many Requests` (Rate Limits) and network timeouts.
- [ ] **End-to-End Live Test**: Perform a live transaction of KSh 100 with a real phone to verify the end-to-end flow, from payment to final payout release.
- [ ] **Request Production API Key**: Once testing is successful, email **support@pesacrow.top** with your **Platform Number** and **Platform Email** to receive your live production credentials.
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
    'Postman Collection': '''
# Postman Collection

Accelerate your integration by importing our official Postman collection. It contains pre-configured requests for all Open Integration and Decentralized API endpoints.

### Download
[Download] **[PesaCrow Open Integration Postman Collection](https://github.com/user-attachments/files/27161248/PesaCrow_Open_Integration_Collection.json)**

### How to use:
1.  Download the `.json` file from the link above.
2.  Open Postman and click **Import**.
3.  Drag and drop the downloaded file.
4.  Configure your **Environment Variables** (e.g., `apiKey`, `baseUrl`) to match your sandbox or production credentials.
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
  },
  'API v0.1.0': {
    'Response Schema': '''
# 1. Global Response Schema
All PesaCrow APIs return a consistent JSON structure.

### Success Response
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Action completed successfully",
  "data": { ... }
}
```

### Error Response
```json
{
  "success": false,
  "statusCode": 401,
  "message": "Invalid or inactive API key.",
  "errorCode": "INVALID_API_KEY",
  "metadata": {
    "timestamp": "2026-04-28T11:00:00Z",
    "path": "/api/open/deals"
  }
}
```

### Common Error Codes
| HTTP | Error Code | Description |
|---|---|---|
| 400 | `VALIDATION_ERROR` | Missing parameters or invalid formats (e.g. invalid phone). |
| 401 | `INVALID_API_KEY` | API key is missing, incorrect, or has been deactivated. |
| 403 | `FORBIDDEN_ROLE` | You are authenticated, but don't own this deal. |
| 404 | `DEAL_NOT_FOUND` | The requested Transaction ID does not exist. |
| 409 | `INVALID_STATE` | Illegal state transition (e.g. marking as delivered before payment). |
| 429 | `RATE_LIMITED` | Too many requests. Wait before trying again. |
''',
    'Open Integration': '''
# 2. Open Integration (For Platforms)
These endpoints are designed for shops, marketplaces, and apps to initiate and track escrow deals using `x-api-key`.

### A. Create a Managed Deal
`POST /api/open/deals`

- **Success (201 Created)**: Deal initialized. Use the `shareLink` to direct the buyer to pay.
- **Error (400)**: Amount below minimum (KSh 20) or invalid phone.
- **Error (403)**: Phone number is blacklisted.

### B. Initiate STK Push
`POST /api/payments/initiate-stk`

- **Success (200 OK)**: Safaricom has accepted the request and sent a prompt to the user.
- **Error (404)**: Deal not found.
- **Error (429)**: STK limit reached for this number (retry in 1 hour).

### C. Public Deal Lookup
`GET /api/open/deals/:transactionId`

- **Success (200 OK)**: Returns anonymized deal data, status, and expiry. Safe for public frontend usage.

### D. Refund Deal
`POST /api/deals/:transactionId/refund`

- **Success (200 OK)**: Reversal initiated via M-Pesa.
- **Error (409)**: Deal is not in a "refundable" state (e.g. already cancelled or released).
''',
    'Decentralized UX': '''
# 3. Decentralized User Experience (For Frontend Apps)
These endpoints allow you to build a "Consumer Hub" where users manage their own deals using **Bearer Tokens (JWT)**.

### A. Unified Deal History
`GET /api/user/deals`

- **Success (200 OK)**: List of deals across **all** platforms associated with the user's phone number.

### B. Action Discovery
`GET /api/deals/:transactionId/actions`

- **Success (200 OK)**: Returns allowed actions based on the current user's role and deal status.
- **Example**: `["approve_funds", "raise_dispute"]`
''',
    'Webhooks & Best Practices': '''
# 4. Webhook Integration
Register a Webhook URL in your Developer Dashboard to receive real-time updates.

### Deal Status Updated
Triggered whenever a deal status changes (e.g., to `held` or `delivered`).

**Success Payload**:
```json
{
  "event": "deal.status_updated",
  "data": {
    "transactionId": "ESC-KE-123456",
    "externalId": "ORDER-998",
    "oldStatus": "pending_payment",
    "newStatus": "held",
    "amount": 1500,
    "mpesaReceipt": "RBC12345XYZ"
  }
}
```

---

# 5. Best Practices
1.  **Use `externalId`**: Always pass your internal Order ID when creating a deal to avoid mapping headaches.
2.  **Listen to Webhooks**: Rely on webhooks for order fulfillment rather than polling.
3.  **Encourage Global Payouts**: Redirect users to PesaCrow to set their preferences; this reduces your liability and ensures they get paid where they want.
'''
  }
};
