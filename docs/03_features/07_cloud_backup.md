# Feature 07: Cloud Backup & Sync (Optional / Post-MVP)

## Overview
Optional feature allowing users to back up their financial data to the cloud. This is local-first by default; cloud is opt-in. Deferred to v2 due to complexity, but the infrastructure is designed to support it.

## Scope

### Included in MVP (Foundation Only)
- `enable_cloud_sync` toggle in settings (UI only, non-functional)
- `is_synced_to_cloud` column on transactions (tracks sync status)
- `sync_state` table (schema ready for future use)
- Error handling for cloud operations (stubs)

### Full Implementation (v2+)
- Actual cloud sync to Firebase or Supabase
- Conflict resolution (local vs. cloud changes)
- Incremental sync (only new/updated transactions)
- Manual sync button in settings
- Auto-sync on interval (optional)
- User authentication (email/password or OAuth)
- Data encryption in transit and at rest

## User Stories

### US-07.01: Enable Cloud Backup (Stub)
**As a** a user  
**I want to** enable cloud backup so my data is safe  
**So that** I don't lose my financial history if I get a new phone

**Acceptance Criteria (MVP)**
- [ ] Settings has toggle: "Cloud Backup (Beta)"
- [ ] Toggle is OFF by default
- [ ] Tapping shows warning: "Backup will sync your data to a secure server."
- [ ] "Enable" button shows confirmation (but does nothing functional in MVP)
- [ ] Toggle state saved to `user_preferences.enable_cloud_sync`
- [ ] In v2, actual sync implementation follows

### US-07.02: Manual Sync (Stub)
**As a** a user with cloud backup enabled  
**I want to** manually sync my data now  
**So that** I ensure recent transactions are backed up

**Acceptance Criteria (MVP)**
- [ ] If cloud sync enabled, "Sync Now" button appears in settings
- [ ] Tapping shows: "Syncing..." with loading spinner (3 seconds max)
- [ ] After 3 seconds, shows: "Sync complete" (stub response)
- [ ] Updates `sync_state.last_sync_time` in database
- [ ] In v2, actual sync to cloud backend

## Architecture Notes (Design for v2)

### Cloud Provider Options
1. **Firebase Realtime Database**
   - Pros: Easy auth, real-time updates, Firestore rules for security
   - Cons: Vendor lock-in, pricing per read/write
   - Cost: Free tier covers small users; ~$6/month for 100k users

2. **Supabase (PostgreSQL + Auth)**
   - Pros: Open-source, PostgreSQL, fine-grained auth
   - Cons: Requires custom backend, more setup
   - Cost: $5-50/month depending on usage

**Recommendation for v2:** Supabase with RLS (Row-Level Security) for per-user data isolation.

### Sync Flow (v2 Design)
```
Local SQLite ← → Cloud DB
     ↓             ↓
  Changed?      Changed?
     ↓             ↓
  Queue sync   Merge & resolve
     ↓             ↓
  Send delta   Apply locally
     ↓
  Mark synced
```

### Conflict Resolution (v2)
- **Last-write-wins:** If local and cloud differ, use newer timestamp
- **Manual override:** User can choose "keep local" or "keep cloud"
- **Audit trail:** Log all sync conflicts (for debugging)

### Authentication (v2)
- Email + password (simple)
- Or OAuth (Google, Apple) for frictionless signup
- Multi-device support: same account on phone + tablet

### Data Encryption (v2)
- In transit: HTTPS (automatic via Firebase/Supabase)
- At rest: User data encrypted with per-user key (optional client-side encryption)
- Key management: Store key locally on device (not in cloud)

## Database Schema (v2 Cloud DB - Supabase Example)

