const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'ecomapp-22701'
});

const auth = admin.auth();
const db = admin.firestore();

async function checkAdminUser() {
  try {
    const adminEmail = 'admin@freshveggie.com';
    
    // Get user by email
    const userRecord = await auth.getUserByEmail(adminEmail);
    console.log('✅ User found:', userRecord.uid);
    console.log('📧 Email:', userRecord.email);
    console.log('👤 Display Name:', userRecord.displayName);
    console.log('🔐 Custom Claims:', userRecord.customClaims);
    
    // Check Firestore user document
    const userDoc = await db.collection('users').doc(userRecord.uid).get();
    if (userDoc.exists) {
      const userData = userDoc.data();
      console.log('\n📄 Firestore document exists:');
      console.log('📋 Data:', JSON.stringify(userData, null, 2));
      console.log('👤 Role from Firestore:', userData.role);
    } else {
      console.log('\n❌ Firestore document does not exist');
      
      // Create the user document with admin role
      console.log('🔧 Creating user document with admin role...');
      await db.collection('users').doc(userRecord.uid).set({
        uid: userRecord.uid,
        email: userRecord.email,
        displayName: userRecord.displayName || 'Admin User',
        role: 'admin',
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        last_sign_in_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log('✅ User document created with admin role');
    }
    
    // Test authentication
    console.log('\n🧪 Testing authentication...');
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

checkAdminUser();
