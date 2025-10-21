# The Aggregate Function API Challenge

**Date:** 2025-10-16
**Context:** swift-structured-queries-postgres library
**Problem:** Designing a beautiful, type-safe API for SQL aggregate functions in Swift

---

## Executive Summary

This document analyzes a challenging type system problem encountered while attempting to expand aggregate function APIs (MIN, MAX, AVG, SUM) to match the existing COUNT implementation. The core issue involves Swift's opaque result types, phantom type parameters, and the tension between API ergonomics and type system expressiveness.

**Current Status:** The low-level QueryExpression extensions (`.sum()`, `.min()`, `.max()`, `.avg()`) work perfectly. The high-level convenience extensions (Table+, Where+, Select+) face insurmountable type inference challenges.

---

## 1. Desired API Design

### Goal: Beautiful, Ergonomic Syntax

The ideal API should support both KeyPath and closure syntax with automatic conversion:

```swift
// ✅ DESIRED: KeyPath syntax (auto-converts to closure)
Product.min(of: \.price)
Product.max(of: \.price)
Product.avg(of: \.price)
Product.sum(of: \.amount)

// ✅ DESIRED: Closure syntax (for complex expressions)
Order.sum(of: { $0.quantity * $0.unitPrice })
Order.avg(of: { $0.price * (1 + $0.taxRate) })

// ✅ DESIRED: With FILTER clause
Order.sum(of: \.amount, filter: { $0.status == "completed" })

// ✅ DESIRED: Chainable after WHERE
Product.where { $0.inStock }.avg(of: \.price)
```

### Academic Context: The KeyPath→Closure Conversion

Swift's type system allows automatic conversion from KeyPath to closure through **function overloading resolution**. When a function accepts a closure `(T) -> U`, Swift will automatically convert a KeyPath `\T.property` to the equivalent closure `{ $0.property }`.

This is a form of **syntactic sugar** that provides **dual interface ergonomics** without requiring two separate implementations.

---

## 2. The Working Implementation (COUNT)

### Why COUNT is Special

The COUNT aggregate works beautifully across all three extension points:

```swift
// Table extension
extension Table {
    public static func count(
        filter: ((TableColumns) -> some QueryExpression<Bool>)? = nil
    ) -> Select<Int, Self, ()> {
        Where().count(filter: filter)
    }
}

// Where extension
extension Where {
    public func count(
        filter: ((From.TableColumns) -> some QueryExpression<Bool>)? = nil
    ) -> Select<Int, From, ()> {
        let filter = filter?(From.columns)
        return asSelect().select { _ in .count(filter: filter) }
    }
}
```

**Key observation:** COUNT always returns `Select<Int, From, ()>` - a **concrete, monomorphic type**. There's no generic type parameter dependent on the input expression.

### Academic Analysis: Monomorphic vs Polymorphic Return Types

COUNT exhibits **parametric monomorphism** - while the function itself is generic over `From: Table`, the return type's `Columns` parameter is always `Int`, regardless of input.

In contrast, MIN/MAX/AVG/SUM exhibit **return type polymorphism** - the return type's `Columns` parameter depends on the input expression's type.

---

## 3. The Core Technical Challenge

### 3.1 Phantom Type Parameters

The aggregate functions use Swift's **phantom types** pattern:

```swift
extension QueryExpression where QueryValue: _OptionalPromotable {
    public func min(filter: ...) -> some QueryExpression<QueryValue._Optionalized.Wrapped?> {
        AggregateFunction("min", [queryFragment], filter: filter?.queryFragment)
    }
}
```

**Academic context:** Phantom types are types that appear in a generic signature but not in the value representation. Here, `QueryValue` is a phantom type parameter that exists only at the type level to track SQL column types.

### 3.2 The _OptionalPromotable Protocol

This is a **type-level function** that computes optional variants:

```swift
protocol _OptionalPromotable {
    associatedtype _Optionalized
}

// For non-optional T:
// T._Optionalized = T?
// T._Optionalized.Wrapped = T

// For optional T?:
// T?._Optionalized = T?
// T?._Optionalized.Wrapped = T
```

**Academic context:** This is an example of **type-level computation** using associated types. The type system computes a canonical optional representation at compile time.

