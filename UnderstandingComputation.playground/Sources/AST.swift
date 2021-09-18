import Foundation

enum Val {
    case int(Int)
    case bool(Bool)
    case symbol(String)
    case unit
}

protocol AST {
    func eval(_ env: inout [String: Val]) throws -> AST
}

enum ASTError: Error {
    case type(AST)
}

struct Primitive: AST {
    var raw: Val
    func eval(_ env: inout [String : Val]) throws -> AST {
        switch raw {
        case let .symbol(s):
            guard let x = env[s] else {
                throw ASTError.type(self)
            }
            return Primitive(raw: x)
        default:
            return self
        }
    }
}

struct Add: AST {
    var left: AST
    var right: AST
    func eval(_ env: inout [String: Val]) throws -> AST {
        guard case let (l as Primitive, r as Primitive) = (try left.eval(&env), try right.eval(&env)) else {
            throw ASTError.type(self)
        }
        
        switch (l.raw, r.raw) {
        case let (.int(x), .int(y)):
            return Primitive(raw: .int(x + y))
        default:
            throw ASTError.type(self)
        }
    }
}

struct Mul: AST {
    var left: AST
    var right: AST
    func eval(_ env: inout [String : Val]) throws -> AST {
        guard case let (l as Primitive, r as Primitive) = (try left.eval(&env), try right.eval(&env)) else {
            throw ASTError.type(self)
        }
        
        switch (l.raw, r.raw) {
        case let (.int(x), .int(y)):
            return Primitive(raw: .int(x * y))
        default:
            throw ASTError.type(self)
        }
    }
}

struct Lt: AST {
    var left: AST
    var right: AST
    func eval(_ env: inout [String : Val]) throws -> AST {
        guard case let (l as Primitive, r as Primitive) = (try left.eval(&env), try right.eval(&env)) else {
            throw ASTError.type(self)
        }
        
        switch (l.raw, r.raw) {
        case let (.int(x), .int(y)):
            return Primitive(raw: .bool(x < y))
        default:
            throw ASTError.type(self)
        }
    }
}

struct Assign: AST {
    var left: AST
    var right: AST
    func eval(_ env: inout [String : Val]) throws -> AST {
        guard case let (l as Primitive, r as Primitive) = (left, try right.eval(&env)) else {
            throw ASTError.type(self)
        }
        
        switch (l.raw, r.raw) {
        case let (.symbol(label), val):
            env[label] = val
            return Primitive(raw: .unit)
        default:
            throw ASTError.type(self)
        }
    }
}

struct If: AST {
    var condition: AST
    var consequence: AST
    var alternative: AST
    func eval(_ env: inout [String : Val]) throws -> AST {
        guard case let p as Primitive = try condition.eval(&env) else {
            throw ASTError.type(self)
        }
        
        guard case let .bool(p) = p.raw else {
            throw ASTError.type(self)
        }
        
        return try p ? consequence.eval(&env) : alternative.eval(&env)
    }
}

struct Do: AST {
    var sequence: [AST]
    func eval(_ env: inout [String : Val]) throws -> AST {
        var seq = sequence.makeIterator()
        guard let ast = seq.next() else {
            throw ASTError.type(self)
        }
        var a = try ast.eval(&env)
        for ast in seq {
            a = try ast.eval(&env)
        }
        return try a.eval(&env)
    }
}

struct While: AST {
    var condition: AST
    var body: AST
    func eval(_ env: inout [String : Val]) throws -> AST {
        return try If(condition: condition, consequence: Do(sequence: [body, self]), alternative: Primitive(raw: .unit)).eval(&env)
    }
}

public func ASTMain() throws {
    var env = [String: Val]()
    
    let p = Do(sequence: [
        // x = 2 + 5 * 12
        Assign(left: Primitive(raw: .symbol("x")),
               right: Add(left: Primitive(raw: .int(2)),
                          right: Mul(left: Primitive(raw: .int(5)), right: Primitive(raw: .int(12))))),
        // while x < 65 {
        //     x = x + 1
        // }
        While(condition: Lt(left: Primitive(raw: .symbol("x")), right: Primitive(raw: .int(65))),
              body: Assign(left: Primitive(raw: .symbol("x")),
                           right: Add(left: Primitive(raw: .symbol("x")), right: Primitive(raw: .int(1)))
              )
        ),
        Primitive.init(raw: .symbol("x"))
    ])
    print(try p.eval(&env))
}
