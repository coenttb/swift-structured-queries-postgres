import SwiftSyntax

extension SyntaxProtocol {
  func rewritten(_ rewriter: SyntaxRewriter) -> Self {
    rewriter.rewrite(self).cast(Self.self)
  }
}

final class SelfRewriter: SyntaxRewriter {
  let selfEquivalent: TokenSyntax

  init(selfEquivalent: TokenSyntax) {
    self.selfEquivalent = selfEquivalent
  }

  override func visit(_ token: TokenSyntax) -> TokenSyntax {
    guard token.tokenKind == .keyword(.Self)
    else { return super.visit(token) }
    return super.visit(selfEquivalent)
  }
}
