import Foundation

typealias State = (Int)

struct FARuleInput: CustomStringConvertible {
    var state: State
    var char: Character
    var description: String { "\(state)\(char)" }
}

struct FARule {
    var input: FARuleInput
    var output: State
}

struct DFARulebook {
    var mapping: [String: State]
    init(_ rules: [FARule]) {
        mapping = Dictionary(uniqueKeysWithValues: rules.map { rule in (rule.input.description, rule.output) })
    }
    func nextState(state: State, char: Character) -> State {
        let input = FARuleInput(state: state, char: char)
        guard let output = mapping[input.description] else {
            fatalError("invalid input: \(input)")
        }
        
        return output
    }
}


struct NFARulebook {
    var mapping: [String: Set<State>]
    init(_ rules: [FARule]) {
        mapping = Dictionary(grouping: rules, by: { rule in rule.input.description })
            .mapValues { rules in Set(rules.map { $0.output }) }
    }
    
    func nextStates(states: Set<State>, char: Character) -> Set<State> {
        let nexts: [State] = states.flatMap { state -> Set<State> in 
            let input = FARuleInput(state: state, char: char)
            guard let outputs = mapping[input.description] else {
                fatalError("invalid input: \(input)")
            }
            return outputs
        }

        return Set(nexts)
    }
    
}

infix operator ~: AdditionPrecedence
func ~ (state: State, char: Character) -> FARuleInput {
    FARuleInput(state: state, char: char)
}

infix operator ~>: AdditionPrecedence
func ~> (input: FARuleInput, output: State) -> FARule {
    FARule(input: input, output: output)
}

struct DFA {
    var currentState: State
    var acceptStates: Set<State>
    var rulebook: DFARulebook
    
    var accepting: Bool {
        acceptStates.contains(currentState)
    }
    
    mutating func readCharacter(char: Character) {
        currentState = rulebook.nextState(state: currentState, char: char)
    }
    
    mutating func readString(str: String) {
        for char in str {
            readCharacter(char: char)
        }
    }
}

struct DFADesign {
    var startState: State
    var acceptStates: Set<State>
    var rulebook: DFARulebook
    
    func newDFA() -> DFA {
        DFA(currentState: startState, acceptStates: acceptStates, rulebook: rulebook)
    }
    
    func canAccept(str: String) -> Bool {
        var dfa = newDFA()
        dfa.readString(str: str)
        return dfa.accepting
    }
}

public func dfaMain() {
    let rulebook = DFARulebook([
        1~"a"~>2, 1~"b"~>1,
        2~"a"~>2, 2~"b"~>3,
        3~"a"~>3, 3~"b"~>3
    ])
    let s = DFADesign(startState: 1, acceptStates: [1, 3], rulebook: rulebook)
    print(s.canAccept(str: "ab"),
          s.canAccept(str: "aa"),
          s.canAccept(str: "ba"))
    
}

public func nfaMain() {
    let rulebook = NFARulebook([
        1~"a"~>1, 1~"b"~>1, 1~"b"~>2,
        2~"a"~>3, 2~"b"~>3,
        3~"a"~>4, 3~"b"~>4
    ])

    print(
        rulebook.nextStates(states: [1], char: "b"),
        rulebook.nextStates(states: [1, 2], char: "a"),
        rulebook.nextStates(states: [1, 3], char: "b")
    )
}
