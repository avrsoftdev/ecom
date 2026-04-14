# Firestore Security Rules & Indexes Setup Guide

This guide provides the complete setup for FreshVeggie e-commerce Firestore security rules and indexes.

## 📋 Files Created

1. **firestore.rules** - Security rules for data protection
2. **firestore.indexes.json** - Database indexes for optimal performance

## 🛡️ Security Rules Setup

### Deploy Security Rules

```bash
# Deploy security rules to Firestore
firebase deploy --only firestore:rules
```

### Security Rules Features

- **Authentication Required**: All write operations require authentication
- **Role-Based Access**: Admin users have full access, regular users have limited access
- **Data Isolation**: Users can only access their own cart, wishlist, and orders
- **Public Read Access**: Only active products, categories, and banners are publicly readable
- **Admin Protection**: Only users with `role: 'admin'` can manage products, categories, and banners

### Collections Protected

| Collection | Public Read | Admin Write | User Write | Notes |
|------------|--------------|--------------|-------------|---------|
| products | ✅ (active only) | ✅ | ❌ | Only active products visible |
| categories | ✅ (active only) | ✅ | ❌ | Only active categories visible |
| banners | ✅ (active only) | ✅ | ❌ | Only active banners visible |
| orders | 👤 (own only) | ✅ | 👤 (own only) | Users see their orders |
| cart | 👤 (own only) | ❌ | 👤 (own only) | Personal cart items |
| wishlist | 👤 (own only) | ❌ | 👤 (own only) | Personal wishlist |
| reviews | ✅ (public) | 👤 (own only) | 👤 (own only) | Public reviews |

## 🚀 Indexes Setup

### Deploy Indexes

```bash
# Deploy indexes to Firestore
firebase deploy --only firestore:indexes
```

### Required Indexes Explained

#### Products Collection
1. **Featured Products Query**
   - Fields: `isActive` (ASC), `isFeatured` (ASC), `createdAt` (DESC)
   - Used by: Home screen featured products section

2. **Today's Deals Query**
   - Fields: `isActive` (ASC), `discountPercent` (DESC)
   - Used by: Home screen deals section

3. **New Arrivals Query**
   - Fields: `isActive` (ASC), `createdAt` (DESC)
   - Used by: Home screen new arrivals section

4. **Recommended Products Query**
   - Fields: `isActive` (ASC), `rating` (DESC)
   - Used by: Home screen recommended section

5. **Category Products Query**
   - Fields: `isActive` (ASC), `categoryId` (ASC), `createdAt` (DESC)
   - Used by: Product listing by category

6. **Product Search Query**
   - Fields: `isActive` (ASC), `name` (ASC)
   - Used by: Product search functionality

7. **Price Sorting Query**
   - Fields: `isActive` (ASC), `price` (ASC/DESC)
   - Used by: Product sorting by price

#### Categories Collection
8. **Categories Query**
   - Fields: `isActive` (ASC), `order` (ASC)
   - Used by: Home screen categories section

#### Banners Collection
9. **Banners Query**
   - Fields: `isActive` (ASC), `order` (ASC)
   - Used by: Home screen banner carousel

#### Orders Collection
10. **User Orders Query**
    - Fields: `userId` (ASC), `createdAt` (DESC)
    - Used by: User order history

11. **Order Status Query**
    - Fields: `status` (ASC), `createdAt` (DESC)
    - Used by: Admin order management

#### Cart Collection
12. **User Cart Query**
    - Fields: `userId` (ASC), `createdAt` (DESC)
    - Used by: Shopping cart functionality

#### Wishlist Collection
13. **User Wishlist Query**
    - Fields: `userId` (ASC), `createdAt` (DESC)
    - Used by: Wishlist functionality

#### Reviews Collection
14. **Product Reviews Query**
    - Fields: `productId` (ASC), `createdAt` (DESC)
    - Used by: Product reviews display

15. **Top Rated Products Query**
    - Fields: `rating` (DESC)
    - Used by: Product rating display

## 🔧 Field Overrides

### Text Search Optimization
- **Products.name**: Array contains for search functionality
- **Products.description**: Array contains for search functionality
- **Users.email**: Unique constraint for user authentication

## 📱 Performance Benefits

### Before Indexes
- Slow queries on large datasets
- Query timeouts on complex filters
- Poor user experience with loading times
- High Firestore read costs due to full collection scans

### After Indexes
- ⚡ Fast query performance (< 100ms)
- 📊 Optimized read costs
- 🚀 Smooth user experience
- 📈 Scalable for growth

## 🛠️ Manual Index Creation (Alternative)

If automatic deployment fails, create indexes manually in Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to Firestore Database → Indexes
4. Click "Add Index" for each query pattern listed above

## 🔍 Testing Your Setup

### Test Security Rules
```bash
# Test rules with Firebase emulator
firebase emulators:start --only firestore
```

### Test Index Performance
```bash
# Monitor query performance in Firebase Console
# Check Firestore usage tab for slow queries
```

## 📊 Monitoring

### Key Metrics to Watch
- Query execution time
- Document read count
- Index usage percentage
- Security rule evaluation time

### Optimization Tips
- Monitor slow queries in Firebase Console
- Add composite indexes for new query patterns
- Review security rule complexity for performance
- Use pagination for large result sets

## 🚨 Important Notes

1. **Deploy Rules First**: Always deploy security rules before indexes
2. **Test Thoroughly**: Test all user roles and permissions
3. **Monitor Costs**: Keep an eye on Firestore usage
4. **Update Regularly**: Add new indexes as features are added
5. **Backup Rules**: Keep version control of security rules

## 🔄 Maintenance

### Regular Tasks
- Review security rules quarterly
- Monitor index usage monthly
- Update indexes for new features
- Audit user permissions regularly

### Troubleshooting
- **Missing Index Error**: Check Firebase Console for index creation status
- **Permission Denied**: Verify user roles and security rules
- **Slow Queries**: Review query patterns and index coverage

---

**Setup Complete!** 🎉

Your FreshVeggie e-commerce app now has:
- ✅ Secure data access controls
- ✅ Optimized query performance
- ✅ Role-based permissions
- ✅ Scalable database structure
