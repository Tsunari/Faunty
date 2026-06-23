# Faunty OneSignal Push Notification Cloudflare Worker

This is a lightweight, secure proxy to send push notifications via OneSignal without exposing the `ONESIGNAL_REST_API_KEY` in the Flutter PWA client bundle.

## Features
- **100% Free:** Runs on the Cloudflare Workers free tier (up to 100,000 requests per day).
- **Secure:** Holds the REST API key in Cloudflare Secrets instead of the client bundle.
- **Easy Setup:** Can be deployed in under 2 minutes directly from the Cloudflare Dashboard or Wrangler CLI.

---

## Deployment (Cloudflare Dashboard - Easiest)

1. Log into your [Cloudflare Dashboard](https://dash.cloudflare.com/).
2. Navigate to **Workers & Pages** -> **Create Application** -> **Create Worker**.
3. Name it `faunty-push-notification` and click **Deploy**.
4. Click **Edit Code** and replace the default code with the contents of `index.js` in this folder.
5. Click **Save and Deploy**.
6. Go back to the Worker's setting panel, select **Settings** -> **Variables**.
7. Under **Environment Variables**, click **Add variable** / **Add secret**:
   - Set **Name**: `ONESIGNAL_REST_API_KEY` and **Value**: *Your actual OneSignal App REST API Key*.
   - Set **Name**: `ONESIGNAL_APP_ID` (optional) and **Value**: `f2a525de-b733-4e92-9494-dff5eae29756`.
8. Save and deploy again. Your Worker is now secure and ready to use!

---

## Triggering from Firestore (Optional Integration)
If you wish to trigger this Worker automatically when a new record is added to the Firestore `notification_queue`, you can use a webhook integration tool like Make.com (free tier) or set up a standard webhook pointing to this Worker URL.
