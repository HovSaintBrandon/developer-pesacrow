# PesaCrow Developer Portal: Comprehensive Documentation

Welcome to the unified documentation for the PesaCrow Escrow Platform. This document consolidates all technical guides, API references, and integration protocols required to build secure digital commerce experiences using PesaCrow.

---

## Table of Contents
1. [Getting Started](#getting-started)
   - [Overview](#overview)
   - [Integration Approaches](#integration-approaches)
   - [Authentication & Security](#authentication--security)
   - [Going Live Checklist](#going-live-checklist)
2. [KYC Verification Guide](#kyc-verification-implementation-guide)
   - [Manual Entry Flow](#the-manual-flow-state-machine)
   - [OCR Automated Flow](#the-ocr-flow-one-click)
3. [SDK & Tools](#sdk--tools)
   - [JS SDK (Web)](#js-sdk-web)
   - [Mobile Integrations](#mobile-integrations)
   - [Postman Collection](#postman-collection)
4. [API Reference](#api-reference)
   - [Create Deal](#create-deal)
   - [Initiate STK Push](#initiate-stk-push)
   - [Poll Status](#poll-status)
   - [Mark Delivered](#mark-delivered)
   - [Webhooks](#webhooks)
   - [Refunds & Disputes](#refunds--disputes)
5. [API v0.1.0 (Global Schema)](#api-v010-global-schema)
   - [Response Schema](#response-schema)
   - [Open Integration Endpoints](#open-integration-endpoints)
   - [Decentralized UX](#decentralized-ux)
   - [Webhooks & Best Practices](#webhooks--best-practices)

---

## 1. Getting Started

### Overview
PesaCrow provides **"Trust-as-a-Service."** We act as an impartial digital middleman to solve the lack of trust in digital commerce.

**The Core Problem:**
- **Buyers** fear being scammed.
- **Sellers** fear non-payment or fake screenshots.

**The Solution:**
1. **Agreement:** Buyer checks out on your website.
2. **Secure Payment:** Buyer pays via M-Pesa prompt. Funds are held by PesaCrow.
3. **Delivery:** Seller ships the item confidently.
4. **Release:** Buyer approves release; PesaCrow deposits funds to the seller.

### Integration Approaches
- **Drop-In UI (JS SDK):** Easiest for websites. Adds a pre-built modal.
- **Custom API:** Full control for mobile apps (Flutter/React Native) or custom flows.

**Environments:**
- **Sandbox:** `sandbox-api.escrow.pesacrow.top` (Simulated payments, no real money).
- **Production:** `api.escrow.pesacrow.top` (Real money, real PIN prompts).

### Authentication & Security
Register as a Platform Partner to obtain:
1. **API Key (`apiKey`):** Prefix `pk_`, used in `x-api-key` header.
2. **API Secret (`apiSecret`):** Prefix `sk_`, used strictly for webhook verification.

**Critical Requirements:**
- **Idempotency Keys:** Use `Idempotency-Key` header to prevent double charges.
- **Webhook Signatures:** Verify `x-pesacrow-signature` using your `API_SECRET`.
- **HTTPS:** All webhooks must use secure `https://` endpoints.

### Going Live Checklist
- [ ] **KYC Compliance:** Complete the mandatory KRA-integrated verification (Manual or OCR).
- [ ] **Payout Configuration:** Verify primary merchant phone number.
- [ ] **Environment Switch:** Change Base URLs from sandbox to production.
- [ ] **Swap API Keys:** Replace sandbox keys with live production keys.
- [ ] **Signature Verification:** Ensure webhook verification is active.
- [ ] **End-to-End Live Test:** Perform a real KSh 100 transaction.

---

## 2. KYC Verification Implementation Guide

This guide is for frontend developers to implement the state-driven UI for merchant verification.

### 1. Selection UI
Allow the developer to choose their preferred verification method:
- **Option A: Manual Entry** (Reliable, requires typing).
- **Option B: Scan Documents** (Fast, automated extraction).

### 2. The Manual Flow (State Machine)
Implement this as a 3-step wizard to prevent API errors.

**Step 1: Initiation**
- **UI:** Fields for `idNumber` and `taxpayerType`.
- **Action:** `POST /kyc/check-id` (Payload: `{ "idNumber": "12345678", "taxpayerType": "KE" }`)
- **Handling:** If success, move to Step 2. If failure, show an error message.

**Step 2: Name Verification**
- **UI:** Field for `names` (labeled "Enter names exactly as they appear on your ID").
- **Action:** `POST /kyc/validate-names`
- **Tip:** Inform the user that the order of names doesn't matter (e.g., "Middle Last First" is fine).

**Step 3: PIN Verification**
- **UI:** Field for `kraPin`.
- **Action:** `POST /kyc/validate-pin`
- **Handling:** On success, show a "Go-Live Request Submitted" success screen.

### 3. The OCR Flow (One-Click)
A simpler UI that handles all heavy lifting in one request.

- **UI Requirements:**
  - Two file upload slots: National ID (Front) and KRA PIN Certificate.
  - Optional slot: National ID (Back).
- **Action:** `POST /kyc/ocr-upload`
- **Request Type:** `multipart/form-data`
- **Handling:**
  - Show a loading spinner with text: "Extracting data and verifying with KRA..."
  - **Error Handling:** If OCR fails (e.g., "Could not extract PIN"), fallback to the Manual Flow automatically.

### 4. API Integration Details

| Endpoint | Method | Required Headers | Payload Notes |
| :--- | :--- | :--- | :--- |
| `/kyc/check-id` | `POST` | `Authorization: Bearer {{token}}` | JSON body |
| `/kyc/ocr-upload` | `POST` | `Authorization: Bearer {{token}}` | `FormData` with files |

### 5. Final Step: Platform Details
Once the KYC status is marked as `success`, the UI should transition to the final platform configuration form.

**UI Fields:**
- **Platform Name:** (e.g., "ElectroHub Marketplace")
- **Platform Email:** (e.g., "dev@electrohub.co.ke")
- **Support Phone:** (e.g., "254712345678")
- **Webhook URL:** (e.g., "https://api.electrohub.co.ke/webhooks/pesacrow")

**Final Submission:**
- **Endpoint:** `POST /api/platforms/request-go-live`
- **Payload:**
```json
{
  "name": "ElectroHub Marketplace",
  "email": "dev@electrohub.co.ke",
  "platformPhone": "254712345678",
  "webhookUrl": "https://api.electrohub.co.ke/webhooks/pesacrow"
}
```

### 6. Developer Portal UX Tips
- **Instructional Tooltips:** Add a tooltip explaining the verification process and how data is matched with KRA.
- **Anonymization Feedback:** After success, show status as "Verified" but display PIN/Name masked (e.g., `A*******Z`) to confirm data protection.
- **Sequential Flow:** Ensure the user cannot access the Platform Details form until the KYC state is `success`.
- **Persistence:** On return, check current status via the user profile API to resume from the last completed step (KYC or Platform Setup).

**Summary for the Developer:**
> "Implement a sequential wizard: **OTP Verification** → **KYC Verification** (Manual/OCR) → **Platform Details**. Only after the KYC endpoints return success should the user be allowed to submit the final platform configuration to `/api/platforms/request-go-live`."

---

## 3. SDK & Tools

### JS SDK (Web)
Include the script and launch the payment modal:
```html
<script src="https://api.escrow.pesacrow.top/pesacrow.js"></script>
<script>
    PesaCrow.pay(transactionId, {
        onSuccess: () => alert('Paid!'),
        onError: (err) => console.error(err)
    });
</script>
```

### Mobile Integrations
For Flutter/React Native:
1. Backend creates deal via `POST /deals/create`.
2. App triggers STK push via `POST /payments/initiate-stk`.
3. App polls `GET /open/deals/{transactionId}` for status updates.

### Postman Collection
[Download] **[PesaCrow Open Integration Postman Collection](https://github.com/user-attachments/files/27161248/PesaCrow_Open_Integration_Collection.json)**

---

## 4. API Reference

### Create Deal
`POST /deals/create`
- **Headers:** `x-api-key`, `Idempotency-Key`
- **Required Body:** `sellerPhone`, `amount`, `description`
- **Response:** Returns `transactionId` and `totalBuyerPays`.

### Initiate STK Push
`POST /payments/initiate-stk`
- **Required Body:** `transactionId`, `buyerPhone`
- **Response:** Triggers Safaricom PIN prompt on user's phone.

### Poll Status
`GET /open/deals/{transactionId}`
- **Response:** Returns current status (e.g., `held`, `delivered`, `released`).

### Mark Delivered
`POST /deals/{transactionId}/deliver`
- **Action:** Notifies buyer to approve fund release.

### Webhooks
Listen for `deal.status_updated` events.
- **Retry Policy:** Exponential backoff up to 5 attempts.
- **Verification:** HMAC SHA256 using `apiSecret`.

---

## 5. API v0.1.0 (Global Schema)

### Response Schema
All APIs return:
```json
{
  "success": true,
  "statusCode": 200,
  "message": "...",
  "data": { ... }
}
```

### Open Integration Endpoints
- `POST /api/open/deals`: Create managed deals.
- `POST /api/payments/initiate-stk`: Trigger payment.
- `GET /api/open/deals/:transactionId`: Public lookup.
- `POST /api/deals/:transactionId/refund`: Initiate reversal.

### Best Practices
1. **Use `externalId`:** Map PesaCrow deals to your internal Order IDs.
2. **Listen to Webhooks:** Don't rely solely on polling.
3. **Handle Rate Limits:** Gracefully manage `429 Too Many Requests`.

---
*Documentation generated for PesaCrow Developer Portal.*
