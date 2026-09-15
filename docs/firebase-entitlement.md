# Lanske Entitlement foundation

## Purpose

web #221 introduces the minimum Entitlement boundary used to answer:

- whether a feature is available
- whether the entitlement itself imposes a usage limit

Entitlement remains separate from Role, Plan, resource Permission, and Usage.

```text
Role
  system position, such as admin

Plan
  contract state, such as free / premium

Entitlement
  feature availability and limit

Permission
  operation allowed for a specific resource

Usage
  actual consumption counted against a limit
```

This issue intentionally does not define Lanske's full Premium feature set or
persist usage counters.

## Domain model

`EntitlementFeature` is a typed feature key.

Production feature keys are not predeclared by web #221. A feature should add
its key only when the feature is actually implemented.

`Entitlement` contains:

```text
available: bool
usageLimit: int?
```

When `available == true`:

- a finite `usageLimit` is the maximum usage allowed by this entitlement
- `usageLimit == null` means the entitlement itself imposes no usage limit

When `available == false`, `usageLimit` is null.

The entitlement does not contain current usage. Usage is a separate concern.

## Resolver boundary

Callers depend on `EntitlementResolver` rather than checking Plan or Role
directly.

`RolePlanEntitlementResolver` receives:

- `AdminRoleReader`
- `PlanReader`
- feature-specific rules

Conceptually:

```text
AdminRoleReader --+
                  +--> EntitlementResolver --> Entitlement
PlanReader -------+
```

A rule receives an `EntitlementContext` containing:

```text
plan: LanskePlan?
isAdmin: bool
```

This allows different features to express different policies without turning
Role or Plan into one global hierarchy.

For example, one later feature may give an administrator an unlimited usage
limit while another Premium-only feature may remain unavailable to an
administrator on the free Plan.

## Fail-closed behavior

A feature without a registered rule resolves to:

```text
Entitlement.unavailable()
```

The resolver does not read Role or Plan for an unknown feature.

Errors while reading a known feature's trusted inputs are not converted into
an available entitlement. Callers must not treat resolver failures as
authorization success.

## Role and Plan separation

Administrator Role is provided by web #216 from Firebase Authentication Custom
Claims.

Account Plan is provided by web #220 from the protected registered-user
document.

Neither implies the other.

```text
admin + free
admin + premium
user + free
user + premium
```

can all be represented without changing the Entitlement API.

Administrator-only operations themselves are Role / Permission concerns, not
Premium Entitlements.

## Permission boundary

Entitlement does not answer whether the current user may operate on a
particular event or other resource.

Examples such as:

- can manage this event
- can write this result
- can progress this shared event

remain resource Permission decisions. Event-specific Permission is handled by
web #196.

## Usage boundary

Entitlement answers the configured limit, not how much has already been used.

```text
Entitlement
  usageLimit = 10

Usage
  consumed = 4
```

Persistent counters, reset periods, monthly quotas, and related write
protection are deferred until a concrete feature needs usage enforcement.

## No Firestore Entitlement documents

web #221 does not add a generic Entitlement collection or user-document field.

Current Entitlements are derived by feature-specific rules from trusted
inputs such as Role and Plan.

If future requirements need persisted grants, exceptions, or server-side
enforcement, that storage can be added behind the same resolver boundary
without making current callers depend directly on the persistence model.
