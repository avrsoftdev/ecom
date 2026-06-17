const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const fcm = admin.messaging();

// Send admin notification when a new order is created
exports.sendAdminNotification = functions.firestore
  .document("admin_notifications/{notificationId}")
  .onCreate(async (snap) => {
    const notification = snap.data();

    if (notification.type !== "new_order" || notification.targetRole !== "admin") {
      console.log("Skipping non-admin notification");
      return null;
    }

    try {
      // Get all admin users with FCM tokens
      const adminsSnapshot = await db
        .collection("users")
        .where("role", "==", "admin")
        .where("fcmToken", "!=", null)
        .get();

      if (adminsSnapshot.empty) {
        console.log("No admin users with FCM tokens found");
        return null;
      }

      const tokens = [];
      adminsSnapshot.docs.forEach((doc) => {
        const token = doc.data().fcmToken;
        if (token) {
          tokens.push(token);
        }
      });

      if (tokens.length === 0) {
        console.log("No valid FCM tokens found for admins");
        return null;
      }

      console.log(`Found ${tokens.length} admin token(s)`);

      // Create FCM message
      const message = {
        notification: {
          title: notification.title || "New Order Received!",
          body: notification.body || `New order from ${notification.customerName}`,
        },
        data: {
          type: "new_order",
          orderId: notification.orderId,
          customerName: notification.customerName,
          totalAmount: notification.totalAmount.toString(),
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        tokens: tokens,
        android: {
          priority: "high",
          notification: {
            sound: "alert_ring.mp3",
            priority: "high",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "alert_ring.mp3",
              priority: 10,
            },
          },
        },
      };

      // Send the message
      const response = await fcm.sendEachForMulticast(message);

      console.log(`Successfully sent ${response.successCount} messages`);
      if (response.failureCount > 0) {
        console.error(`Failed to send ${response.failureCount} messages`);
        response.responses.forEach((resp, idx) => {
          if (resp.error) {
            console.error(`Error sending to token ${tokens[idx]}:`, resp.error);
          }
        });
      }

      // Mark notification as processed
      await snap.ref.update({
        processed: true,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    } catch (error) {
      console.error("Error sending admin notification:", error);
      throw error;
    }
  });
