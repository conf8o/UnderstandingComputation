import Foundation

typealias State = (Int)
var globalStateCount = 0
extension State {
    static var new: State {
        let x = globalStateCount
        globalStateCount += 1
        return x
    }
}

enum Symbol: ExpressibleByStringLiteral {
    case symbol(Character)
    case free
    
    init(stringLiteral: StringLiteralType) {
        self = .symbol(Character(stringLiteral))
    }
}

struct FATransitionInput: CustomStringConvertible {
    var state: State
    var symbol: Symbol
    var description: String { "\(state)\(symbol)" }
}

struct FATransition {
    var input: FATransitionInput
    var output: State
}

infix operator ~: AdditionPrecedence
func ~ (state: State, symbol: Symbol) -> FATransitionInput {
    FATransitionInput(state: state, symbol: symbol)
}

infix operator ~>: AdditionPrecedence
func ~> (input: FATransitionInput, output: State) -> FATransition {
    FATransition(input: input, output: output)
}

struct DFATransitionMap {
    var mapping: [String: State]
    init(_ rules: [FATransition]) {
        mapping = Dictionary(uniqueKeysWithValues: rules.map { rule in (rule.input.description, rule.output) })
    }
    func nextState(state: State, symbol: Symbol) -> State {
        let input = FATransitionInput(state: state, symbol: symbol)
        guard let output = mapping[input.description] else {
            fatalError("invalid input: \(input)")
        }
        
        return output
    }
    subscript(state: State, symbol: Symbol) -> State {
        nextState(state: state, symbol: symbol)
    }
}

struct DFA {
    var currentState: State
    var acceptStates: Set<State>
    var transMap: DFATransitionMap
    
    var accepting: Bool {
        acceptStates.contains(currentState)
    }
    
    mutating func readSymbol(symbol: Symbol) {
        currentState = transMap.nextState(state: currentState, symbol: symbol)
    }
    
    mutating func readSymbols(str: String) {
        for symbol in str {
            readSymbol(symbol: .symbol(symbol))
        }
    }
}

struct DFADesign {
    var startState: State
    var acceptStates: Set<State>
    var transMap: DFATransitionMap
    
    func newDFA() -> DFA {
        DFA(currentState: startState, acceptStates: acceptStates, transMap: transMap)
    }
    
    func canAccept(str: String) -> Bool {
        var dfa = newDFA()
        dfa.readSymbols(str: str)
        return dfa.accepting
    }
}

struct NFATransitionMap {
    var mapping: [String: Set<State>]
    init(_ rules: [FATransition]) {
        mapping = Dictionary(grouping: rules, by: { rule in rule.input.description })
            .mapValues { rules in Set(rules.map { $0.output }) }
    }
    
    func nextStates(states: Set<State>, symbol: Symbol) -> Set<State> {
        let nexts: [State] = states.flatMap { state -> Set<State> in
            let input = FATransitionInput(state: state, symbol: symbol)
            guard let outputs = mapping[input.description] else {
                return []
            }
            return outputs
        }

        return Set(nexts)
    }
    
    subscript(states: Set<State>, symbol: Symbol) -> Set<State> {
        nextStates(states: states, symbol: symbol)
    }
    
    func followFreeMoves(states: Set<State>) -> Set<State> {
        let moreStates = nextStates(states: states, symbol: .free)
        return moreStates.isSubset(of: states) ? states : followFreeMoves(states: moreStates)
    }
}

struct NFA {
    var movingStates: Set<State>
    var acceptStates: Set<State>
    var transMap: NFATransitionMap
    
    var currentStates: Set<State> {
        transMap.followFreeMoves(states: movingStates).union(movingStates)
    }
    
    var accepting: Bool {
        !currentStates.isDisjoint(with: acceptStates)
    }
    
    mutating func readSymbol(symbol: Symbol) {
        movingStates = transMap.nextStates(states: currentStates, symbol: symbol)
    }
    
    mutating func readSymbols(str: String) {
        for symbol in str {
            readSymbol(symbol: .symbol(symbol))
        }
    }
}

struct NFADesign {
    var startState: State
    var acceptStates: Set<State>
    var transMap: NFATransitionMap
    
    func newNFA() -> NFA {
        NFA(movingStates: [startState], acceptStates: acceptStates, transMap: transMap)
    }
    
    func canAccept(str: String) -> Bool {
        var nfa = newNFA()
        nfa.readSymbols(str: str)
        return nfa.accepting
    }
    
}

public func dfaMain() {
    let transMap = DFATransitionMap([
        1~"a"~>2, 1~"b"~>1,
        2~"a"~>2, 2~"b"~>3,
        3~"a"~>3, 3~"b"~>3
    ])
    let s = DFADesign(startState: 1, acceptStates: [1, 3], transMap: transMap)
    print(
        s.canAccept(str: "ab"),
        s.canAccept(str: "aa"),
        s.canAccept(str: "ba")
    )
    
}

public func nfaMain() {
    let transMap = NFATransitionMap([
        1~"a"~>1, 1~"b"~>1, 1~"b"~>2,
        2~"a"~>3, 2~"b"~>3,
        3~"a"~>4, 3~"b"~>4
    ])
    
    let s = NFADesign(startState: 1, acceptStates: [4], transMap: transMap)

    print(
        s.canAccept(str: "bab"),
        s.canAccept(str: "bbbbb"),
        s.canAccept(str: "bbabb")
    )
}

public func nfaFreeMoveMain() {
    let transMap = NFATransitionMap([
        1~Symbol.free~>2, 1~Symbol.free~>4,
        2~"a"~>3,
        3~"a"~>2,
        4~"a"~>5,
        5~"a"~>6,
        6~"a"~>4
    ])
    
    let s = NFADesign(startState: 1, acceptStates: [2, 4], transMap: transMap)
    
    print(
        s.canAccept(str: "aa"),
        s.canAccept(str: "aaa"),
        s.canAccept(str: "aaaaa"),
        s.canAccept(str: "aaaaaa")
    )
}
