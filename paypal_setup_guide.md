# PayPal Integration Setup Guide

This guide walks you through the steps required to configure your real PayPal merchant credentials for the **DTrade Trading Terminal** application.

---

## 🛠️ Step 1: Create a PayPal Developer Account
To use the real PayPal Checkout flow, you must have a developer account to generate API keys:
1. Go to the [PayPal Developer Portal](https://developer.paypal.com/).
2. Log in with your standard PayPal account credentials, or create a new account.

---

## 🔑 Step 2: Generate REST API Credentials
PayPal uses **REST API Apps** to authenticate transactions.
1. In the left navigation menu, click on **Apps & Credentials**.
2. Select the **Sandbox** tab (for testing) or the **Live** tab (for real payments).
3. Click the **Create App** button.
4. Name your application (e.g., `DTrade App`) and click **Create App**.
5. Once created, you will see:
   - **Client ID** (a long string of characters)
   - **Secret** (click *Show* to reveal the secret key)

---

## ⚙️ Step 3: Configure Credentials in DTrade
Open the DTrade codebase and navigate to `lib/core/constants/api_constants.dart`.

Update the PayPal constants with your generated keys:

```dart
// PayPal Integration Configuration
// Set to true to use the PayPal sandbox environment, false for live payments.
static const bool paypalSandboxMode = true; // Set to false when deploying to production

// Replace these with your actual PayPal REST API credentials from https://developer.paypal.com
static const String paypalClientId = 'YOUR_PAYPAL_CLIENT_ID';
static const String paypalSecretKey = 'YOUR_PAYPAL_SECRET_KEY';
```

---

## 🧪 Step 4: Testing in Sandbox Mode
Before going live, keep `paypalSandboxMode` set to `true` and test the transaction:
1. When checking out, select **PayPal / Cards**.
2. Tap the **PROCEED TO PAYPAL** button.
3. The secure PayPal WebView checkout window will open.
4. Log in using a **Sandbox Personal Account** (you can find or create sandbox buyer accounts in the PayPal Developer Dashboard under **Testing Tools > Sandbox Accounts**).
5. Complete the payment.
6. Upon success, the window will automatically close and submit your verification receipt transaction ID (e.g., `PAYID-xxxxxxxxxxxx`) to your Supabase backend for final approval.

---

## 🚀 Step 5: Going Live
When you are ready to accept real payments:
1. Toggle the sandbox mode in `lib/core/constants/api_constants.dart`:
   ```dart
   static const bool paypalSandboxMode = false;
   ```
2. Replace `paypalClientId` and `paypalSecretKey` with your **Live** credentials from the PayPal Developer Portal.
3. Re-build and release your application!
