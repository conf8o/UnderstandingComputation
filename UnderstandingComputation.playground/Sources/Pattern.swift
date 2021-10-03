import Foundation

protocol Pattern: CustomStringConvertible {
    var precedence: Int { get }
}
extension Pattern {
    func bracket(_ outer_precedence: Int) -> String {
        self.precedence < outer_precedence ? "(\(description))" : description
    }
}

protocol ToNFA {
    func toNFADesign() -> NFADesign
}

extension Pattern where Self: ToNFA {
    func matches(_ str: String) -> Bool {
        toNFADesign().canAccept(str: str)
    }
}

struct Empty: Pattern, ToNFA {
    var description: String { "" }
    var precedence: Int { 3 }
    func toNFADesign() -> NFADesign {
        let startState = State.new
        let acceptStates: Set<State> = [startState]
        let mapping = NFATransitionMap([])
        return NFADesign(startState: startState, acceptStates: acceptStates, transMap: mapping)
    }
}

struct Literal: Pattern, ToNFA {
    var char: Character
    var description: String { String(char) }
    var precedence: Int { 3 }
    func toNFADesign() -> NFADesign {
        let startState = State.new
        let acceptState = State.new
        let transition = (startState~Symbol.symbol(char))~>acceptState
        let mapping = NFATransitionMap([transition])
        return NFADesign(startState: startState, acceptStates: [acceptState], transMap: mapping)
    }
}

struct Concatenate: Pattern {
    var first: Pattern
    var second: Pattern
    var description: String {
        [first, second].map { pattern in pattern.bracket(self.precedence) }.joined(separator: "")
    }
    var precedence: Int { 1 }
}

struct Choose: Pattern {
    var first: Pattern
    var second: Pattern
    var description: String {
        [first, second].map { pattern in pattern.bracket(self.precedence) }.joined(separator: "|")
    }
    var precedence: Int { 0 }
}

struct Repeat: Pattern {
    var pattern: Pattern
    var description: String {
        "\(pattern.bracket(self.precedence))*"
    }
    var precedence: Int { 2 }
}

public func patternMain() {
    let pattern = Repeat(pattern: Choose(first: Concatenate(first: Literal(char: "a"),
                                                            second: Literal(char: "b")),
                                         second: Literal(char: "a")))
    print(pattern)
    
    var d = Empty().toNFADesign()
    print(d.canAccept(str: ""))
    print(d.canAccept(str: "a"))
    
    d = Literal(char: "a").toNFADesign()
    print(d.canAccept(str: ""))
    print(d.canAccept(str: "a"))
    print(d.canAccept(str: "b"))
    
    print(Empty().matches("a"))
    print(Literal(char: "a").matches("a"))
}
