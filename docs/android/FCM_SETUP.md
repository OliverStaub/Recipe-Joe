# Firebase Cloud Messaging (FCM) Setup for RecipeJoe Android

This guide explains how to set up push notifications for the Android app.

## Prerequisites

- Firebase project (created during Google Sign-In setup)
- Android app registered in Firebase

## Step 1: Enable Cloud Messaging

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to "Cloud Messaging" in the left menu
4. Note your Server Key and Sender ID

## Step 2: Add FCM Dependency

Already included in `app/build.gradle.kts`. If needed:

```kotlin
implementation("com.google.firebase:firebase-messaging-ktx:24.0.0")
```

## Step 3: Create FCM Service

Create `app/src/main/java/com/recipejoe/data/remote/RecipeJoeMessagingService.kt`:

```kotlin
package com.recipejoe.data.remote

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import timber.log.Timber

class RecipeJoeMessagingService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        Timber.d("FCM Token: $token")
        // Send token to your server
        sendTokenToServer(token)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        Timber.d("FCM Message: ${message.data}")

        // Handle notification
        message.notification?.let { notification ->
            showNotification(notification.title, notification.body)
        }

        // Handle data payload
        if (message.data.isNotEmpty()) {
            handleDataPayload(message.data)
        }
    }

    private fun sendTokenToServer(token: String) {
        // TODO: Send to Supabase
    }

    private fun showNotification(title: String?, body: String?) {
        // TODO: Show local notification
    }

    private fun handleDataPayload(data: Map<String, String>) {
        // TODO: Handle data payload
    }
}
```

## Step 4: Register Service in Manifest

Add to `AndroidManifest.xml`:

```xml
<service
    android:name=".data.remote.RecipeJoeMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

## Step 5: Create Notification Channels

For Android 8.0+, create notification channels in `RecipeJoeApp.kt`:

```kotlin
override fun onCreate() {
    super.onCreate()

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        createNotificationChannels()
    }
}

@RequiresApi(Build.VERSION_CODES.O)
private fun createNotificationChannels() {
    val manager = getSystemService(NotificationManager::class.java)

    // Recipe updates channel
    val recipeChannel = NotificationChannel(
        "recipe_updates",
        "Recipe Updates",
        NotificationManager.IMPORTANCE_DEFAULT
    ).apply {
        description = "Notifications about recipe imports and updates"
    }

    // Promotions channel
    val promoChannel = NotificationChannel(
        "promotions",
        "Promotions",
        NotificationManager.IMPORTANCE_LOW
    ).apply {
        description = "Special offers and promotions"
    }

    manager.createNotificationChannels(listOf(recipeChannel, promoChannel))
}
```

## Step 6: Request Notification Permission (Android 13+)

For Android 13 (API 33)+, you must request notification permission:

```kotlin
// In MainActivity or appropriate location
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
    requestPermissions(
        arrayOf(Manifest.permission.POST_NOTIFICATIONS),
        NOTIFICATION_PERMISSION_CODE
    )
}
```

## Step 7: Server-Side Setup

### Get FCM Server Key

1. Go to Firebase Console > Project Settings > Cloud Messaging
2. Copy the Server Key

### Configure Supabase Edge Function

Create or update `supabase/functions/send-notification/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')!

serve(async (req) => {
  const { token, title, body, data } = await req.json()

  const response = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `key=${FCM_SERVER_KEY}`,
    },
    body: JSON.stringify({
      to: token,
      notification: { title, body },
      data,
    }),
  })

  return new Response(JSON.stringify({ success: true }))
})
```

### Store FCM Token in Database

Create a table to store device tokens:

```sql
CREATE TABLE device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'android',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, token)
);

-- RLS policies
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own tokens"
  ON device_tokens
  FOR ALL
  USING (auth.uid() = user_id);
```

## Step 8: Testing

### Send Test Notification from Firebase Console

1. Go to Firebase Console > Cloud Messaging
2. Click "Send your first message"
3. Enter notification content
4. Target your test device
5. Send

### Send from Server

```bash
curl -X POST "https://<project>.supabase.co/functions/v1/send-notification" \
  -H "Authorization: Bearer <anon-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "<device-fcm-token>",
    "title": "Recipe Ready!",
    "body": "Your pasta recipe has been imported."
  }'
```

## Use Cases for RecipeJoe

1. **Import Complete**: Notify when a long-running import finishes
2. **Token Low**: Remind users when token balance is low
3. **Weekly Digest**: Send weekly recipe suggestions
4. **Special Offers**: Promote token packages

## Troubleshooting

### Notifications not received

- Check FCM token is valid
- Verify notification permissions granted
- Ensure app is not in "force stopped" state
- Check notification channel settings

### Token refresh issues

- Token refreshes automatically
- Handle `onNewToken` to update server

### Background restrictions

Some devices (Xiaomi, Huawei) restrict background services. Users may need to:
- Disable battery optimization for the app
- Enable auto-start permission
