import Foundation
import CLua

public protocol LuaCustomTypeInstance {
    static func luaTypeName() -> String
}

extension Lua {
    open class Userdata: Lua.StoredValue, LuaValueRepresentable, SimpleUnwrapping, CustomStringConvertible {
        open func userdataPointer<T>() -> UnsafeMutablePointer<T> {
            push(vm)
            let ptr = lua_touserdata(vm.state, -1)
            vm.pop()
            return (ptr?.assumingMemoryBound(to: T.self))!
        }

        open func toCustomType<T: LuaCustomTypeInstance>() throws -> T {
            push(vm)
            defer { vm.pop() }
            guard luaL_testudata(vm.state, -1, T.luaTypeName().cString(using: .utf8)) != nil,
                  let ptr = lua_touserdata(vm.state, -1) else {
                throw Lua.Error.customTypeGuard(T.self)
            }
            return ptr.assumingMemoryBound(to: T.self).pointee
        }

        open func toAny() -> Any {
            return userdataPointer().pointee
        }

        fileprivate static func description(name: String) -> String { "Lua.CustomType<\(name)>" }
        public var description: String { 
            self.metatable.flatMap { $0["__name"] as? String }.map { Self.description(name: $0) } ?? String(describing: Self.self)
        }
    }

    open class LightUserdata: Lua.StoredValue, LuaValueRepresentable, SimpleUnwrapping { }

    open class CustomType<T: LuaCustomTypeInstance>: Table {
        public class func unwrap(_ vm: Lua.State, _ value: LuaValueRepresentable) throws -> Self {
            value.push(vm)
            let isLegit = luaL_testudata(vm.state, -1, T.luaTypeName().cString(using: .utf8)) != nil
            vm.pop()
            guard isLegit else { throw Lua.Error.customTypeGuard(T.self) }
            return value as! Self
        }

        open var gc: ((T) -> Void)?
        open var eq: ((T, T) -> Bool)?

        public func createMethod(_ fn: @escaping (T, [LuaValueRepresentable]) throws -> [LuaValueRepresentable]) -> Function {
            vm.createFunction { args in
                guard args.count > 0 else { throw Lua.Error.methodCall }
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

        override public var description: String {
            Userdata.description(name: Self.typeName)
        }
    }
}
