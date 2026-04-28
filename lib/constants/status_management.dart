final Map<String, Map<String, String>> systemStatusDocs = {
  'Status & Monitoring': {
    'Live API Status': '', // This is a special key that will render the live dashboard widget
    'Monitoring the Status Page': '''
# Monitoring the Status Page

The source of truth for all operational metrics is our public status page:
**🔗 [status.pesacrow.top](https://status.pesacrow.top)**

### Status Indicators
Our status page tracks the health of several core components:

*   **PesaCrow Core API**: The REST endpoints (`/api/deals/*`). If this is degraded, you will experience 500 errors or high latency when creating deals.
*   **M-Pesa STK Push (Daraja)**: Safaricom's ability to trigger PIN prompts on customer phones.
*   **M-Pesa B2C (Payouts/Refunds)**: Safaricom's ability to deposit funds into your merchant account or refund buyers.
*   **Webhook Dispatcher**: Our internal queue that sends `POST` requests to your servers when a deal is paid.
*   **SMS Gateway (Africa's Talking)**: The system that notifies buyers to approve delivery.
''',
  },
  'External Dependencies': {
    'M-Pesa Outages': '''
# Understanding M-Pesa Dependencies

PesaCrow abstracts away much of the complexity of M-Pesa, but we cannot prevent Safaricom maintenance windows. Here is how specific external outages affect your integration:

### Scenario A: M-Pesa STK Push is Down
*   **What happens**: Buyers check out, but their phones never receive the prompt to enter their PIN.
*   **What PesaCrow does**: Our API might return an `MPESA_TIMEOUT` or `503 Service Unavailable` error when you call `/payments/initiate-stk`.
*   **What you should do**: Your frontend should elegantly tell the buyer: *"M-Pesa is currently experiencing delays. Your order is saved. Please try paying again in a few minutes."*

### Scenario B: M-Pesa B2C is Down
*   **What happens**: You deliver goods, the buyer approves, but the money does not immediately hit your M-Pesa account. Or, you trigger a refund, but the buyer doesn't get the money instantly.
*   **What PesaCrow does**: The transaction status remains `approved` (for payouts) or `held` (for refunds). Our system queues the payout.
*   **What you should do**: Do nothing. PesaCrow automatically retries B2C transactions with exponential backoff until Safaricom processes them. Your dashboard will show the disbursement as "Pending."

### Scenario C: M-Pesa Callbacks (Webhooks) are Delayed
*   **What happens**: The buyer enters their PIN and money is deducted, but your system doesn't immediately receive the PesaCrow webhook.
*   **What PesaCrow does**: We are waiting for Safaricom to confirm the payment to us. As soon as they do, we immediately fire the webhook to you.
*   **What you should do**: Ensure your frontend UI has a manual "I have paid, check status" button that polls our public `GET /open/deals/{transactionId}` endpoint. Do not fulfill orders until the webhook fires or the endpoint returns `status: "held"`.
''',
  },
  'Incident Response': {
    'Best Practices': '''
# Best Practices for Incident Handling

To ensure your customers don't lose trust during an outage, implement these engineering best practices:

### 1. Graceful Degradation in the UI
Never show raw API error strings to a customer. If PesaCrow returns a `500 Internal Server Error`, catch it in your frontend and display a user-friendly message:
> *"We're unable to connect to the secure payment gateway at the moment. Please don't worry, your cart is saved. Try again shortly."*

### 2. Rely on Idempotency
If a request times out, you might not know if it succeeded. Because you implemented **Idempotency Keys** (as per the API Guide), you can safely retry the `POST /deals/create` request without fearing you will create two identical deals.

### 3. Handle Webhook Retries Idempotently
If PesaCrow's webhook dispatcher experiences a hiccup, it might send the same `status_updated` event twice. 
Always check your database before acting on a webhook:
```javascript
// Good Practice
const order = await getOrder(event.transactionId);
if (order.paymentStatus === 'paid') {
    return res.status(200).send('Already processed');
}
```
''',
    'Maintenance Windows': '''
# Maintenance Windows

*   **PesaCrow Maintenance**: We aim for zero-downtime deployments. Major upgrades are performed on Sundays between 02:00 AM and 04:00 AM (EAT). We will notify all registered developers via email 7 days in advance if downtime is expected.
*   **Safaricom Maintenance**: Safaricom frequently performs maintenance on weekends late at night. PesaCrow has no control over these windows, but we will reflect them on `status.pesacrow.top` as soon as Safaricom announces them.

*For critical incidents affecting your ability to process payments, please check the status page first. If all systems show as operational but you are experiencing total failure, escalate immediately to emergency-dev@pesacrow.top.*
''',
  }
};
