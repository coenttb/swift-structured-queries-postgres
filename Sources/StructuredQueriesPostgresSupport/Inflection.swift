extension String {
  package func lowerCamelCased() -> String {
    var prefix = prefix(while: \.isUppercase)
    if prefix.count > 1 { prefix = prefix.dropLast() }
    return prefix.lowercased() + dropFirst(prefix.count)
  }

  // NB: This is a minimal attempt to provide common pluralizations.
  //     We don't plan/want to cover every corner case.
  //     Instead, folks should leverage '@Table("name")'.
  package func pluralized() -> String {
    var bytes = self[...].utf8
    guard !bytes.isEmpty else { return self }

    switch bytes.removeLast() {
    case UInt8(ascii: "h"):
      switch bytes.last {
      case UInt8(ascii: "c"), UInt8(ascii: "s"):
        return "\(self)es"
      default:
        break
      }

    case UInt8(ascii: "s"), UInt8(ascii: "x"), UInt8(ascii: "z"):
      return "\(self)es"

    case UInt8(ascii: "y"):
      switch bytes.last {
      case UInt8(ascii: "a"),
        UInt8(ascii: "e"),
        UInt8(ascii: "i"),
        UInt8(ascii: "o"),
        UInt8(ascii: "u"),
        UInt8(ascii: "y"):
        break
      default:
        return "\(dropLast())ies"
      }

    default:
      break
    }

    return "\(self)s"
  }
}
