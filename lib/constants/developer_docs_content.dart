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
    'User Journeys': '''
# PesaCrow: The User Journey

This document details the step-by-step experience for both Buyers and Sellers on the PesaCrow platform, from setup to final disbursement.

---

## 1. The Seller Journey
*The goal: Secure proof of payment before delivery and receive funds through a preferred channel.*

### Phase A: Setup & Onboarding
1.  **OTP Authentication**: Seller logs in using their M-Pesa phone number and a one-time password (OTP).
2.  **Payout Preferences**: The seller configures where they want their earnings to go.
    *   **Options**: Personal Wallet, Pochi La Biashara, Business Paybill, or Till Number.
    *   **Customization**: They can set a `payoutPhone` different from their login number.

### Phase B: Deal Creation
3.  **Initiate Deal**: Seller enters the Buyer's phone number, deal amount, and a description (e.g., "Selling 2021 MacBook Air").
4.  **Review Fees**: Seller sees the exact amount they will receive after PesaCrow fees are deducted.
5.  **Share Deal**: The system sends a unique **Transaction ID** (e.g., `ESC-KE-123456`) to the Buyer via SMS.

### Phase C: Escrow & Delivery
6.  **Escrow Notification**: Once the buyer pays, the seller receives an SMS: *"Funds for deal ESC-KE-123456 are now held in escrow. You can proceed with delivery."*
7.  **Fulfillment**: The seller delivers the product or service.
8.  **Proof of Delivery**: (Optional but Recommended) The seller uploads a photo or delivery note to the platform as evidence.

### Phase D: Get Paid
9.  **Release**: Once the buyer clicks 'Approve', PesaCrow instantly triggers the disbursement.
10. **Receipt**: Seller receives funds in their preferred channel (M-Pesa, Pochi, etc.) and a confirmation SMS with the M-Pesa receipt number.

---

## 2. The Buyer Journey
*The goal: Ensure the product or service is received as described before the money is released.*

### Phase A: Discovery
1.  **Receive Invitation**: The buyer receives an SMS alerting them that a PesaCrow deal has been created for them.
2.  **View Deal**: The buyer logs into the app or visits the deal link to verify the description, price, and seller's reputation.

### Phase B: Secure Payment
3.  **Confirm & Pay**: Buyer clicks "Pay Now".
4.  **STK Push**: A secure M-Pesa prompt appears on the buyer's phone. They enter their PIN to authorize the payment.
5.  **Funds Held**: Buyer receives an immediate confirmation that the funds are safely held in the PesaCrow escrow vault.

### Phase C: Inspection Period
6.  **Inspection**: Once the seller delivers, the buyer has a window of time to verify the item.
7.  **Quality Check**: Is it a MacBook Air? Does it work? Is it the right color?

### Phase D: Finalization or Dispute
8.  **Option 1: Approve**: If satisfied, the buyer clicks **"Approve & Release Funds"**. The transaction is complete.
9.  **Option 2: Dispute**: If the item is faulty, different, or never arrived, the buyer clicks **"Raise Dispute"**.
    *   The funds remain locked in escrow.
    *   An Admin reviews the evidence (chat logs, seller's proof of delivery).
10. **Refund**: If the dispute is settled in the buyer's favor, PesaCrow issues a refund directly to the buyer's wallet.

---

## 3. The Cancellation Flow (Security Feature)

*   **Before Payment**: Either party can cancel the deal. The record is removed from the system.
*   **After Payment**:
    *   If the seller realizes they cannot fulfill the order, they can cancel and trigger an **immediate M-Pesa reversal** back to the buyer.
    *   Once the reversal is confirmed, the deal is cleared from the database to maintain a clean workspace.

---

## 4. Key Security Milestones

| Action | Status | Security Meaning |
| :--- | :--- | :--- |
| **Buyer Pays** | `held` | Funds are "frozen" and cannot be touched by the seller until approval. |
| **Seller Marks Delivered** | `delivered` | The clock starts. Buyer is reminded to check the items. |
| **Buyer Approves** | `released` | The transaction is final. Funds move to the seller. |
| **Admin Ruling** | `refunded` | Funds are returned to the buyer after a failed seller delivery. |
''',
    'Technical Principles': '''
# PesaCrow Escrow System: Core Working Principles

This document explains how the PesaCrow Escrow service functions at both a high strategic level and a low technical level.

---

## 1. High-Level Flow (The "Safe Middleman")

PesaCrow acts as a trusted third party that holds funds during a transaction to ensure both the Buyer and Seller are protected.

1.  **Deal Creation**: One party (Buyer or Seller) initiates a deal specifying the amount and description.
2.  **Payment (Funds Secured)**: The Buyer pays the deal amount plus a transaction fee. The platform holds these funds in a specialized account (Escrow).
3.  **Delivery**: The Seller delivers the goods or services and marks the deal as "Delivered" in the app.
4.  **Acceptance**: The Buyer inspects the goods and approves the deal.
5.  **Disbursement (Payout)**: PesaCrow automatically releases the net funds to the Seller's preferred M-Pesa channel.

---

## 2. Low-Level Technical Lifecycle

### Backend (The "Brain")
Built with Node.js, Express, and MongoDB, the backend enforces the **Escrow State Machine**.

-   **State Machine**: A transaction MUST follow a strict sequence (e.g., you cannot "Release" funds if the status isn't "Approved"). This prevents double-spending or accidental releases.
-   **Daraja API Integration**:
    *   **STK Push (C2B)**: Triggers the M-Pesa prompt on the Buyer's phone.
    *   **B2C / B2B Disbursement**: Automatically pays out to the Seller via the channel of their choice (Wallet, Pochi, Till, or Paybill).
-   **Security Webhooks**: Safaricom notifies our server when a payment is successful. We use **IP Whitelisting** to ensure these notifications actually come from Safaricom.
-   **Dual-Buyer Identity**: Uses both the payer's phone and their authenticated account phone to ensure role-based access control (RBAC).

### Frontend (The "Face")
The client application (Flutter) manages the user journey and provides real-time visibility.

-   **OTP Authentication**: Users log in using a 6-digit code sent to their phone (2FA). There are no passwords to remember.
-   **JWT Session**: A secure token is stored locally to authorize API requests.
-   **Polling & Status Updates**: The app frequently checks the backend for status changes (e.g., "Paid," "Delivered") to update the UI instantly.
-   **FileUploads**: Buyers and Sellers can upload photos/PDFs as "Proof of Delivery" or for "Dispute Resolution."

### Disbursement Routing
When a Buyer approves a deal:
1.  The system checks the Seller's **Payout Preference**.
2.  It calculates the `netPayout` (Amount - 1.5%).
3.  It calls the relevant Daraja API:
    *   `callB2C`: Standard Phone Number.
    *   `callB2Pochi`: Pochi La Biashara.
    *   `businessBuyGoods`: Till Number.
    *   `businessPayBill`: PayBill Shortcode.

---

## 3. Safety Nets & Edge Cases

-   **Disputes**: If the items are not as described, the Buyer can "Raise a Dispute." This freezes the funds and notifies an Admin for manual review.
-   **Auto-Expiry**: If a deal sits in "Delivered" too long without Buyer response, it can be automatically approved (configurable).
-   **Cancellations & Reversals**: Sellers can intentionally cancel a deal at any time before approval. If payment was already made, PesaCrow triggers an asynchronous M-Pesa **Reversal** to return funds to the Buyer.
-   **Late Payments**: If a payment arrives for a deal that was already automatically timed out or cancelled, the system triggers a reversal to ensure funds are not trapped.
''',
    'Going Live': '''
# The "Going Live" Checklist

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
  'Marketplace Models': {
    'Integration Guide': '''
