const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const fcm = admin.messaging();

/**
 * Send notifications to admin and vendors when a new order is created
 * @param {Object} snap - Firestore snapshot
 * @return {Promise}
 */
exports.sendNewOrderNotifications = functions
  .region("asia-south1")
  .firestore
  .document("orders/{orderId}")
  .onCreate(async (snap) => {
      const order = snap.data();
      const orderId = snap.id;
      const customerName = order.customerName || "Customer";
      const customerPhone = order.phone || "";
      const totalAmount = order.total || 0;

      // Get all unique vendor IDs from order items
      const vendorIds = [
        ...new Set(
          order.items
              .map((item) => item.vendorId)
              .filter((id) => id && id.trim() !== ""),
        ),
      ];

      console.log(
        "New order " + orderId + " placed by " + customerName +
        " - Vendors: " + vendorIds.join(", "),
      );

      try {
        // 1. Get admin tokens
        const adminTokens = await getUserTokensByRole("admin");
        console.log(`Found ${adminTokens.length} admin token(s)`);

        // 2. Get vendor tokens for each involved vendor
        const vendorTokens = await getUserTokensByVendorIds(vendorIds);
        console.log(
          "Found " + vendorTokens.length + " vendor token(s) for " +
          vendorIds.length + " vendor(s)",
        );

        // Combine and deduplicate all tokens to avoid duplicates
        const allTokens = [...new Set([...adminTokens, ...vendorTokens])];
        console.log("Total unique tokens to send: " + allTokens.length);

        // Send notifications to all unique tokens
        if (allTokens.length > 0) {
          await sendFCMNotification({
            tokens: allTokens,
            title: "New Order Received 🛒",
            body: `Order #${orderId} has been placed by ${customerName}.`,
            data: {
              orderId: orderId,
              customerName: customerName,
              customerPhone: customerPhone,
              totalAmount: totalAmount.toString(),
              notificationType: "new_order",
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            collapseKey: orderId, // Collapse notifications for same order
          });
        }

        return null;
      } catch (error) {
        console.error("Error sending new order notifications:", error);
        throw error;
      }
    });

/**
 * Helper function to get all tokens from a user document
 * Supports both single token (fcmToken) and array of tokens (fcmTokens)
 * @param {Object} doc - Firestore document
 * @return {Array}
 */
function extractTokensFromDoc(doc) {
  const data = doc.data();
  const tokens = [];

  // Support for array of tokens (preferred)
  if (data.fcmTokens && Array.isArray(data.fcmTokens)) {
    tokens.push(...data.fcmTokens);
  }

  // Support for single token (backward compatibility)
  if (
    data.fcmToken &&
    typeof data.fcmToken === "string" &&
    data.fcmToken.trim() !== ""
  ) {
    tokens.push(data.fcmToken);
  }

  // Remove duplicates
  return [...new Set(tokens.filter((token) => token && token.trim() !== ""))];
}

/**
 * Get FCM tokens for users with a specific role
 * @param {string} role - User role
 * @return {Promise<Array>}
 */
async function getUserTokensByRole(role) {
  const snapshot = await db
      .collection("users")
      .where("role", "==", role)
      .get();

  const tokens = [];
  snapshot.docs.forEach((doc) => {
    tokens.push(...extractTokensFromDoc(doc));
  });

  // Remove duplicates
  return [...new Set(tokens)];
}

/**
 * Get FCM tokens for users that are vendors with specific vendor IDs
 * @param {Array} vendorIds - Vendor IDs
 * @return {Promise<Array>}
 */
async function getUserTokensByVendorIds(vendorIds) {
  if (vendorIds.length === 0) return [];

  const tokens = [];

  // Firestore allows up to 10 elements in 'in' clause
  // Split into chunks if needed
  const chunkSize = 10;
  for (let i = 0; i < vendorIds.length; i += chunkSize) {
    const chunk = vendorIds.slice(i, i + chunkSize);
    const snapshot = await db
        .collection("users")
        .where("role", "==", "vendor")
        .where("vendorId", "in", chunk)
        .get();

    snapshot.docs.forEach((doc) => {
      tokens.push(...extractTokensFromDoc(doc));
    });
  }

  // Remove duplicates
  return [...new Set(tokens)];
}

/**
 * Remove invalid token from user document
 * @param {string} userId - User ID
 * @param {string} invalidToken - Invalid token to remove
 * @return {Promise}
 */
async function removeInvalidToken(userId, invalidToken) {
  try {
    const userRef = db.collection("users").doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) return;

    const data = userDoc.data();

    // Remove from fcmTokens array if present
    if (data.fcmTokens && Array.isArray(data.fcmTokens)) {
      const updatedTokens = data.fcmTokens.filter(
          (token) => token !== invalidToken,
      );
      await userRef.update({fcmTokens: updatedTokens});
    }

    // Remove from fcmToken single field if it's the one
    if (data.fcmToken === invalidToken) {
      await userRef.update({fcmToken: admin.firestore.FieldValue.delete()});
    }

    console.log(`Removed invalid token for user ${userId}`);
  } catch (error) {
    console.error(`Error removing invalid token for user ${userId}:`, error);
  }
}

/**
 * Send FCM notification to multiple tokens
 * @param {Object} options - Notification options
 * @return {Promise}
 */
async function sendFCMNotification({tokens, title, body, data, collapseKey}) {
  if (tokens.length === 0) {
    console.log("No tokens to send notification to");
    return;
  }

  // FCM has a limit of 500 tokens per multicast
  const chunkSize = 500;
  for (let i = 0; i < tokens.length; i += chunkSize) {
    const chunk = tokens.slice(i, i + chunkSize);

    const message = {
      notification: {
        title,
        body,
      },
      data,
      tokens: chunk,
      android: {
        priority: "high",
        collapseKey: collapseKey,
        notification: {
          sound: "alert_ring.mp3",
          priority: "high",
          tag: collapseKey,
          channelId: "freshveggie_channel" // Use our custom channel
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "alert_ring.mp3",
            priority: 10,
            threadId: collapseKey,
          },
        },
      },
    };

    const response = await fcm.sendEachForMulticast(message);
    const chunkNum = Math.floor(i / chunkSize) + 1;
    console.log(
      "Successfully sent " + response.successCount + "/" +
      response.responses.length + " messages in chunk " + chunkNum,
    );

    if (response.failureCount > 0) {
      console.error(
        "Failed to send " + response.failureCount +
        " messages in chunk " + chunkNum,
      );

      // Get all user documents to map tokens back to user IDs for cleanup
      const allUsersSnapshot = await db.collection("users").get();
      const tokenToUserMap = new Map();

      allUsersSnapshot.docs.forEach((doc) => {
        const userTokens = extractTokensFromDoc(doc);
        userTokens.forEach((token) => {
          tokenToUserMap.set(token, doc.id);
        });
      });

      response.responses.forEach((resp, idx) => {
        if (resp.error) {
          const failedToken = chunk[idx];
          console.error(`Error sending to token ${failedToken}:`, resp.error);

          // Check if error is due to invalid token
          if (
            resp.error.code === "messaging/invalid-registration-token" ||
            resp.error.code === "messaging/registration-token-not-registered"
          ) {
            const userId = tokenToUserMap.get(failedToken);
            if (userId) {
              removeInvalidToken(userId, failedToken);
            }
          }
        }
      });
    }
  }
}
