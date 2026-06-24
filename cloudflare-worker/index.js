export default {
  async fetch(request, env) {
    // Enable CORS
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    if (request.method !== 'POST') {
      return new Response('Method Not Allowed', { status: 405, headers: corsHeaders });
    }

    try {
      const payload = await request.json();
      
      // Basic payload validation
      if (!payload.title || !payload.body) {
        return new Response(JSON.stringify({ error: 'Missing title or body' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // Format OneSignal payload
      const oneSignalPayload = {
        app_id: env.ONESIGNAL_APP_ID || payload.appId || 'f2a525de-b733-4e92-9494-dff5eae29756',
        headings: { en: payload.title },
        contents: { en: payload.body },
        data: payload.payload || {},
      };

      if (payload.targetUserIds && payload.targetUserIds.length > 0) {
        oneSignalPayload['include_external_user_ids'] = payload.targetUserIds;
      } else {
        oneSignalPayload['included_segments'] = ['All'];
      }

      if (payload.imageUrl) {
        oneSignalPayload['chrome_web_image'] = payload.imageUrl;
        oneSignalPayload['big_picture'] = payload.imageUrl;
        oneSignalPayload['ios_attachments'] = { id1: payload.imageUrl };
      }
      
      if (payload.launchUrl) {
        oneSignalPayload['url'] = payload.launchUrl;
      }

      if (payload.deliveryTime) {
        oneSignalPayload['send_after'] = payload.deliveryTime;
      }

      // Call OneSignal REST API
      const response = await fetch('https://onesignal.com/api/v1/notifications', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': `Basic ${env.ONESIGNAL_REST_API_KEY}`,
        },
        body: JSON.stringify(oneSignalPayload),
      });

      const result = await response.json();

      return new Response(JSON.stringify(result), {
        status: response.status,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    } catch (e) {
      return new Response(JSON.stringify({ error: e.toString() }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  },
};
