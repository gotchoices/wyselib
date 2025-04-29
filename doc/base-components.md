# Base Module Components

The base module provides foundational database objects for entity management, addressing, communication, and security. These components have been fully ported to the current version of Wyseman.

## Entity Management (`base.ent`)

The entity system provides a unified approach to handling people, organizations, and other entities.

### Core Tables

- `base.ent`: Primary entity registry with fields for names, tax ID, and status
- `base.ent_type`: Entity type classification (person, organization, etc.)
- `base.ent_link`: Relationships between entities (employee-of, parent-subsidiary, etc.)

### Views

- `base.ent_v`: Primary view for entity access with extended information
- `base.ent_link_v`: View of entity relationships with descriptive fields

### Key Features

- Unified handling of different entity types
- Standard name formatting
- Optional legal name and common name support
- Entity relationship tracking
- Status tracking (active/inactive)
- Connection public key storage (`conn_pub` field) with multi-protocol support

The `conn_pub` field in `base.ent` stores connection credentials in a structured format:

```json
{
  "websocket": { "kty": "EC", ... },  // WebSocket JWK public key
  "libp2p": {                        // libp2p protocol connections
    "12D3KooW...": {                 // PeerID as the key
      "name": "My Device",           // Device name 
      "added": "2025-04-22T..."      // Timestamp when added
    }
  }
}
```

See the [Migration Notes](migration-notes.md) for important information about database changes to support this structure.

## Address Management (`base.addr`)

Comprehensive system for tracking physical and mailing addresses.

### Core Tables

- `base.addr`: Address storage with multiple types (physical, mailing, shipping, billing)
- `base.addr_prim`: Tracks which address is primary for each entity and type

### Views

- `base.addr_v`: Primary view for address management
- `base.addr_v_flat`: Flattened view showing all address types for easier integration

### Key Features

- Support for multiple address types per entity
- Primary address designation per type
- International address format support
- Address status tracking (active/inactive)
- Privacy flags for sensitive addresses

## Communication Endpoints (`base.comm`)

System for managing phone numbers, email addresses, and other communication channels.

### Core Tables

- `base.comm`: Communication endpoint storage
- `base.comm_prim`: Tracks primary communication methods

### Views

- `base.comm_v`: Primary view for communication management
- `base.comm_v_flat`: Flattened view showing all communication types

### Key Features

- Support for multiple communication types (email, cell, work, home, fax)
- Primary designation per type
- Communication status tracking
- Privacy flags for sensitive contact information
- Standardized phone number formatting

## System Parameters (`base.parm`)

Framework for application configuration via database parameters.

### Core Tables

- `base.parm`: Key-value parameter storage
- `base.parm_audit`: Audit trail for parameter changes

### Views

- `base.parm_v`: Parameter view with user-friendly descriptions
- `base.parm_audit_v`: View of parameter change history

### Key Features

- Type-specific parameter storage (text, numeric, boolean, date)
- Parameter categorization
- Default values
- Change history tracking
- Access control integration

## User Privileges (`base.priv`)

Comprehensive role-based access control system.

### Core Tables

- `base.priv`: Privilege definitions
- `base.priv_role`: Role definitions
- `base.priv_role_member`: Role membership assignments
- `base.priv_access`: Specific access grants

### Views

- `base.priv_v`: View of privileges with descriptions
- `base.priv_role_v`: View of roles with descriptions
- `base.priv_access_v`: View of access grants with human-readable names

### Key Features

- Role-based access control
- Hierarchical role structure
- Fine-grained privilege assignment
- Object-level permissions
- Runtime privilege checking

## File Management (`base.file`)

System for tracking and categorizing files.

### Core Tables

- `base.file`: File metadata registry
- `base.file_ver`: File version tracking
- `base.file_tag`: File categorization

### Views

- `base.file_v`: Primary view for file access
- `base.file_ver_v`: File version history
- `base.file_tag_v`: File tag assignments

### Key Features

- File metadata tracking
- MIME type support
- File ownership and access control
- Version history
- Tagging and categorization

## Token Authentication (`base.token`)

System for handling temporary authentication tokens and connection credentials.

### Core Tables

- `base.token`: Stores authentication tokens with expiration times
- Related data stored in `base.ent.conn_pub` (see Entity Management)

### Views

- `base.token_v`: View for token management with status indicators
- `base.token_v_ticket`: View for issuing connection tickets

### Functions

- `base.token_valid()`: Validates tokens and stores connection credentials
- `base.ticket_login()`: Creates a new login token for a specified user
- `base.token_tf_seq()`: Trigger function for generating unique tokens

### Key Features

- Temporary token generation with automatic expiration
- Integration with entity connection credentials
- Support for multiple authentication protocols
- Token usage tracking
- Multi-device support

## Reference Data

Standard reference tables for commonly needed values:

- `base.country`: ISO country codes and names
- `base.language`: ISO language codes and names

## Common Integration Patterns

The base module components are designed to be extended in consistent ways:

1. **Entity Extensions**:  
   Add application-specific fields to the entity system while maintaining compatibility with standard entity views.

2. **Custom Categorization**:  
   Extend type tables and link tables to create domain-specific categorization.

3. **Security Integration**:  
   Leverage the privilege system for access control in application-specific tables.

4. **Address/Communication Reuse**:  
   Reference the standardized addressing and communication components rather than creating new implementations.

5. **Parameter Configuration**:  
   Use the parameter system for application configuration instead of hardcoded values.