### 3.3 Type Mismatch Problem

When we try to specify a return type for aggregate extensions:

```swift
// ❌ ATTEMPT 1: Specify return type as Value?
extension Where {
    public func sum<Value>(
        of expression: (From.TableColumns) -> some QueryExpression<Value>,
        filter: ...
    ) -> Select<Value?, From, ()>  // ❌ Type mismatch!
    where Value: Numeric {
        return asSelect().select { expression($0).sum(filter: ...) }
    }
}
```

**Error:**
```
cannot convert return expression of type
  'Select<(some QueryExpression<Optional<Value._Optionalized.Wrapped>>).QueryValue, From, ()>'
to return type
  'Select<Value?, From, ()>'
```

**Why this fails:**

The `.sum()` method returns `QueryExpression<Value._Optionalized.Wrapped?>`, NOT `QueryExpression<Value?>`.

These types are **not equivalent** in Swift's type system, even though they represent the same underlying optional type at runtime.

### Academic Analysis: Type Equivalence vs Value Equivalence

This is a manifestation of **nominal typing** vs **structural typing**:

- **Structural equivalence:** Two types are equivalent if they have the same structure
- **Nominal equivalence:** Two types are equivalent only if they have the same name

Swift uses nominal typing for type parameters. Even though `Value?` and `Value._Optionalized.Wrapped?` are structurally equivalent (both are optional variants of the same base type), they are nominally distinct because they're expressed through different type paths.

---

## 4. Attempted Solutions

### 4.1 Explicit Type Constraints (Failed)

```swift
// ❌ ATTEMPT 2: Add all required constraints
extension Where {
    public func sum<Value, Expr: QueryExpression<Value>>(
        of expression: (From.TableColumns) -> Expr,
        filter: ...
    ) -> Select<Expr.QueryValue._Optionalized.Wrapped?, From, ()>
    where
        Value: Numeric,
        Expr.QueryValue: _OptionalPromotable,
        Expr.QueryValue._Optionalized.Wrapped: Numeric,
        Expr.QueryValue._Optionalized.Wrapped: QueryRepresentable  // ← Still missing!
    {
        ...
    }
}
```

**Error:**
```
no exact matches in call to instance method 'select'
candidate requires that 'Value._Optionalized.Wrapped' conform to 'QueryRepresentable'
```

**Why this fails:**

The constraint `Expr.QueryValue._Optionalized.Wrapped: QueryRepresentable` is **not inferrable** from the existing constraints. Swift's constraint solver cannot prove this relationship transitively.

### Academic Analysis: Constraint Inference and Decidability

This is related to the **constraint satisfaction problem (CSP)** in type inference. Swift's type checker uses a **greedy, incomplete algorithm** for constraint solving. Some valid constraint relationships are not discoverable by the algorithm, even though they're provable in a complete type theory.

The constraint graph looks like:
```
Value: Numeric
  ↓
Expr: QueryExpression<Value>
  ↓
Expr.QueryValue: _OptionalPromotable
  ↓
Expr.QueryValue._Optionalized.Wrapped: Numeric
  ↓
Expr.QueryValue._Optionalized.Wrapped: ??? QueryRepresentable ???
```

The final constraint is **non-local** - it depends on relationships not explicitly stated in the function signature.

### 4.2 Omit Return Type (Failed)

```swift
// ❌ ATTEMPT 3: Let Swift infer the return type
extension Where {
    public func sum<Value>(
        of expression: (From.TableColumns) -> some QueryExpression<Value>,
        filter: ...
    ) where Value: Numeric {  // ← No return type!
        let filterExpr = filter?(From.columns)
        return asSelect().select { expression($0).sum(filter: filterExpr) }
    }
}
```

**Error:**
```
unexpected non-void return value in void function
```

**Why this fails:**

Without a return type annotation, Swift assumes the function returns `Void`. This is a **language design decision** to avoid ambiguity.

### Academic Analysis: Type Inference Direction

This relates to **bidirectional type checking**:
- **Top-down (analysis mode):** Return type is known, propagate constraints downward
- **Bottom-up (synthesis mode):** Return type is unknown, synthesize from body

