import Foundation

protocol AST {
    var reducible: Bool { get }
    func reduce(_ env: inout [String : Any]) throws -> AST
    func eval(_ env: inout [String: Any]) throws -> AST
    func toJS() -> String
}

protocol Primitive {
    associatedtype Raw
    var raw: Raw { get }
}

extension Primitive {
    var reducible: Bool { false }
    func reduce(_ env: inout [String : Any]) throws -> AST {
        self as! AST
    }
    func eval(_ env: inout [String : Any]) throws -> AST {
        self as! AST
    }
    func toJS() -> String {
        "(e => \(self.raw))"
    }
}

enum ASTError: Error {
    case smallStep(AST)
    case bigStep(AST)
}

struct Integer: Primitive, AST { var raw: Int }
struct Boolean: Primitive, AST { var raw: Bool }
struct Unit: Primitive, AST { var raw: () }

struct Variable: AST {
    var raw: String
    var reducible: Bool { true }
    func reduce(_ env: inout [String : Any]) throws -> AST {
        guard let s = env[raw] else {
            throw ASTError.smallStep(self)
        }
        return s as! AST
    }
    func eval(_ env: inout [String : Any]) throws -> AST {
        guard let s = env[raw] else {
            throw ASTError.bigStep(self)
        }
        return s as! AST
    }
    func toJS() -> String {
        "(e => e.\(self.raw))"
    }
}

struct Add: AST {
    var left: AST
    var right: AST
    var reducible: Bool { true }
    func reduce(_ env: inout [String : Any]) throws -> AST {
        if left.reducible {
            return Add(left: try left.reduce(&env), right: right)
        } else if right.reducible {
            return Add(left: left, right: try right.reduce(&env))
        } else {
            switch (left, right) {
            case let (l as Integer, r as Integer):
                return Integer(raw: l.raw + r.raw)
            default:
                throw ASTError.smallStep(self)
            }
        }
    }
    func eval(_ env: inout [String: Any]) throws -> AST {
        switch (try left.eval(&env), try right.eval(&env)) {
        case let (x as Integer, y as Integer):
            return Integer(raw: x.raw + y.raw)
        default:
            throw ASTError.bigStep(self)
        }
    }
    func toJS() -> String {
        "(e => \(self.left.toJS())(e) + \(self.right.toJS())(e))"
    }
}

struct Mul: AST {
    var left: AST
    var right: AST
    var reducible: Bool { true }
    func reduce(_ env: inout [String : Any]) throws -> AST {
        if left.reducible {
            return Mul(left: try left.reduce(&env), right: right)
        } else if right.reducible {
            return Mul(left: left, right: try right.reduce(&env))
        } else {
            switch (left, right) {
            case let (l as Integer, r as Integer):
                return Integer(raw: l.raw * r.raw)
            default:
                throw ASTError.smallStep(self)
            }
        }
    }
    func eval(_ env: inout [String: Any]) throws -> AST {
        switch (try left.eval(&env), try right.eval(&env)) {
        case let (x as Integer, y as Integer):
            return Integer(raw: x.raw * y.raw)
        default:
            throw ASTError.bigStep(self)
        }
    }

    func toJS() -> String {
        "(e => \(self.left.toJS())(e) * \(self.right.toJS())(e))"
    }
}

struct Lt: AST {
    var left: AST
    var right: AST
    var reducible: Bool { true }
    func reduce(_ env: inout [String : Any]) throws -> AST {
        if left.reducible {
            return Lt(left: try left.reduce(&env), right: right)
        } else if right.reducible {
            return Lt(left: left, right: try right.reduce(&env))
        } else {
            switch (left, right) {
            case let (l as Integer, r as Integer):
                return Boolean(raw: l.raw < r.raw)
            default:
                throw ASTError.smallStep(self)
            }
        }
    }
    func eval(_ env: inout [String: Any]) throws -> AST {
        switch (try left.eval(&env), try right.eval(&env)) {
        case let (x as Integer, y as Integer):
            return Boolean(raw: x.raw < y.raw)
        default:
            throw ASTError.bigStep(self)
        }
    }
    func toJS() -> String {
        "(e => \(self.left.toJS())(e) < \(self.right.toJS())(e))"
    }
}

