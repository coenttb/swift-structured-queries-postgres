/// # Join Operations Overview
///
/// This file serves as the entry point for join operation documentation.
/// The actual implementations are split across focused files:
///
/// - `Select+Join+Inner.swift` - INNER JOIN operations
/// - `Select+Join+Left.swift` - LEFT OUTER JOIN operations
/// - `Select+Join+Right.swift` - RIGHT OUTER JOIN operations
/// - `Select+Join+Full.swift` - FULL OUTER JOIN operations
///
/// ## Overload Resolution Strategy
///
/// Each join type provides 6 overloads to handle different combinations of
/// parameter pack configurations while working around Swift compiler limitations:
///
/// 1. **Primary** - Most general case with dual parameter packs for both caller and other
///    - Handles: Select with columns/joins + Select with columns/joins
///    - Signature: `<each C1, each C2, F, each J1, each J2>`
///
/// 2. **Optimization 1** - When other has no joins (`other.Joins == ()`)
///    - Handles: Select with columns/joins + Select with columns only
///    - Marked `@_disfavoredOverload` to avoid ambiguity with primary
///
/// 3. **Optimization 2** - When other has no columns (`other.Columns == ()`)
///    - Handles: Select with QueryValue + SelectOf (table only)
///    - Requires `QueryValue: QueryRepresentable` to distinguish from SelectOf
///
/// 4. **Where Delegation** - When caller is SelectOf (`self.Columns == (), self.Joins == ()`)
///    - Handles: Where.join() delegating to Select.join()
///    - Enables use of `some SelectStatement` instead of `any`
///
/// 5. **SelectOf Specialization** - Most specific case (both empty)
///    - Handles: SelectOf.join(SelectOf) - the common case
///    - NOT marked `@_disfavoredOverload` so it's preferred over others
///    - Provides optimal type inference for simple joins
///
/// 6. **Legacy** - When caller has joins but other is SelectOf
///    - Handles: Select with existing joins + SelectOf
///    - Marked `@_disfavoredOverload` as a fallback
///
/// ## Why So Many Overloads?
///
/// Swift's parameter pack system has limitations with opaque types (`some`):
/// - All overloads use `some SelectStatement` for proper type inference (no existentials)
/// - Parameter pack expansion in constraints causes overload resolution issues
/// - Need specific overloads for each combination to guide the compiler
/// - The 6-overload pattern enables `some` throughout (avoiding `any` entirely)
///
/// ## Outer Join Type Transformations
///
/// - `LEFT JOIN`: Optionalizes columns/joins from the right side
/// - `RIGHT JOIN`: Optionalizes columns/joins from the left side
/// - `FULL JOIN`: Optionalizes all columns/joins from both sides
/// - `INNER JOIN`: No type transformations
///
/// These transformations happen via the `._Optionalized` protocol requirement.