Swift requires an explicit return type for **top-down checking** of complex generic functions. Pure synthesis mode is only supported for simple cases.

### 4.3 Opaque Return Type (Failed)

```swift
// ❌ ATTEMPT 4: Use opaque return type
extension Where {
    public func sum<Value>(
        of expression: (From.TableColumns) -> some QueryExpression<Value>,
        filter: ...
    ) -> some Select  // ❌ Can't use 'some' with struct!
    where Value: Numeric {
        ...
    }
}
```

**Error:**
```
reference to generic type 'Select' requires arguments in <...>
a 'some' type must specify only 'Any', 'AnyObject', protocols, and/or a base class
```

**Why this fails:**

`Select` is a **concrete generic struct**, not a protocol. Swift's `some` keyword only works with:
1. Protocols (e.g., `some Collection`)
2. Protocol compositions (e.g., `some Collection & Hashable`)
3. Base classes (e.g., `some NSObject`)

It does NOT work with generic structs like `Select<Columns, From, Joins>`.

### Academic Analysis: Existential Types vs Opaque Types

This is a limitation of Swift's **opaque result types** feature:

- **Existential types** (`any Protocol`): Type-erased, runtime polymorphism
- **Opaque result types** (`some Protocol`): Compile-time polymorphism, preserves identity

Generic structs require **full type specification** because:
1. They have value semantics (no vtable)
2. They need compile-time layout computation
3. They don't support subtyping/variance

---

## 5. Why This is Fundamentally Hard

### 5.1 The Type Theory Perspective

This problem sits at the intersection of several type system features:

1. **Higher-kinded types:** `_OptionalPromotable` is essentially a type-level function
2. **Associated type constraints:** The `_Optionalized` associated type creates dependent relationships
3. **Phantom types:** `QueryValue` exists only at the type level
4. **Opaque result types:** The `some QueryExpression<T>` syntax hides the concrete type
5. **Generic constraints:** The complex web of `where` clauses

**Academic context:** This is reminiscent of **System F<:** (System F with subtyping) where constraint solving becomes **undecidable** in the general case.

### 5.2 The Language Design Perspective

Swift made deliberate trade-offs:

**Choice 1:** Nominal typing over structural typing
→ Consequence: `Value?` ≠ `Value._Optionalized.Wrapped?`

**Choice 2:** Incomplete constraint solver
→ Consequence: Some valid programs are rejected

**Choice 3:** Explicit return types for complex generics
→ Consequence: Cannot purely synthesize types for polymorphic returns

**Choice 4:** `some` only for protocols
→ Consequence: Cannot hide generic struct parameters

### 5.3 The API Design Perspective

There's a fundamental tension between:

- **Type safety:** Preserving full type information
- **Ergonomics:** Hiding implementation details
- **Expressiveness:** Supporting complex generic relationships

COUNT succeeds because it sidesteps this entirely with a monomorphic return type.

---

## 6. Academic Parallels

### 6.1 The Expression Problem

This is a variant of the **expression problem** (Wadler, 1998):

> How do you add new operations to existing types without modifying existing code?

Here, we're trying to add new convenience methods (`sum(of:)`) to existing types (`Table`, `Where`, `Select`) that preserve the type relationships of existing operations (`.sum()`).

### 6.2 Type Classes vs Protocols

Swift's protocols are similar to Haskell's **type classes**, but with key differences:

**Haskell approach:**
```haskell
-- This would work in Haskell!
sum :: (Numeric a, Table t) => t -> (t -> a) -> Query (Maybe a)
sum table selector = select table (aggregateSum . selector)
```

Haskell's constraint solver is more powerful because:
1. It uses **coherence checking** (global uniqueness of instances)
2. It supports **multi-parameter type classes**
3. It has **functional dependencies** and **type families**

**Swift approach:**
Swift protocols are **local** and **nominal**, making constraint inference harder.

### 6.3 Dependent Types

A **dependently-typed** language (like Idris or Agda) could express this naturally:

```idris
sum : (t : Table) -> (selector : TableColumns t -> Expression a)
   -> Select (Optional (Unwrap (OptionalPromote a)))
```

The return type **depends on the value** of the input expression's type.

Swift's type system is not dependently typed, so these relationships cannot be expressed directly.

