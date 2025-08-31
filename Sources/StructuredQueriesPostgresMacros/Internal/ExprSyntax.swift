import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder

extension ExprSyntax {
  var literalType: TypeSyntax? {
    if self.is(BooleanLiteralExprSyntax.self) {
      return "Swift.Bool"
    } else if self.is(FloatLiteralExprSyntax.self) {
      return "Swift.Double"
    } else if self.is(IntegerLiteralExprSyntax.self) {
      return "Swift.Int"
    } else if self.is(StringLiteralExprSyntax.self) {
      return "Swift.String"
    } else {
      return nil
    }
  }

  var isNonEmptyStringLiteral: Bool {
    guard let literal = self.as(StringLiteralExprSyntax.self)?.representedLiteralValue
    else { return false }
    return !literal.isEmpty
  }
}