# PesaCrow Marketplace Integration Guide

This guide provides a detailed technical roadmap for developers to integrate PesaCrow's escrow-protected payments into two primary types of market systems: **Decentralized (P2P)** and **Centralized (Platform-Managed)**.

---

## 🚀 The Core Philosophy: "Zero-Friction Checkout"

Before diving into the models, understand our **DevX Optimized Flow**:
1.  **No Login Required**: Buyers don't need to create a PesaCrow account or receive an OTP.
2.  **API-Driven**: Your platform handles the "Deal Creation" via backend API.
3.  **Automatic STK Push**: You trigger the M-Pesa prompt directly on the buyer's phone.
4.  **Real-Time Hooks**: Your platform receives a webhook as soon as payment is secured.

---

## 1. Decentralized Marketplace (P2P Model)
*Perfect for: Classifieds (e.g., Jiji), Freelance Platforms (e.g., Upwork), or P2P Trading.*

### Concept
In this model, your platform acts as a **neutral broker**. You facilitate a transaction between **User A (Buyer)** and **User B (Seller)**. PesaCrow holds the funds in a secure vault and pays the **Seller directly** upon successful delivery.

### Technical Implementation

#### A. Create the Deal
When a buyer clicks "Buy Now" on an item listed by a vendor:
-   **sellerPhone**: The actual phone number of the vendor/seller.
-   **buyerPhone**: The phone number of the customer.

