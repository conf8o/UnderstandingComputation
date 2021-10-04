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

struct Empty: Pattern {
    var description: String { "" }
    var precedence: Int { 3 }
}

extension Empty: ToNFA {
    func toNFADesign() -> NFADesign {
        let startState = State.new
        let acceptStates: Set<State> = [startState]
        let mapping = NFATransitionMap(Dictionary())
        return NFADesign(startState: startState, acceptStates: acceptStates, transMap: mapping)
    }
}

struct Literal: Pattern {
    var char: Character
    var description: String { String(char) }
    var precedence: Int { 3 }
}

extension Literal: ToNFA {
    func toNFADesign() -> NFADesign {
        let startState = State.new
        let acceptState = State.new
        let transition = (startState~Symbol.symbol(char))~>acceptState
        let mapping = NFATransitionMap(transitions: [transition])
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

extension Concatenate: ToNFA {
    func toNFADesign() -> NFADesign {
        let firstNFADesign = (first as! Pattern & ToNFA).toNFADesign()
        let secondNFADesign = (second as! Pattern & ToNFA).toNFADesign()
        let startState = firstNFADesign.startState
        let acceptStates = secondNFADesign.acceptStates
        let mapping = firstNFADesign.transMap.merging(secondNFADesign.transMap)
        let extraMapping = NFATransitionMap(
            transitions: firstNFADesign.acceptStates.map { state in
                (state~Symbol.free)~>secondNFADesign.startState
            }
        )
        return NFADesign(
            startState: startState,
            acceptStates: acceptStates,
            transMap: mapping.merging(extraMapping)
        )
    }
}

struct Choose: Pattern {
    var first: Pattern
    var second: Pattern
    var description: String {
        [first, second].map { pattern in pattern.bracket(self.precedence) }.joined(separator: "|")
    }
    var precedence: Int { 0 }
}

extension Choose: ToNFA {
    func toNFADesign() -> NFADesign {
        let firstNFADesign = (first as! Pattern & ToNFA).toNFADesign()
        let secondNFADesing = (second as! Pattern & ToNFA).toNFADesign()
        
        let startState = State.new
        let acceptStates = firstNFADesign.acceptStates.union(secondNFADesing.acceptStates)
        let mapping = firstNFADesign.transMap.merging(secondNFADesing.transMap)
        let extraMapping = NFATransitionMap(
            transitions: [
                (startState~Symbol.free)~>firstNFADesign.startState,
                (startState~Symbol.free)~>secondNFADesing.startState
            ]
        )
        return NFADesign(
            startState: startState,
            acceptStates: acceptStates,
            transMap: mapping.merging(extraMapping))
    }
}

struct Repeat: Pattern {
    var pattern: Pattern
    var description: String {
        "\(pattern.bracket(self.precedence))*"
    }
    var precedence: Int { 2 }
}

public func patternMain() {
    let pattern = Repeat(
        pattern: Choose(
            first: Concatenate(
                first: Literal(char: "a"),
                second: Literal(char: "b")
            ),
            second: Literal(char: "a")
        )
    )
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
    
    d = Concatenate(
        first: Literal(char: "a"),
        second: Concatenate(
            first: Literal(char: "b"),
            second: Literal(char: "c")
        )
    ).toNFADesign()
    print(d.canAccept(str: "a"))
    print(d.canAccept(str: "ab"))
    print(d.canAccept(str: "abc"))
}
