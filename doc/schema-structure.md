# Wyselib Schema Structure

This document describes the organization and naming conventions of the Wyselib schema components.

## Directory Organization

Wyselib organizes schema files into functional modules:

```
schema/
├── base/           # Core entity and contact management
│   ├── addr.wms    # Address management
│   ├── comm.wms    # Communication endpoints
│   ├── country.wms # Country reference data
│   ├── ent.wms     # Entity registry
│   ├── file.wms    # File management
│   └── ...
├── acct/           # Accounting module
│   ├── acct.wms    # Chart of accounts
│   ├── cat.wms     # Account categories
│   └── ...
└── ...             # Other functional modules
```

Each module contains Wyseman schema files with standardized extensions:

- `.wms`: Schema definition files (tables, views, functions)
- `.wmt`: Text string definitions (UI labels, help text)
- `.wmd`: Display properties for UI rendering
- `.wmi`: Initialization scripts for reference data

## Naming Conventions

### Schema Objects

Objects in Wyselib follow these naming patterns:

1. **Tables**: `module_name.object_name`
   - Primary tables use simple names: `base.ent`, `acct.acct`
   - Link tables use `_link` suffix: `base.ent_link`
   - Type tables use `_type` suffix: `base.ent_type`
   - Audit tables use `_audit` suffix: `base.parm_audit`

2. **Views**: `module_name.object_name_v`
   - Standard views add `_v` suffix: `base.ent_v`
   - Specialized views add descriptive suffixes: `base.ent_v_flat`

3. **Functions**: `module_name.function_name()`
   - Trigger functions use `_tf_` prefix with trigger timing:
     - `base.ent_tf_bi()`: Before Insert trigger
     - `base.addr_tf_bu()`: Before Update trigger
     - `base.comm_tf_bd()`: Before Delete trigger
     - `base.addr_tf_aiud()`: After Insert/Update/Delete trigger

4. **Triggers**: `module_name_object_name_tr_timing`
   - Example: `base_ent_tr_bi`

### Column Naming

Column names follow consistent patterns:

1. **Primary Keys**:
   - Single-column: `id` or `object_name_id`
   - Composite: `object_prefix_column` (e.g., `addr_ent`, `addr_seq`)

2. **Foreign Keys**:
   - Reference parent table name: `ent_id`, `acct_id`
   - Link table references: `parent_id`, `child_id`

3. **Common Columns**:
   - Status flags end with status word: `ent_inact`, `addr_priv`
   - Timestamps follow standard pattern: `crt_date`, `mod_date`
   - User tracking fields: `crt_by`, `mod_by`

4. **Specialized Naming**:
   - Type indicators use `_type` suffix: `addr_type`, `comm_type`
   - Primary indicators use `_prim` suffix: `addr_prim`
   - Comment fields use `_cmt` suffix: `addr_cmt`

## TCL Namespace Structure

Each module typically defines a TCL namespace containing utility functions and common column lists:

```tcl
namespace eval base {
    def addr_pk     {addr_ent addr_seq}
    def addr_v_in   {addr_ent addr_spec city state pcode country addr_cmt addr_type addr_prim addr_inact addr_priv}
    def addr_v_up   [lremove $addr_v_in addr_ent]
    def addr_se     [concat $addr_pk $addr_v_up $glob::stampfn]
}
```

These namespace definitions are used throughout the schema files for consistency and to reduce duplication.

## Common Patterns

### Standard Timestamps

Most tables include standard timestamp fields defined in `glob.tcl`:

```tcl
subst($glob::stamps)
```

This expands to:
```sql
crt_date timestamp default now(),
crt_by   text,
mod_date timestamp,
mod_by   text
```

### View Triggers

Wyselib uses helper functions to create updateable views:

```tcl
eval(trigview::insert base.addr_v base.addr $base::addr_v_in $base::addr_pk $glob::stampin)
eval(trigview::update base.addr_v base.addr $base::addr_v_up $base::addr_pk $glob::stampup)
eval(rule_delete base.addr_v base.addr $base::addr_pk)
```

### Display Definitions

UI display properties use YAML format:

```yaml
base.addr:
  focus: addr_spec
  fields:
  - [addr_seq, ent, 4, [10,1], {state: readonly, just: r}]
  - [city, ent, 24, [2,1], {}]
  display: [addr_type, addr_spec, state, city, pcode]
  sort: [addr_type, addr_seq]
```

## Extending the Schema

When adding new components to Wyselib:

1. **Follow the naming conventions** for consistency
2. **Use the appropriate module** or create a new one if needed
3. **Reference existing components** where applicable
4. **Define text strings** in corresponding .wmt files
5. **Add display properties** in .wmd files
6. **Create initialization scripts** in .wmi files if needed

See the base module components for examples of well-structured schema definitions.