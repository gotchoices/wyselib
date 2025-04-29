# Contributing to Wyselib

This document provides guidelines for extending and improving the Wyselib schema library.

## Development Principles

1. **Consistency**: Follow the established naming conventions and patterns
2. **Modularity**: Keep related components together in appropriate modules
3. **Documentation**: Update documentation when adding or changing components
4. **Testing**: Create test cases for new functionality
5. **Compatibility**: Maintain backward compatibility when possible

## Porting Legacy Components

Several Wyselib modules need to be ported to the current Wyseman standards:

1. **Update TCL syntax** to match modern Wyseman expectations
2. **Convert display definitions** to YAML format
3. **Update trigger functions** to use current patterns
4. **Add comprehensive documentation** for all components

## Adding New Components

When adding new schema components to Wyselib:

1. **Place files in appropriate module directory**
2. **Create all required file types**:
   - `.wms` - Schema definition
   - `.wmt` - Text strings
   - `.wmd` - Display properties
   - `.wmi` - Initialization (if needed)
3. **Follow naming conventions** described in [Schema Structure](schema-structure.md)
4. **Define proper dependencies** between objects
5. **Add appropriate permissions** using grant syntax
6. **Update documentation** to describe new components

## Testing Changes

Test your changes using:

1. **Wyseman validation** to check schema syntax
2. **Database loading** to verify proper object creation
3. **UI testing** to confirm display property functionality
4. **Runtime testing** for functional components

## Documentation Updates

When updating documentation:

1. **Reference existing patterns** in the base module
2. **Include key features and usage examples**
3. **Document integration points** with other components
4. **Update the main README** if adding significant functionality