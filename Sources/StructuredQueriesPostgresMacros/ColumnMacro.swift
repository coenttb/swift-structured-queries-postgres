import SwiftSyntax
import SwiftSyntaxMacros

public enum ColumnMacro: PeerMacro {
    public static func expansion<D: DeclSyntaxProtocol, C: MacroExpansionContext>(
        of node: AttributeSyntax,
        providingPeersOf declaration: D,
        in context: C
    ) throws -> [DeclSyntax] {
        // swiftlint:disable:previous typed_throws_required
        // reason: fork-heritage untyped-throws surface (pointfreeco/swift-structured-queries)
        []
    }
}
