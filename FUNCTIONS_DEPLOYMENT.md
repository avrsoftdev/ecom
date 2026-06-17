# Firebase Cloud Functions Deployment Guide

## Prerequisites
1. Node.js (v18 or later) installed on your machine
2. Firebase CLI installed globally: `npm install -g firebase-tools`
3. Firebase project already set up and linked to your app

## Steps to Deploy

### 1. Install Dependencies
First, navigate to the `functions` directory and install the required npm packages:
```bash
cd functions
npm install
```

### 2. Log in to Firebase (if not already logged in)
```bash
firebase login
```

### 3. Initialize Firebase Functions (optional if not already initialized)
If you haven't set up Firebase Functions before, you can initialize them:
```bash
firebase init functions
```
- Select "Use an existing project" and choose your Firebase project
- Select JavaScript as the language
- Choose whether to use ESLint (we've already added a config)
- Choose whether to install dependencies now (we'll do that separately)

### 4. Deploy the Functions
To deploy only the functions:
```bash
firebase deploy --only functions
```

Or to deploy everything (functions, Firestore rules, etc.):
```bash
firebase deploy
```

## What the Function Does
The `sendAdminNotification` function:
1. Listens for new documents created in the `admin_notifications` collection
2. When a new notification is created, it finds all admin users with FCM tokens
3. Sends a push notification to all those admin users
4. Marks the notification as processed in Firestore

## Testing the Function
1. Create a new order using your user app
2. Check the Firebase console logs to see if the function executed:
   ```bash
   firebase functions:log
   ```
3. Verify that admin users received the push notification

## Troubleshooting
- If deployment fails, check the error message for details
- Make sure your Firebase project has the Blaze plan (required for Cloud Functions)
- Verify that admin users have a valid `fcmToken` stored in their user document in Firestore