```javascript
// Request to POST /api/deals/create
{
  "sellerPhone": "254711222333", // The Vendor's Number
  "amount": 5000,
  "description": "Purchase: iPhone 12 - Order #9921",
  "buyerPhone": "254799888777"  // The Buyer's Number
}
```

#### B. The Payout Flow
1.  **Payment**: Buyer pays → Funds held by PesaCrow.
2.  **Delivery**: Seller ships item → Marks as `delivered` via your UI.
3.  **Release**: Buyer confirms receipt → **Funds are sent directly to the Seller's M-Pesa**.
4.  **Fee**: PesaCrow automatically deducts the escrow fee before the seller receives the balance.

### Why choose this?
-   **Zero Liability**: Your platform never "touches" the money, reducing regulatory and accounting overhead.
-   **Trust**: Sellers know they are being paid by a trusted third-party escrow.

---

## 2. Centralized Marketplace (Platform-Led Model)
*Perfect for: E-commerce stores (e.g., Jumia), Service Aggregators, or Subscription Boxes.*

### Concept
In this model, your platform is the **Merchant of Record**. The buyer is paying **You (The Platform)**. You use PesaCrow to provide the buyer with a "Money Back Guarantee" while you manage the fulfillment.

### Technical Implementation

#### A. Create the Deal
When a customer checkouts from your store:
-   **sellerPhone**: **Your Platform's registered M-Pesa number**.
-   **buyerPhone**: The customer's phone number.

```javascript
// Request to POST /api/deals/create
{
  "sellerPhone": "254700000111", // YOUR Business Number
  "amount": 2500,
  "description": "Store Order #ABC-123",
  "buyerPhone": "254799888777"
}
```

#### B. The Payout Flow
1.  **Payment**: Buyer pays → Funds held by PesaCrow.
2.  **Fulfillment**: Your warehouse ships the item.
3.  **Release**: Buyer confirms → **Funds are sent to your Business Wallet/Number**.
4.  **Redistribution**: You then handle payments to your logistics partners or suppliers internally.

---

## 🛠 Integration Steps (Step-by-Step)

### Step 1: Initialize the Transaction
Call the `create` endpoint from your backend. Store the `transactionId` in your database.

```bash
curl -X POST https://api.pesacrow.top/api/deals/create \\
  -H "x-api-key: YOUR_PLATFORM_KEY" \\
  -H "Content-Type: application/json" \\
  -d '{
    "sellerPhone": "2547XXXXXXXX",
    "amount": 1000,
    "description": "Order #1",
    "buyerPhone": "2547YYYYYYYY"
  }'
```

### Step 2: Trigger the Payment Prompt
Use the `transactionId` to trigger an STK Push on the buyer's phone immediately.

```bash
curl -X POST https://api.pesacrow.top/api/payments/initiate-stk \\
  -d '{
    "transactionId": "ESC-KE-XXXXX",
    "buyerPhone": "2547YYYYYYYY"
  }'
```

### Step 3: Instant Release (Approval)
If the buyer confirms receipt on **your platform's UI**, you can instantly trigger the payout to the seller without requiring the buyer to log into PesaCrow.

```bash
curl -X POST https://api.pesacrow.top/api/open/deals/ESC-KE-XXXXX/release \\
  -H "x-api-key: YOUR_PLATFORM_KEY"
```

### Step 4: Listen for the Webhook
Configure a Webhook URL in your PesaCrow dashboard. We will notify you when the status changes to `held` or `released`.

```json
// Incoming Webhook from PesaCrow
{
  "event": "deal.status_updated",
  "data": {
    "transactionId": "ESC-KE-XXXXX",
    "newStatus": "held", // Money is now SECURED
    "mpesaReceipt": "RQK8XXXXXX"
  }
}
```

---

## ⚖️ Comparison Matrix

| Feature | Decentralized (P2P) | Centralized (Platform) |
| :--- | :--- | :--- |
| **Recipient of Funds** | The Individual Seller | Your Platform Account |
| **Accounting** | Handled by PesaCrow | Managed by Your Platform |
| **Compliance** | Seller is responsible | Platform is responsible |
| **User Experience** | Transparent P2P trust | Traditional E-commerce feel |
| **Best For** | Jiji, OLX, AirBnB | Shopify Stores, Jumia, Uber |

