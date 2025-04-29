# Wyselib Documentation

Wyselib is a library of reusable SQL objects for accelerating database application development. This documentation describes the schema components available in the library.

## Library Structure

Wyselib is organized into functional modules:

- **Base**: Core entity and communication management (`schema/base/`)
- **Accounting**: Financial record-keeping (`schema/acct/`)
- **Asset**: Asset tracking and management (`schema/asset/`)
- **Customer**: CRM foundations (`schema/cust/`)
- **Document**: Document management (`schema/doc/`)
- **Employee**: Personnel management (`schema/empl/`)
- **Payroll**: Payroll processing and withholding (`schema/payroll/`)
- **Product**: Inventory and manufacturing (`schema/prod/`)

## Schema Components

### Base Module

Core components that form the foundation for most applications:

| Component | Description |
|-----------|-------------|
| `base.ent` | Entity management for people and organizations |
| `base.addr` | Physical and mailing addresses for entities |
| `base.comm` | Communication channels (phone, email, etc.) |
| `base.country` | Country reference data |
| `base.language` | Language reference data |
| `base.file` | File storage system |
| `base.login` | Authentication and session management |
| `base.parm` | System parameters and configuration |
| `base.priv` | User privileges and access control |

### Accounting Module

Double-entry accounting system components:

| Component | Description |
|-----------|-------------|
| `acct.acct` | Chart of accounts management |
| `acct.cat` | Account categorization |
| `acct.meth` | Accounting methods |
| `acct.close` | Period closing procedures |
| `acct.proj` | Project accounting framework |
| `acct.budg` | Budget planning and tracking |

### Other Modules 

These modules provide additional functionality but have not been fully ported to the current version of wyseman:

- `asset`: Fixed and variable asset tracking
- `cust`: Customer relationship management
- `doc`: Document storage and classification
- `empl`: Employee records and HR management
- `payroll`: Payroll processing with tax withholding
- `prod`: Product and inventory with bill-of-materials

## Using the Library

To use Wyselib components in your own applications:

1. Include the required schema files using wyseman's `require` mechanism
2. Extend the base tables with your own application-specific fields
3. Create additional views and functions for your business logic
4. Reference the text and display definitions for UI integration

## Extension Points

Each Wyselib module is designed to be extended:

- `base.ent`: Add custom entity types and fields
- `base.addr`: Extend with additional address types
- `acct.acct`: Create specialized account structures
- `prod.part`: Add product-specific attributes

Refer to individual schema files for specific extension mechanisms.