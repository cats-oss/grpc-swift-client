import SwiftProtobufPluginLibrary

extension CodePrinter {
    mutating func println(_ text: String = "") {
        print(text)
        print("\n")
    }

    mutating func printScope(_ text: String, scope: (inout CodePrinter) -> Void) {
        println(text + " {")
        indent()
        scope(&self)
        outdent()
        println("}")
    }
}
