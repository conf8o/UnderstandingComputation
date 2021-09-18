import Foundation

typealias State = (Int)

struct FARule {
    var state: State
    var char: Character
    var next_state: State
    func applies_to(state: State, char: Character) -> Bool {
        self.state == state && self.char == char
    }
    
    var follow: State { next_state }
}

extension Array where Element == FARule {
    func nextState(_ state: State, _ char: Character) -> State? {
        rule_for(state: state, char: char)?.follow
    }
    
    private func rule_for(state: State, char: Character) -> FARule? {
        first { rule in
            rule.applies_to(state: state, char: char)
        }
    }
}

infix operator ~: AdditionPrecedence
func ~ (s1: State, char: Character) -> (State, Character) {
    (s1, char)
}

infix operator ~>: AdditionPrecedence
func ~> (from: (State, Character), to: State) -> FARule {
    FARule(state: from.0, char: from.1, next_state: to)
}

struct DFA {
    var currentState: State
    var acceptStates: Set<State>
    var rulebook: [FARule]
    
    var accepting: Bool {
        acceptStates.contains(currentState)
    }
    
}
public func automatonMain() {
    let rulebook = [
        1~"a"~>2, 1~"b"~>1,
        2~"a"~>2, 2~"b"~>3,
        3~"a"~>3, 3~"b"~>3
    ]
    
    let s =
        DFA(currentState: 1, acceptStates: [1, 3], rulebook: rulebook)
        .accepting
    
    print(s)
}