---

## 🔐 Security Best Practices
1.  **Never expose API Keys**: Always call the `create` endpoint from your server-side code.
2.  **Verify Webhooks**: Always check the transaction status via `GET /api/open/deals/{id}` if you want to be 100% sure the webhook was genuine.
3.  **Idempotency**: Use an `Idempotency-Key` header when creating deals to prevent double-charging if a user clicks "Checkout" twice.
4.  **Platform Release**: Only use the `/release` endpoint if you have verified delivery/satisfaction on your end. This action is irreversible.

---

## 🛠 Advanced Platform Actions

### D. Mark as Delivered (Shop Action)
**Endpoint**: `POST /api/deals/{transactionId}/deliver`  
**Auth**: **API Key Required**  
**Purpose**: Signals that the item has been shipped. This notifies the buyer to approve the release of funds.

---

### E. Approve Release (Platform on behalf of Buyer)
**Endpoint**: `POST /api/deals/{transactionId}/approve`  
**Auth**: **API Key Required**  
**Purpose**: Signals that the buyer has received the item and is satisfied. This triggers the immediate release of funds to the seller. 
*Note: Use this if the buyer confirms receipt on your own platform's UI.*

---

### F. Cancel Deal
**Endpoint**: `POST /api/deals/{transactionId}/cancel`  
**Auth**: **API Key Required**  
**Purpose**: Cancels an unpaid deal or initiates a reversal/refund for a paid deal.

---

> [!TIP]
> **Pro Tip**: Use the `/api/open/deals/{transactionId}` endpoint to build a "Track My Escrow" widget on your own frontend. It requires zero authentication and provides a safe, anonymized view of the transaction progress.
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
    'Fee Calculation': '''
# Fee Calculation

Dynamically calculate the escrow fee before creating a deal.

**Method & Path**: `GET /api/fees/calculate`

### Query Parameters
| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `amount` | Number | Yes | The transaction amount. |

### Success Response (200 OK)
```json
{
  "success": true,
  "data": {
    "amount": 1500,
    "escrowFee": 45,
    "safaricomCharge": 12,
    "totalBuyerPays": 1557
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
    'Error Documentation': '''
# PesaCrow Open Integration: Error Documentation

This document lists the possible error codes, their meanings, and how to resolve them when using the PesaCrow Open Integration APIs.

---

## 🛑 Global Error Format
All errors follow this standard structure:

```json
{
  "success": false,
  "statusCode": 400,
  "message": "Human-readable explanation",
  "errorCode": "MACHINE_READABLE_CODE",
  "metadata": {
    "timestamp": "2026-05-13T11:24:20.000Z",
    "requestId": "unique-request-id",
    "path": "/api/open/deals"
  }
}
```

---

## 1. Authentication Errors

| Error Code | Status | Meaning | Solution |
| :--- | :--- | :--- | :--- |
| `INVALID_API_KEY` | 401 | The `x-api-key` header is missing, incorrect, or the platform is inactive. | Double-check your API key in the PesaCrow Dashboard. |
| `UNAUTHORIZED` | 401 | You attempted to access a platform-only endpoint without an API key. | Ensure you are sending the `x-api-key` header. |
| `UNAUTHORIZED` | 403 | You attempted to manage a deal that was not created by your platform. | Ensure the `transactionId` belongs to your platform. |

---

## 2. Validation Errors

| Error Code | Status | Meaning | Solution |
| :--- | :--- | :--- | :--- |
| `VALIDATION_ERROR` | 400 | One or more input fields failed validation. | Check the `details` field for a list of failing parameters. |
| `INVALID_PHONE` | 400 | The phone number provided (seller or buyer) is not a valid Kenyan number. | Use the format `2547XXXXXXXX` or `07XXXXXXXX`. |
| `TRANSACTION_RESTRICTED`| 403 | One of the phone numbers is on the global PesaCrow blacklist. | This transaction cannot be processed due to safety restrictions. |

---

## 3. Transactional Errors

| Error Code | Status | Meaning | Solution |
| :--- | :--- | :--- | :--- |
| `DEAL_NOT_FOUND` | 404 | The `transactionId` provided does not exist. | Verify the ID. Remember they usually start with `ESC-KE-`. |
| `INVALID_STATE` | 409 | The transaction is not in a state that allows the requested action. | For example, you cannot `release` a deal that is still `pending_payment`. |
| `INVALID_STATE` | 409 | Attempting to pay for or release a deal that has already been completed. | Check the current status via the `GET` endpoint. |

