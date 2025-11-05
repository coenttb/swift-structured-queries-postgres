// MARK: - Select Extension

extension Select {
    /// Creates a new select statement from this one by defining a named window specification.
    ///
    /// Named windows allow you to define a window specification once and reference it multiple times,
    /// reducing repetition and improving query readability.
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// Employee
    ///     .window("dept_window") { spec, cols in
    ///         spec.partition(by: cols.department).order(by: cols.salary.desc())
    ///     }
    ///     .select {
    ///         ($0.name, rank().over("dept_window"))
    ///     }
    /// ```
    ///
    /// Or using shorthand parameter names:
    ///
    /// ```swift
    /// Employee
    ///     .window("dept_window") {
    ///         $0.partition(by: $1.department).order(by: $1.salary.desc())
    ///     }
    ///     .select {
    ///         ($0.name, rank().over("dept_window"))
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - name: The name for this window specification
    ///   - builder: A closure that receives a WindowSpec and table columns, returns configured WindowSpec
    /// - Returns: A new select statement with the named window added
    public func window<each J: Table>(
        _ name: String,
        _ builder:
            @escaping (WindowSpec, From.TableColumns, repeat (each J).TableColumns) -> WindowSpec
    ) -> Self
    where Joins == (repeat each J) {
        let spec = builder(WindowSpec(), From.columns, repeat (each J).columns)
        let specification = spec.generateSpecificationFragment()

        var select = self
        select.windows.append((name: name, specification: specification))
        return select
    }

    /// Creates a new select statement from this one by defining a named window specification.
    ///
    /// This overload is for selects without joins.
    ///
    /// - Parameters:
    ///   - name: The name for this window specification
    ///   - builder: A closure that receives a WindowSpec and table columns, returns configured WindowSpec
    /// - Returns: A new select statement with the named window added
    public func window(
        _ name: String,
        _ builder: @escaping (WindowSpec, From.TableColumns) -> WindowSpec
    ) -> Self
    where Joins == () {
        let spec = builder(WindowSpec(), From.columns)
        let specification = spec.generateSpecificationFragment()

        var select = self
        select.windows.append((name: name, specification: specification))
        return select
    }
}

// MARK: - Table Extension (Delegation)

extension Table {
    /// Creates a select statement with a named window specification.
    ///
    /// This is a convenience method that delegates to Where.window().
    ///
    /// - Parameters:
    ///   - name: The name for this window specification
    ///   - builder: A closure that receives a WindowSpec and table columns, returns configured WindowSpec
    /// - Returns: A new select statement with the named window added
    public static func window(
        _ name: String,
        _ builder: @escaping (WindowSpec, TableColumns) -> WindowSpec
    ) -> SelectOf<Self> {
        Where().window(name, builder)
    }
}

// MARK: - Where Extension (Delegation)

extension Where {
    /// Creates a new select statement from this where clause by defining a named window specification.
    ///
    /// This is a convenience method that delegates to Select.window().
    ///
    /// - Parameters:
    ///   - name: The name for this window specification
    ///   - builder: A closure that receives a WindowSpec and table columns, returns configured WindowSpec
    /// - Returns: A new select statement with the named window added
    public func window(
        _ name: String,
        _ builder: @escaping (WindowSpec, From.TableColumns) -> WindowSpec
    ) -> SelectOf<From> {
        asSelect().window(name, builder)
    }
}
