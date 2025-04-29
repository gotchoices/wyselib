# Database Migration Notes

## Login and Connection Migration

The `base.ent.conn_pub` field structure has been enhanced to support multiple connection protocols such as WebSocket and libp2p. The field now stores credentials in a structured format organized by protocol.

### Connection Public Key Structure Change

Previously, the `conn_pub` field stored a single JWK public key directly. In the updated structure, this field is a JSON object where each connection protocol has its own key:

```json
{
  "websocket": { "kty": "EC", ... },  // The JWK public key for WebSocket connections
  "libp2p": {                        // For libp2p connections
    "12D3KooW...": {                 // PeerID as the key
      "name": "My Device",           // Device name 
      "added": "2025-04-22T..."      // Timestamp when added
    }
  }
}
```

This structure allows for:
- Multiple connection protocols (WebSocket, libp2p, etc.)
- Multiple devices per user within each protocol
- Protocol-specific metadata for each connection

### Migration Required

If you're upgrading from a previous version, you'll need to run a database migration to update existing `conn_pub` values. The following SQL script will wrap existing JWK public keys into the new structure:

```sql
UPDATE base.ent
SET conn_pub = jsonb_build_object('websocket', conn_pub)
WHERE jsonb_typeof(conn_pub) = 'object' AND conn_pub ? 'kty';
```

### Verification

After running the migration, you can verify the structure for a sample user:

```sql
SELECT id, conn_pub FROM base.ent WHERE id = 'some_user_id';
```

The `conn_pub` column should now look like: `{"websocket": {"kty": "...", ...}}`

### Implementation Details

The `base.token_valid` function in `schema/base/login.wms` has been modified to accept a path parameter:

```sql
base.token_valid(uname text, tok text, pub jsonb, path text[] = array['default'])
```

This function now stores the provided public key information at the specified path in the `conn_pub` JSON structure. The path parameter is an array that specifies the location where the key should be stored (e.g., `['websocket']` or `['libp2p', '12D3KooW...']`).

When migrating from an older system, client connections will need to be updated to provide the correct path for storing credential information.