---

## 4. System Errors

| Error Code | Status | Meaning | Solution |
| :--- | :--- | :--- | :--- |
| `INTERNAL_SERVER_ERROR` | 500 | An unexpected error occurred on the PesaCrow server. | Try again later or contact PesaCrow support if the issue persists. |
| `REVERSAL_FAILED` | 400 | An attempt to cancel a paid deal failed at the M-Pesa level. | Contact support to handle the refund manually. |

---

## 🛠 Testing Errors (Integration Script)

You can use the following Node.js snippet to test how your system handles these errors:

```javascript
const axios = require('axios');

const BASE_URL = 'https://api.pesacrow.top/api';
const API_KEY = 'pc_your_key_here';

async function testError(name, call) {
    try {
        console.log(`Testing: \${name}...`);
        await call();
        console.log("❌ Expected error but got success.");
    } catch (err) {
        console.log(`✅ Received Expected Error [\${err.response?.data?.errorCode}]: \${err.response?.data?.message}`);
    }
}

async function runTests() {
    // 1. Test Invalid API Key
    await testError('Invalid API Key', () => 
        axios.post(`\${BASE_URL}/open/deals`, {}, { headers: { 'x-api-key': 'fake_key' } })
    );

    // 2. Test Minimum Amount Validation
    await testError('Amount too low', () => 
        axios.post(`\${BASE_URL}/open/deals`, { amount: 5 }, { headers: { 'x-api-key': API_KEY } })
    );

    // 3. Test Invalid Transaction ID
    await testError('Non-existent Deal', () => 
        axios.get(`\${BASE_URL}/open/deals/ESC-KE-INVALID`)
    );

    // 4. Test Release Unpaid Deal
    await testError('Release Unpaid Deal', () => 
        axios.post(`\${BASE_URL}/open/deals/ESC-KE-EXISTING/release`, {}, { headers: { 'x-api-key': API_KEY } })
    );
}

runTests();
```
''',
  },
  'Financials & Fees': {
    'Fee Model': '''
# PesaCrow Fee Model

This document explains the fee model used in the PesaCrow platform in detail. The fee logic is primarily implemented in `src/services/transactionService.js` and configurable via the `FeeConfig` database schema.

## Overview

The PesaCrow fee model is designed to be fair, tiered, and covers both platform administration and Safaricom's M-Pesa transaction costs (Bouquet charges). Fees are distributed between the Buyer (who pays an upfront fee to create the escrow) and the Seller (who pays a release fee upon successful payout).

### Key Entities
*   **Transaction Amount:** The principal amount being held in escrow for the deal.
*   **Buyer:** The user initiating the transaction and funding the escrow.
*   **Seller:** The user providing the goods/services and receiving the funds.
*   **Platform (PesaCrow):** The escrow service provider.

---

## 1. Zero-Fee Threshold

**Transactions below KSh 100 incur no fees.**
*   Buyer pays exactly the transaction amount.
*   Seller receives exactly the transaction amount.
*   Platform covers any negligible M-Pesa costs.

---

## 2. Core Fee Components

For transactions of KSh 100 or more, the system applies several fee components:

### A. Volume-Based Tiers
The platform scales its percentage fees based on the transaction amount to incentivize larger deals.
*   **Tier 1 (KSh 100 - KSh 10,000):** Defaults to base rates.
*   **Tier 2 (KSh 10,001 - KSh 50,000):** Transaction Fee = 1.8%, Release Fee = 1.2%
*   **Tier 3 (KSh 50,001 and above):** Transaction Fee = 1.5%, Release Fee = 1.0%

### B. Transaction Fee (Paid by Buyer)
Charged upfront when the Buyer deposits funds into the escrow account.
*   **Calculation:** `Transaction Amount * Tiered Percentage`
*   **Minimum Floor:** KSh 20 (Ensures basic platform cover for small values).

### C. Release Fee (Paid by Seller)
Deducted from the principal amount before disbursing to the Seller upon successful completion of the deal.
*   **Calculation:** `Transaction Amount * Tiered Percentage`
*   **Minimum Floor:** KSh 10.

