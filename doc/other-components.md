# Other Wyselib Components

The following schema components are included in Wyselib but have not been fully ported to the current version of Wyseman. These components should be documented more thoroughly when properly ported and implemented according to current standards.

## Accounting (`schema/acct/`)

Financial record-keeping and general ledger system:

- Chart of accounts with hierarchical structure
- Multi-dimensional account categorization
- Period closing procedures
- Budget planning and tracking
- Project-based accounting

## Asset Management (`schema/asset/`)

System for tracking and managing fixed and variable assets:

- Asset registry and inventory
- Depreciation calculation
- Asset maintenance scheduling
- Acquisition and disposal tracking

## Customer Management (`schema/cust/`)

Customer relationship management foundations:

- Customer profiles linked to base entities
- Contact management integration
- Service history tracking
- Customer categorization

## Document Management (`schema/doc/`)

Document storage and classification system:

- Document metadata tracking
- Version control
- Document categorization
- Link documents to entities and transactions

## Employee Management (`schema/empl/`)

Personnel management and human resources:

- Employee records extending base entities
- Position and department tracking
- Employment history
- Skills and certification tracking

## Payroll Processing (`schema/payroll/`)

Payroll calculation and tax withholding:

- Earnings and deductions tracking
- Tax withholding rules for multiple jurisdictions
- Payroll period management
- Payment tracking

## Product Management (`schema/prod/`)

Inventory and manufacturing support:

- Product definitions and categories
- Bill of materials for manufacturing
- Inventory tracking
- Product documentation

## Additional Components

Other schema elements that require further development:

- System actions (`schema/sact/`)
- Global utilities (`schema/glob.wms`)
- Transaction framework (`schema/tran.tcl`)
- Multi-view utilities (`schema/multiview.tcl`, `schema/splitview.tcl`, `schema/trigview.tcl`)

These components provide valuable functionality but require modernization to align with current Wyseman best practices. When porting these components, each should be documented with:

1. Core tables and their relationships
2. Primary views for accessing data
3. Key functions and their purposes
4. Integration points with other components
5. Extension mechanisms for customization