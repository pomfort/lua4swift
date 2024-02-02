import Foundation
import CLua

public protocol LuaCustomTypeInstance {
    static func luaTypeName() -> String
}

extension Lua {
    open class Userdata: Lua.StoredValue, LuaValueRepresentable, SimpleUnwrapping {
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
    }

    open class LightUserdata: Lua.StoredValue, LuaValueRepresentable, SimpleUnwrapping { }

    open class CustomType<T: LuaCustomTypeInstance>: Table {
        public class func unwrap(_ vm: Lua.State, _ value: LuaValueRepresentable) throws -> Self {
            value.push(vm)
            let isLegit = luaL_testudata(vm.state, -1, T.luaTypeName().cString(using: .utf8)) != nil
            vm.pop()
            guard isLegit else { throw Lua.TypeGuardError(type: T.luaTypeName()) }
            return value as! Self
        }

        open var gc: ((T) -> Void)?
        open var eq: ((T, T) -> Bool)?

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