struct Assign: AST {
    var name: AST
    var expression: AST
    var reducible: Bool { true }
    func reduce(_ env: inout [String : Any]) throws -> AST {
        guard case let s as Variable = name else {
            throw ASTError.smallStep(self)
        }
        if expression.reducible {
            return Assign(name: s, expression: try expression.reduce(&env))
        } else {
            env[s.raw] = expression
            return Unit()
        }
        
    }
    func eval(_ env: inout [String : Any]) throws -> AST {
        switch (name, try expression.eval(&env)){
        case let (label as Variable, val):
            env[label.raw] = val
            return Unit()
        default:
            throw ASTError.bigStep(self)
        }
    }
    func toJS() -> String {
        "(e => { e.\((name as! Variable).raw) = \(expression.toJS())(e) })"
    }
}

struct If: AST {
    var condition: AST
    var consequence: AST
    var alternative: AST
    var reducible: Bool { true }
    func reduce(_ env: inout [String : Any]) throws -> AST {
        if condition.reducible {
            return If(condition: try condition.reduce(&env), consequence: consequence, alternative: alternative)
        } else {
            switch condition {
            case let (p as Boolean):
                return p.raw ? consequence : alternative
            default:
                throw ASTError.smallStep(self)
            }
        }
    }
    func eval(_ env: inout [String : Any]) throws -> AST {
        guard case let p as Boolean = try condition.eval(&env) else {
            throw ASTError.bigStep(self)
        }
        
        return try p.raw ? consequence.eval(&env) : alternative.eval(&env)
    }
    func toJS() -> String {
        "(e => \(condition)(e) ? \(consequence)(e) : \(alternative)(e))"
    }
}

struct Do: AST {
    var sequence: [AST]
    var reducible: Bool { true }
    func reduce(_ env: inout [String : Any]) throws -> AST {
        if sequence.count == 0 {
            return Unit()
        }
        else if sequence.first! is Unit {
            return Do(sequence: Array(sequence.dropFirst()))
        } else {
            var _seq = sequence
            let a = try _seq.removeFirst().eval(&env)
            _seq.insert(a, at: 0)
            return Do(sequence: _seq)
        }
    }
    func eval(_ env: inout [String : Any]) throws -> AST {
        for ast in sequence {
            let _ = try ast.eval(&env)
        }
        return Unit()
    }
    func toJS() -> String {
        "(e => { \(sequence.map { "\($0.toJS())(e)" }.joined(separator: ";")) })"
    }
}

struct While: AST {
    var condition: AST
    var body: AST
    var reducible: Bool { true }
    func reduce(_ env: inout [String : Any]) throws -> AST {
        return If(condition: condition, consequence: Do(sequence: [body, self]), alternative: Unit())
    }
    func eval(_ env: inout [String : Any]) throws -> AST {
        return try If(condition: condition, consequence: Do(sequence: [body, self]), alternative: Unit()).eval(&env)
    }
    func toJS() -> String {
        "(e => { while (\(condition.toJS())(e)) { \(body.toJS())(e) } })"
    }
}

struct SmallStepMachine {
    var expression: AST
    mutating func step(_ env: inout [String: Any]) throws {
        expression = try expression.reduce(&env)
    }
    mutating func run(_ env: inout [String: Any]) throws {
        while expression.reducible {
            print(expression)
            try step(&env)
        }
        print(expression)
    }
}
public func ASTMain() throws {
    var env = [String: Any]()
    
    let ast = Do(sequence: [
        // x = 2 + 5 * 12
        Assign(name: Variable(raw: "x"),
               expression: Add(left: Integer(raw: 2),
                               right: Mul(left: Integer(raw: 5),
                                          right: Integer(raw: 12))
               )
        ),
        // while x < 100 {
        //     x = x + 1
        // }
        While(condition: Lt(left: Variable(raw: "x"), right: Integer(raw: 100)),
              body: Assign(name: Variable(raw: "x"),
                           expression: Add(left: Variable(raw: "x"), right: Integer(raw: 1))
              )
        )
    ])
    
    
    // 操作的意味論 スモールステップ
    var machine = SmallStepMachine(expression: ast)
    try machine.run(&env)
    print(env)
    
    // 操作的意味論 ビッグステップ
    let _ = try ast.eval(&env)
    print(env)

    // 表示的意味論
    let js = ast.toJS()
    print(js)
}
