const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'ecomapp-22701'
});

const auth = admin.auth();

async function createAdminUser() {
  try {
    let userRecord;
    const adminEmail = 'admin@freshveggie.com';
    
    try {
      // Try to get existing user
      userRecord = await auth.getUserByEmail(adminEmail);
      console.log('Found existing user:', userRecord.uid);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        // Create new admin user if doesn't exist
        userRecord = await auth.createUser({
          email: adminEmail,
          password: 'admin123456',
          displayName: 'Admin User',
        });
        console.log('Successfully created new user:', userRecord.uid);
      } else {
        throw error;
      }
    }

    // Set custom claims for admin role
    await auth.setCustomUserClaims(userRecord.uid, { role: 'admin' });
    console.log('Successfully set admin claims for user');

    // Verify claims
    const user = await auth.getUser(userRecord.uid);
    console.log('User custom claims:', user.customClaims);

    console.log('\n✅ Admin account setup completed!');
    console.log('📧 Email:', adminEmail);
    console.log('🔑 Password: admin123456');
    console.log('👤 Role: admin');
    console.log('🆔 User ID:', userRecord.uid);

  } catch (error) {
    console.error('Error setting up admin user:', error);
  }
}

createAdminUser();