### D. Safaricom Business Bouquet Charge
Since PesaCrow uses Safaricom Paybill (Customer Pays) or similar mechanisms, Safaricom imposes standard B2C/C2B charges. This charge is passed to the Buyer upfront.
*   **Schedule (Examples):**
    *   <= 500: KSh 5
    *   <= 1000: KSh 12
    *   <= 5000: KSh 34
    *   > 50000: KSh 210 (Max)
*   **Bouquet Revenue Share:** PesaCrow retains a configuration percentage (default 50%) of this bouquet charge as additional platform revenue.

---

## 3. Circumstantial Fees

### A. Holding Fee (Applied on Refunds)
If a deal is canceled or heavily disputed resulting in a refund back to the Buyer, a Holding Fee is deducted from the refund amount.
*   **Calculation:** `(Transaction Amount * 0.5%) + KSh 50 (Flat Admin Overhead)`
*   This covers the M-Pesa B2C payout cost for returning the money and administrative overhead.

### B. Inactivity Fee (Late Approval Penalty)
To prevent Sellers from having funds locked indefinitely while waiting for Buyer approval, an inactivity penalty is levied on the transaction if the Buyer delays approval beyond a grace period.
*   **Grace Period:** 7 days after the deal is marked "delivered".
*   **Penalty Rate:** 0.1% of the deal amount per week of delay.
*   **Deducted From:** The final payout to the Seller.

### C. Dispute Fee
Configured for manual resolutions that require admin intervention.
*   **Default Flat Fee:** KSh 500 (Configurable, with a KSh 2000 cap).

---

## 4. Financial Flow Breakdown

### Upon Deposit (Buyer Pays)
The Buyer is required to pay:
`Total Buyer Pays = Transaction Amount + Safaricom Bouquet Charge + Platform Transaction Fee`

### Escrow Storage (Held Amount)
The system securely holds exactly the `Transaction Amount`. The upfront fees (Safaricom + Platform Transaction Fee) are immediately registered as earned revenue/expenses.

### Upon Release (Seller Receives)
When the deal is approved, the Seller receives the held amount minus their release fee:
`Amount to Seller = Transaction Amount - Release Fee - (Inactivity Fee, if applicable)`

### Platform Profit
On a successful transaction, PesaCrow's gross margin is:
`Platform Profit = Transaction Fee + Release Fee + Bouquet Revenue Share`

## 5. Administrative Controls

All fee parameters mentioned above are dynamic. They can be modified by the Administrator via the `FeeConfig` document in the database, allowing the platform to adjust pricing models on the fly without code deployments.
''',
  },
  'Legal & FAQ': {
    'Terms & Conditions': '''
# PesaCrow: Terms and Conditions & FAQ

This document contains the official Terms and Conditions and Frequently Asked Questions (FAQ) for PesaCrow, a digital escrow service integrated with M-Pesa.

---

## Terms and Conditions

### 1. Parties Involved
This Agreement is entered into between:
*   **The Escrow Agent**: PesaCrow (operated by A3s(Absolute Advanced Anonymity Services)), a digital platform providing neutral holding and disbursement services.
*   **The Buyer**: Any natural or legal person utilizing PesaCrow to secure a purchase of goods or services.
*   **The Seller**: Any natural or legal person utilized PesaCrow to secure payment for the provision of goods or services.
*   **Participating Financial Institutions**: Specifically Safaricom M-Pesa, which acts as the underlying payment rail for fund collection and disbursement.

### 2. Definitions
*   **"Escrow Account"**: The digital wallet or platform-managed record where funds are held until conditions are met.
*   **"Escrowed Funds"**: The specific monetary amount (KES) deposited by the Buyer for a transaction.
*   **"Disbursement"**: The act of releasing funds from the Escrow Account to the Seller or Buyer.
*   **"Inspection Period"**: The timeframe agreed upon for the Buyer to verify the quality of goods/services.
*   **"Business Day"**: Any day excluding weekends and public holidays in Kenya.
*   **"Deal ID"**: The unique transaction identifier generated by the PesaCrow platform.

### 3. Appointment of the Escrow Agent
The Buyer and Seller hereby formally appoint PesaCrow as their neutral Escrow Agent. PesaCrow accepts this appointment and agrees to act solely as a facilitator in accordance with the automated logic of the platform and these terms. PesaCrow remains independent and does not represent either party in the underlying commerce.

