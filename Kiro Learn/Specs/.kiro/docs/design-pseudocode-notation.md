# Design Document Pseudocode Notation

This document describes the pseudocode notation used in Kiro-generated design documents for defining component interfaces and data models.

## Purpose

The notation provides a language-neutral way to describe software contracts — function signatures, data structures, and type relationships — without coupling to a specific programming language. It prioritizes human readability over machine parsability.

## Code Fence Language

All pseudocode blocks use ` ```python ` as the code fence language tag. This is for syntax highlighting convenience only — the content is not valid Python.

---

## INTERFACE Blocks

Define the public contract of a component (module, class, or service).

### Syntax

```
INTERFACE <Name>:
    FUNCTION <name>(<param>: <type>, ...) -> <return_type>
```

### Rules

- `INTERFACE` keyword followed by the component name and a colon
- Each function is declared with the `FUNCTION` keyword
- Parameters use `name: type` syntax (Python-style type hints)
- Return type follows `->` arrow notation
- No method bodies — signatures only
- Indentation is 4 spaces

### Example

```python
INTERFACE RevisionManager:
    FUNCTION create_revision_bucket(bucket_name: string) -> None
    FUNCTION upload_revision(bucket_name: string, bundle_path: string, key: string) -> string
    FUNCTION get_revision_location(bucket_name: string, key: string) -> Dictionary
```

---

## TYPE Blocks

Define data structures (equivalent to dataclasses, TypedDicts, structs, or interfaces depending on the target language).

### Syntax

```
TYPE <Name>:
    <field_name>: <type>              # optional inline comment
    <field_name>?: <type>             # optional field
```

### Rules

- `TYPE` keyword followed by the structure name and a colon
- Each field uses `name: type` syntax
- Optional fields are marked with `?` before the colon: `field_name?: type`
- Inline comments (after `#`) document allowed values or constraints
- Indentation is 4 spaces

### Example

```python
TYPE DeploymentStatus:
    deployment_id: string
    status: string              # "Created", "InProgress", "Succeeded", "Failed"
    create_time: datetime
    complete_time?: datetime
    error_info?: Dictionary
```

---

## Primitive Types

| Type | Description |
|------|-------------|
| `string` | Text value |
| `integer` | Whole number |
| `boolean` | `true` or `false` |
| `datetime` | Date and time value |
| `None` | No return value (void) |

## Collection Types

| Type | Description |
|------|-------------|
| `List[T]` | Ordered collection of type T |
| `Dictionary` | Key-value map (untyped) |
| `Dictionary[K, V]` | Key-value map with typed keys and values |

## Custom Types

Any `TYPE` defined in the same document can be referenced by name in other `TYPE` or `INTERFACE` blocks:

```python
TYPE InstanceTarget:
    target_id: string
    lifecycle_events: List[LifecycleEvent]
```

---

## Influences

The notation borrows conventions from multiple sources:

| Element | Origin |
|---------|--------|
| `INTERFACE`, `FUNCTION`, `TYPE` keywords | Pascal/Ada-style structured pseudocode |
| `name: type` annotations | Python type hints (PEP 484) |
| `-> return_type` | Python return type annotation |
| `field?` optional marker | TypeScript optional property syntax |
| `List[T]`, `Dictionary` | Python typing module |

## Limitations

- Not formally specified or parsable by any tool
- No support for generics beyond `List[T]` and `Dictionary[K, V]`
- No visibility modifiers (public/private)
- No inheritance or composition syntax
- No error/exception declarations on function signatures
