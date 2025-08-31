import SwiftSyntax
import SwiftSyntaxBuilder

extension SyntaxStringInterpolation {
  mutating func appendInterpolation<Node: SyntaxProtocol>(_ nodes: [Node], separator: String) {
    guard let first = nodes.first else { return }
    appendInterpolation(first)
    for node in nodes.dropFirst() {
      appendInterpolation(raw: separator)
      appendInterpolation(node)
    }
  }

  mutating func appendInterpolation<Node: SyntaxProtocol>(_ node: Node?) {
    guard let node else { return }
    appendInterpolation(node)
  }
}