### 4. Description of the Escrowed Property
PesaCrow facilitates the escrow of **Kenyan Shillings (KES)**. 
*   **Deposits**: Must be made exclusively via the Buyer’s registered M-Pesa number through the PesaCrow STK Push prompt.
*   **Limits**: Minimum and maximum transaction limits apply as dictated by Safaricom M-Pesa regulations and PesaCrow internal policies.

### 5. Release / Disbursement Conditions
Funds are released from the Escrow Account under the following conditions:
1.  **Mutual Approval**: The Buyer confirms receipt and satisfaction of the goods/services through the platform, triggering an immediate release.
2.  **Seller Proof of Delivery**: In specific cases where proof of delivery is undisputed and the inspection period expires without a claim.
3.  **Dispute Resolution**: Upon a final decision by a PesaCrow Admin or an arbitrator in a disputed case.
4.  **Automatic Expiry**: If a deal is cancelled or fails to be approved within the platform's defined timeout periods, funds may be returned to the Buyer (less applicable fees).

### 6. Fees and Expenses
PesaCrow charges for its services to ensure platform stability and security.
*   **Service Fees**: Calculated as a combination of a fixed percentage and a flat transaction fee (refer to the "Fee Calculator" in-app).
*   **Payment Rails**: Standard M-Pesa transaction costs apply for sending and receiving via the platform.
*   **Deduction**: Fees are automatically deducted at the point of release or during the initial deposit as specified in the transaction breakdown.

### 7. Duties and Responsibilities of the Escrow Agent
*   **Neutrality**: PesaCrow will act as a neutral third party and will not favor one party over another.
*   **Reporting**: PesaCrow provides a digital ledger of all transaction statuses within the platform dashboard.
*   **Limitations**: PesaCrow is responsible only for the safekeeping of funds and their disbursement according to user instructions; it does not warrant the quality, legality, or suitability of the underlying goods.

### 8. Liability and Limitations of Liability
PesaCrow is not liable for:
*   Disputes arising from the quality of goods or services provided by the Seller.
*   Losses due to network failures, Safaricom M-Pesa outages, or incorrect phone number entry by the user.
*   Indirect, incidental, or consequential damages.
*   **Indemnification**: Users agree to indemnify PesaCrow against all claims arising from their use of the platform in violation of these terms.

### 9. Dispute Resolution
In the event of a disagreement:
*   **Mediation**: The parties are encouraged to resolve the issue directly through the platform's "Dispute" feature.
*   **Escalation**: If unresolved after 48 hours, either party may escalate the deal to "Dispute" status.
*   **Admin Decision**: PesaCrow Admins will review the evidence (proof of delivery, communication logs) and issue a binding decision.
*   **Legal Action**: This Agreement is governed by the laws of the Republic of Kenya.

### 10. Termination of Escrow
The escrow relationship terminates when:
*   Funds are fully disbursed to the Seller.
*   Funds are returned to the Buyer.
*   The deal is cancelled by mutual agreement before the Seller has delivered.

### 11. Interest / Investment of Funds
Escrowed funds held by PesaCrow do **not** earn interest for the Buyer or Seller. PesaCrow does not invest escrowed funds in high-risk assets.

### 12. Representations and Warranties
Users represent that:
*   They have the legal capacity to enter this agreement.
*   The funds used are from legitimate sources.
*   The transaction does not involve illegal goods (e.g., drugs, weapons, or counterfeit items).

### 13. Compliance and Regulatory Clauses
PesaCrow adheres to **Anti-Money Laundering (AML)** and **Know Your Customer (KYC)** regulations. We reserve the right to flag and freeze transactions suspected of fraud or illegal activity and report them to relevant Kenyan authorities.

### 14. General Provisions
*   **Entire Agreement**: These terms constitute the full agreement between the parties.
*   **Amendments**: Terms may be updated periodically; continued use of the platform constitutes acceptance.
*   **Force Majeure**: PesaCrow is not liable for delays caused by "Acts of God," pandemics, or civil unrest.

### 15. Miscellaneous
PesaCrow maintains no interest in the underlying transaction beyond the collection of service fees. Certain clauses, including Liability and Indemnification, survive the termination of this Agreement.

---

## Frequently Asked Questions (FAQ)

### What is PesaCrow?
PesaCrow is a digital escrow platform that secures your payments when buying or selling with strangers. We hold the buyer's money until they confirm they've received the item, then we release it to the seller.  

**Trusting them so you don't have to.**