---

## 7. Possible Future Solutions

### 7.1 Language Evolution

**SE-XXXX: Improved Opaque Result Types**

Allow `some` with generic types:
```swift
func sum<Value>(...) -> some Select<_, Self, ()> where Value: Numeric
//                                    ↑
//                              Wildcard type parameter
```

**SE-XXXX: Associated Type Constraints in Return Position**

Allow return types to reference associated types more flexibly:
```swift
func sum<Value, E: QueryExpression<Value>>(...)
-> Select<E.QueryValue.Canonical Optional, From, ()>
//        ↑
//        Hypothetical canonical type computation
```

### 7.2 Library Evolution

**Option A: Type Alias Bridge**

```swift
// Define a type alias that captures the relationship
typealias AggregateResult<Value> = Value._Optionalized.Wrapped?

func sum<Value>(...) -> Select<AggregateResult<Value>, From, ()>
```

**Status:** Doesn't work - type aliases don't solve constraint inference

**Option B: Wrapper Types**

```swift
struct AggregateExpression<Value> {
    let expression: some QueryExpression<Value>
}

func sum(of expr: AggregateExpression<Value>) -> Select<Value?, From, ()>
```

**Status:** Loses KeyPath→Closure conversion

**Option C: Builder Pattern**

```swift
Table
    .aggregate()
    .sum(of: \.amount)
    .build()
```

**Status:** Verbose, loses directness

### 7.3 Pragmatic Compromise

**Accept the limitation and document it:**

```swift
// ✅ WORKS: Low-level API
Product.select { $0.price.sum() }

// ❌ DOESN'T WORK: High-level convenience API
Product.sum(of: \.price)
```

**Rationale:**
- The low-level API is complete and type-safe
- The high-level API would be nice-to-have but not essential
- Fighting the type system creates maintenance burden

---

## 8. Conclusion

This challenge illustrates deep tensions in programming language design:

1. **Expressiveness vs Decidability:** More powerful type systems are harder to implement
2. **Safety vs Ergonomics:** Stronger guarantees often require more annotations
3. **Local vs Global Reasoning:** Swift's local constraint solving limits what's inferrable

The COUNT implementation works because it avoids these issues through monomorphic return types. Generalizing to polymorphic aggregates requires type system features Swift doesn't (yet) have.

### Recommendations

**Short term:**
- Keep only the QueryExpression+ extensions (`.sum()`, `.min()`, `.max()`, `.avg()`)
- Document the type system limitation
- Provide examples of the working low-level API

**Long term:**
- Monitor Swift Evolution proposals for relevant features
- Consider contributing an evolution proposal if/when appropriate
- Revisit when Swift's type system evolves

---

## References

1. **Wadler, P. (1998).** "The Expression Problem." Java Generics mailing list.
2. **Pierce, B. C. (2002).** *Types and Programming Languages*. MIT Press.
3. **Swift Team (2023).** Swift Language Guide - Opaque Types.
4. **Lattner, C. et al. (2020).** "Swift: A Type-Safe Systems Programming Language." (Informal documentation)

---

## Appendix: Full Error Trace

```
/Sources/.../Sum/Select+Sum.swift:20:16: error: no exact matches in call to instance method 'select'
18 |     where Value: Numeric, Expr.QueryValue: _OptionalPromotable, Expr.QueryValue._Optionalized.Wrapped: Numeric {
19 |         let filterExpr = filter?(From.columns)
20 |         return select { expression($0).sum(filter: filterExpr) }
   |                `- error: no exact matches in call to instance method 'select'

/Sources/.../Optional.swift:63:1: note: candidate requires that 'Value._Optionalized.Wrapped' conform to 'QueryRepresentable'
63 | extension Optional: QueryRepresentable where Wrapped: QueryRepresentable {
   | |- note: candidate requires that 'Value._Optionalized.Wrapped' conform to 'QueryRepresentable'
```

This error demonstrates the constraint inference gap: the type checker needs `Value._Optionalized.Wrapped: QueryRepresentable` but cannot derive it from the stated constraints.

---

**Document Status:** Complete technical and academic analysis
**Next Steps:** Share with Swift community / Consider evolution proposal
