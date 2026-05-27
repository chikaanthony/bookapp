import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.21.0"
import { JWT } from "https://esm.sh/google-auth-library@8.8.0"

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID')!
const FIREBASE_CLIENT_EMAIL = Deno.env.get('FIREBASE_CLIENT_EMAIL')!
const FIREBASE_PRIVATE_KEY = Deno.env.get('FIREBASE_PRIVATE_KEY')!.replace(/\\n/g, '\n')

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

async function getAccessToken(): Promise<string> {
  const jwtClient = new JWT({
    email: FIREBASE_CLIENT_EMAIL,
    key: FIREBASE_PRIVATE_KEY,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });
  const credentials = await jwtClient.getAccessToken();
  return credentials.token!;
}

async function sendFcmNotification(token: string, title: string, body: string) {
  const accessToken = await getAccessToken();
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
        },
      }),
    }
  );

  if (!response.ok) {
    const errorText = await response.text();
    console.error(`❌ FCM Send Error (Token: ${token}):`, errorText);
    if (response.status === 404 || errorText.includes("UNREGISTERED") || errorText.includes("INVALID_ARGUMENT")) {
      await supabase.from('device_tokens').delete().eq('token', token);
    }
  }
}

async function getUserTokens(userIds: string[]): Promise<string[]> {
  if (userIds.length === 0) return [];
  const { data, error } = await supabase
    .from('device_tokens')
    .select('token')
    .in('user_id', userIds);

  if (error || !data) return [];
  return data.map((d: { token: string }) => d.token);
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } });
  }

  try {
    const payload = await req.json();
    const { record, old_record } = payload;

    // Check if status transitioned away from pending
    if (old_record && old_record.status === 'pending' && record.status !== 'pending') {
      const targetDate = record.created_at;

      // Retrieve remaining pending queue items sequentially
      const { data: remainingBookings, error: queryError } = await supabase
        .from('bookings')
        .select('id, user_id')
        .eq('status', 'pending')
        .eq('created_at', targetDate)
        .order('created_at', { ascending: true });

      if (queryError || !remainingBookings || remainingBookings.length === 0) {
        return new Response(JSON.stringify({ status: "No remaining users to notify" }), { status: 200 });
      }

      // Process notification logic for each remaining user based on current rank position
      for (let index = 0; index < remainingBookings.length; index++) {
        const client = remainingBookings[index];
        if (!client.user_id) continue;

        const calculatedPosition = index + 1;
        const clientTokens = await getUserTokens([client.user_id]);

        for (const token of clientTokens) {
          let title = "Lineup Update ✂️";
          let body = `The queue just moved! You are now position No. ${calculatedPosition} in line.`;

          if (calculatedPosition === 1) {
            title = "You're Next Up! 💈";
            body = "Step up to the chair! The barber is ready for you right now.";
          } else if (calculatedPosition === 2) {
            title = "Queue Update: Position No. 2";
            body = "You are now second in line. Keep an eye out, you are almost up!";
          }

          await sendFcmNotification(token, title, body);
        }
      }
    }

    return new Response(JSON.stringify({ success: true }), { headers: { 'Content-Type': 'application/json' } });
  } catch (err) {
    console.error('💥 Webhook runtime exception:', err);
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});
