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
        mapping = Dictionary(uniqueKeysWithValues: rules.map { rule in (rule.input.description, rule.output)})
    }
    func nextState(input: FARuleInput) -> State? {
        mapping[input.description]
    }
}

infix operator ~: AdditionPrecedence
func ~ (s1: State, char: Character) -> FARuleInput {
    FARuleInput(state: s1, char: char)
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
}
public func automatonMain() {
    let rulebook = DFARulebook([
        1~"a"~>2, 1~"b"~>1,
        2~"a"~>2, 2~"b"~>3,
        3~"a"~>3, 3~"b"~>3
    ])
    
    let s =
        DFA(currentState: 1, acceptStates: [1, 3], rulebook: rulebook)
        .accepting
    
    print(s)
}


