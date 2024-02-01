import Foundation
import CLua

public protocol LuaCustomTypeInstance {
    static func luaTypeName() -> String
}

extension Lua {
    open class Userdata: Lua.StoredValue, LuaValueRepresentable {
        open func userdataPointer<T>() -> UnsafeMutablePointer<T> {
            push(vm)
            let ptr = lua_touserdata(vm.state, -1)
            vm.pop()
            return (ptr?.assumingMemoryBound(to: T.self))!
        }

        open func toCustomType<T: LuaCustomTypeInstance>() -> T {
            return userdataPointer().pointee
        }

        open func toAny() -> Any {
            return userdataPointer().pointee
        }

        open var kind: Lua.Kind { return .userdata }
        public static var typeName: String { Lua.Kind.userdata.description }

        internal static func unwrap(_ value: LuaValueRepresentable) throws -> Self {
            guard value.kind == .userdata else { throw Lua.TypeGuardError(kind: .userdata) }
            return value as! Self
        }

        public static func unwrap(_: Lua.State, _ value: LuaValueRepresentable) throws -> Self {
            try Self.unwrap(value)
        }

        fileprivate static func description(name: String) -> String { "Lua.CustomType<\(name)>" }
        public var description: String { self.metatable.flatMap { $0["__name"] as? String }.map { Self.description(name: $0) } ?? self.kind.description }
    }

    open class LightUserdata: Lua.StoredValue, LuaValueRepresentable {
        open var kind: Lua.Kind { return .lightUserdata }
        public static var typeName: String { Lua.Kind.lightUserdata.description }
        public var description: String { Lua.Kind.lightUserdata.description }

        public static func unwrap(_ vm: Lua.State, _ value: LuaValueRepresentable) throws -> Self {
            guard value.kind == .lightUserdata else { throw Lua.TypeGuardError(kind: .lightUserdata) }
            return value as! Self
        }
    }

    open class CustomType<T: LuaCustomTypeInstance>: Table {
        override public class func unwrap(_ vm: Lua.State, _ value: LuaValueRepresentable) throws -> Self {
            value.push(vm)
            let isLegit = luaL_testudata(vm.state, -1, T.luaTypeName().cString(using: .utf8)) != nil
            vm.pop()
            guard isLegit else { throw Lua.TypeGuardError(type: T.luaTypeName()) }
            return value as! Self
        }

        override internal init(_ vm: Lua.State) {
            super.init(vm)
        }

        open var gc: ((T) -> Void)?
        open var eq: ((T, T) -> Bool)?

        override public var description: String { Userdata.description(name: T.luaTypeName()) }
        override public class var typeName: String { Userdata.description(name: T.luaTypeName()) }

        public func createMethod(_ fn: @escaping (T, [LuaValueRepresentable]) throws -> [LuaValueRepresentable]) -> Function {
            vm.createFunction { args in
                guard args.count > 0 else { throw Lua.MethodCallError() }
                return try fn(Userdata.unwrap(self.vm, args[0]).toCustomType(), Array(args[1...]))
            }
        }

        public func createMethod(_ fn: @escaping (T, [LuaValueRepresentable]) throws -> LuaValueRepresentable) -> Function {
            self.createMethod {
                try [fn($0, $1)]
            }
        }

        public func createMethod(_ fn: @escaping (T, [LuaValueRepresentable]) throws -> Void) -> Function {
            self.createMethod {
                try fn($0, $1)
                return []
            }
        }
    }
}
