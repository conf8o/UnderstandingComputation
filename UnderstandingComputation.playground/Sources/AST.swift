import Foundation

enum Val {
    case int(Int)
    case bool(Bool)
    case symbol(String)
    case unit
}

protocol AST {
    var left: AST? { get }
    var right: AST? { get }
    
    func reduce(_ env: inout [String: Val]) throws -> AST
}


enum ASTError: Error {
    case type(AST)
}

extension AST {
    var left: AST? { nil }
    var right: AST? { nil }
}

struct Primitive: AST {
    var raw: Val
    func reduce(_ env: inout [String : Val]) throws -> AST {
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
    
    func reduce(_ env: inout [String: Val]) throws -> AST {
        guard case let (l as Primitive, r as Primitive) = (try left.reduce(&env), try right.reduce(&env)) else {
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
    func reduce(_ env: inout [String : Val]) throws -> AST {
        guard case let (l as Primitive, r as Primitive) = (try left.reduce(&env), try right.reduce(&env)) else {
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
    func reduce(_ env: inout [String : Val]) throws -> AST {
        guard case let (l as Primitive, r as Primitive) = (try left.reduce(&env), try right.reduce(&env)) else {
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
    func reduce(_ env: inout [String : Val]) throws -> AST {
        guard case let (l as Primitive, r as Primitive) = (left, try right.reduce(&env)) else {
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


public func ASTMain() throws {
    var env = [String: Val]()
    
    // x = 2 + 5 * 12
    let x = Assign(left: Primitive(raw: .symbol("x")),
                   right: Add(left: Primitive(raw: .int(2)),
                              right: Mul(left: Primitive(raw: .int(5)), right: Primitive(raw: .int(12)))))
    let _ = try x.reduce(&env)
    
    let p = Lt(left: Primitive(raw: .symbol("x")), right: Primitive(raw: .int(100)))
    
    print(try p.reduce(&env))
}