```sql
-- Supabase Remote DB (parallel to local SQLite)

CREATE TABLE public.cloud_users (
  user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE public.cloud_transactions (
  transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.cloud_users(user_id) ON DELETE CASCADE,
  category_name TEXT NOT NULL,
  amount_idr INTEGER NOT NULL,
  description TEXT,
  transaction_date TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT cloud_transactions_amount CHECK (amount_idr > 0)
);

-- Row-level security (RLS) policy: each user sees only their own data
ALTER TABLE public.cloud_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY cloud_transactions_user_isolation ON public.cloud_transactions
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
```

## Sync Implementation (v2 Pseudocode)

```dart
// Pseudocode for v2 sync logic

class CloudSyncService {
  final _supabaseClient = Supabase.instance.client;
  
  Future<void> syncTransactions() async {
    // 1. Fetch all unsynced local transactions
    final unsyncedLocal = await _db.getUnsyncedTransactions();
    
    // 2. Push to cloud
    for (var txn in unsyncedLocal) {
      try {
        await _supabaseClient
          .from('cloud_transactions')
          .insert({
            'category_name': txn.categoryName,
            'amount_idr': txn.amountIdr,
            'description': txn.description,
            'transaction_date': txn.transactionDate.toIso8601String(),
          });
        
        // Mark as synced locally
        await _db.markSynced(txn.id);
      } catch (e) {
        print('Sync failed: $e');
        // Retry on next sync; don't mark as synced
      }
    }
    
    // 3. Update sync_state
    await _db.updateSyncState(
      lastSyncTime: DateTime.now(),
      direction: 'push',
    );
  }
}
```

## Error Handling (v2)

| Scenario | Behavior |
|----------|----------|
| No internet during sync | Queue transactions locally; retry on reconnect |
| Cloud service down (500 error) | Show: "Cloud is temporarily down. Retrying..." |
| Authentication expired | Show: "Re-login required" with login button |
| Quota exceeded | Show: "You've hit your sync limit. Upgrade your plan." |
| Sync conflict (local vs. cloud differ) | Show picker: "Keep local" or "Keep cloud" |
| Data corruption (malformed sync) | Abort sync; flag for manual review |

## Testing Strategy (v2)

### Unit Tests
- Sync conflict resolution logic
- Last-write-wins comparison
- Data validation before upload

### Integration Tests
- Full sync flow: local → cloud → verify remote
- Multi-device sync: change on phone → verify on tablet
- Conflict handling: edit on both devices → resolve

### End-to-End (Manual)
- Enable sync, verify data appears in cloud console
- Disable sync, verify data stays local
- Uninstall app, reinstall, re-enable sync → data reappears
- Offline mode: make changes → reconnect → sync

## Limitations & Future Work (v3+)
- Multi-currency support (currently Indonesia IDR only)
- Real-time sync (current MVP is manual only)
- Offline-first conflict-free replicated data types (CRDTs)
- Data sharing / family accounts
- Export to external services (Google Sheets, Notion)

## Definition of Done (MVP Phase)
- [ ] Toggle added to settings (non-functional)
- [ ] `is_synced_to_cloud` column on transactions table
- [ ] `sync_state` table schema defined
- [ ] Stub "Sync Now" button in settings (shows loading, clears)
- [ ] `enable_cloud_sync` preference saved to database
- [ ] Documentation clear that v1 cloud features are stubs
- [ ] Status in `docs/00_master_plan.md` marked as ⏳ Pending (v2)

## Definition of Done (v2 Full Implementation)
- [ ] Cloud provider chosen and infrastructure set up (Firebase or Supabase)
- [ ] User authentication (email/password or OAuth)
- [ ] Sync service fully implemented with conflict resolution
- [ ] Data encrypted in transit (HTTPS) and at rest
- [ ] Multi-device sync works: changes on one device appear on others
- [ ] RLS policies prevent users from seeing other users' data
- [ ] Rate limiting and quota enforcement
- [ ] Error handling for all failure scenarios
- [ ] Comprehensive testing (unit, integration, e2e)
- [ ] User documentation for cloud backup feature
- [ ] Status in `docs/00_master_plan.md` updated to ✅ Done