### How do I pay for a deal?
Once a deal is created, the Buyer will receive an sms from  M-Pesa STK Push on their phone. Simply enter your M-Pesa PIN, and the funds will be securely moved to the PesaCrow escrow account.

### When does the Seller get paid?
The Seller is paid immediately after the Buyer approves the deal on the PesaCrow platform. If the Buyer is happy with the product, they click "Approve," and the funds are sent to the Seller's M-Pesa wallet.

### What happens if I don't receive my item?
If the Seller fails to deliver, the Buyer can raise a dispute. Our team will investigate, and if the Seller cannot provide proof of delivery, the funds will be returned to the Buyer.

### What are the fees?
PesaCrow charges a small service fee to cover the security and infrastructure costs. You can use our "Fee Calculator" within the app to see the exact breakdown before starting a deal.

### Can I cancel a deal?
Yes, a deal can be cancelled by the Seller if they haven't started delivery, or by mutual agreement. 

If a deal is cancelled before delivery or disbursement, the escrowed funds are **refunded to the Buyer fully** (minus any applicable transaction fees). 

Once funds are in escrow, they can only be released through Buyer Approval, valid Proof of Delivery, or the official Dispute Resolution process.

### Is PesaCrow safe?
Yes. PesaCrow uses industry-standard encryption and adheres to Kenyan financial regulations. Funds are held securely, and disbursement is automated based on your authorization.
''',
    'Privacy Policy': '''
# PesaCrow Privacy Policy

**Effective Date:** April 2026

## 1. Introduction

Welcome to **PesaCrow** ("we", "our", or "us"), operated by A3s (Absolute Advanced Anonymity Services). We respect your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you visit our platform or use our digital escrow services.

## 2. Information We Collect

To provide our digital escrow services effectively, we collect the following types of information:

*   **Personal Identification Information:** Phone number (M-Pesa registered number).

*   **Transaction Information:** Details regarding the deals you create or participate in, including Deal IDs, amounts, item descriptions, and M-Pesa transaction references.
*   **Communication Data:** Dispute evidence, or other communications made through the platform between Buyers, Sellers, and PesaCrow Admins.


## 3. How We Use Your Information

We use the collected information for the following purposes:

*   **Service Delivery:** To facilitate and manage escrow transactions, process M-Pesa deposits and disbursements, and update transaction statuses.
*   **Dispute Resolution:** To provide evidence to our Admins in the event of a dispute, allowing for fair and accurate resolutions.
*   **Security and Compliance:** To verify your identity, prevent fraud, monitor for unauthorized activities, and comply with Anti-Money Laundering (AML) and Know Your Customer (KYC) regulations in Kenya.
*   **Communication:** To send you transactional notifications (e.g., SMS alerts regarding M-Pesa STK pushes, deal approvals, and cancellations) and respond to your customer service inquiries.

## 4. Information Sharing and Disclosure

We do not sell your personal data. We may share your information only in the following circumstances:

*   **With the Other Party in a Deal:** We share necessary information (e.g., phone number, transaction details) with the Buyer or Seller you are transacting with to facilitate the deal.
*   **Service Providers:** We share data with trusted third-party service providers, primarily **Safaricom (M-Pesa)**, specifically for processing payments and disbursements.
*   **Legal Obligations:** We may disclose your information to law enforcement or regulatory authorities if required by Kenyan law, or to protect the rights, property, and safety of PesaCrow and our users.

## 5. Data Security

We implement industry-standard administrative, technical, and physical security measures to protect your personal information. Our platform uses encryption and secure protocols to safeguard sensitive data, especially regarding payment rails and personal identifiers. However, no electronic transmission over the internet or information storage technology can be guaranteed to be 100% secure.

## 6. Data Retention

We retain your personal information only for as long as is necessary to fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required or permitted by law (such as for tax, legal, or accounting purposes).

## 7. Your Privacy Rights

Depending on the applicable data protection laws in Kenya, you may have the right to:

*   Request access to the personal data we hold about you.
*   Request correction of inaccurate or incomplete data.
*   Request deletion of your personal data (subject to legal and regulatory restrictions regarding financial transactions).
*   Object to or restrict our processing of your data.

To exercise any of these rights, please contact our support team.

## 8. Changes to This Privacy Policy

We may update this Privacy Policy from time to time to reflect changes in our practices or relevant laws. We encourage you to review this page periodically for the latest information on our privacy practices.

## 9. Contact Us

If you have any questions or concerns about this Privacy Policy or our data practices, please contact us at support@pesacrow.top.
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
