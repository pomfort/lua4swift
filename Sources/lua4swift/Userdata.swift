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

        public static func unwrap(_ vm: Lua.VirtualMachine, _ value: LuaValueRepresentable) throws -> Self {
            guard value.kind == .userdata else { throw Lua.TypeGuardError(kind: .userdata) }
            return value as! Self
        }
    }

    open class LightUserdata: Lua.StoredValue, LuaValueRepresentable {
        open var kind: Lua.Kind { return .lightUserdata }

        public static func unwrap(_ vm: Lua.VirtualMachine, _ value: LuaValueRepresentable) throws -> Self {
            guard value.kind == .lightUserdata else { throw Lua.TypeGuardError(kind: .lightUserdata) }
            return value as! Self
        }
    }

    open class CustomType<T: LuaCustomTypeInstance>: Table {
        override public class func unwrap(_ vm: Lua.VirtualMachine, _ value: LuaValueRepresentable) throws -> Self {
            value.push(vm)
            let isLegit = luaL_testudata(vm.state, -1, T.luaTypeName().cString(using: .utf8)) != nil
            vm.pop()
            guard isLegit else { throw Lua.TypeGuardError(type: T.luaTypeName()) }
            return value as! Self
        }

        override internal init(_ vm: Lua.VirtualMachine) {
            super.init(vm)
        }

        open var gc: ((T) -> Void)?
        open var eq: ((T, T) -> Bool)?

        public func createMethod(_ fn: @escaping (T) -> Void) -> Function {
            vm.createFunction(nargs: 1) {
                try fn(Userdata.unwrap(self.vm, $0[0]).toCustomType())
                return []
            }
        }

        public func createMethod<R: LuaValueRepresentable>(_ fn: @escaping (T) -> R) -> Function {
            vm.createFunction(nargs: 1) {
                try [fn(Userdata.unwrap(self.vm, $0[0]).toCustomType())]
            }
        }

        public func createMethod(_ fn: @escaping (T) -> [LuaValueRepresentable]) -> Function {
            vm.createFunction(nargs: 1) {
                try fn(Userdata.unwrap(self.vm, $0[0]).toCustomType())
            }
        }

        public func createMethod<A1: LuaValueRepresentable>(_ fn: @escaping (T, A1) -> Void) -> Function {
            vm.createFunction(nargs: 2) {
                try fn(Userdata.unwrap(self.vm, $0[0]).toCustomType(), A1.unwrap(self.vm, $0[1]))
                return []
            }
        }

        public func createMethod<A1: LuaValueRepresentable, R: LuaValueRepresentable>(_ fn: @escaping (T, A1) -> R) -> Function {
            vm.createFunction(nargs: 2) {
                try [fn(Userdata.unwrap(self.vm, $0[0]).toCustomType(), A1.unwrap(self.vm, $0[1]))]
            }
        }

        public func createMethod<A1: LuaValueRepresentable>(_ fn: @escaping (T, A1) -> [LuaValueRepresentable]) -> Function {
            vm.createFunction(nargs: 2) {
                try fn(Userdata.unwrap(self.vm, $0[0]).toCustomType(), A1.unwrap(self.vm, $0[1]))
            }
        }

        public func createMethod<A1: LuaValueRepresentable, A2: LuaValueRepresentable>(_ fn: @escaping (T, A1, A2) -> Void) -> Function {
            vm.createFunction(nargs: 3) {
                try fn(Userdata.unwrap(self.vm, $0[0]).toCustomType(), A1.unwrap(self.vm, $0[1]), A2.unwrap(self.vm, $0[2]))
                return []
            }
        }

        public func createMethod<A1: LuaValueRepresentable, A2: LuaValueRepresentable, R: LuaValueRepresentable>(_ fn: @escaping (T, A1, A2) -> R) -> Function {
            vm.createFunction(nargs: 3) {
                try [fn(Userdata.unwrap(self.vm, $0[0]).toCustomType(), A1.unwrap(self.vm, $0[1]), A2.unwrap(self.vm, $0[2]))]
            }
        }

        public func createMethod<A1: LuaValueRepresentable, A2: LuaValueRepresentable>(_ fn: @escaping (T, A1, A2) -> [LuaValueRepresentable]) -> Function {
            vm.createFunction(nargs: 3) {
                try fn(Userdata.unwrap(self.vm, $0[0]).toCustomType(), A1.unwrap(self.vm, $0[1]), A2.unwrap(self.vm, $0[2]))
            }
        }

        public func createMethod<A1: LuaValueRepresentable, A2: LuaValueRepresentable, A3: LuaValueRepresentable>(_ fn: @escaping (T, A1, A2, A3) -> Void) -> Function {
            vm.createFunction(nargs: 4) {
                try fn(Userdata.unwrap(self.vm, $0[0]).toCustomType(), A1.unwrap(self.vm, $0[1]), A2.unwrap(self.vm, $0[2]), A3.unwrap(self.vm, $0[3]))
                return []
            }
        }

        public func createMethod<A1: LuaValueRepresentable, A2: LuaValueRepresentable, A3: LuaValueRepresentable, R: LuaValueRepresentable>(_ fn: @escaping (T, A1, A2, A3) -> R) -> Function {
            vm.createFunction(nargs: 4) {
                try [fn(Userdata.unwrap(self.vm, $0[0]).toCustomType(), A1.unwrap(self.vm, $0[1]), A2.unwrap(self.vm, $0[2]), A3.unwrap(self.vm, $0[3]))]
            }
        }

        public func createMethod<A1: LuaValueRepresentable, A2: LuaValueRepresentable, A3: LuaValueRepresentable>(_ fn: @escaping (T, A1, A2, A3) -> [LuaValueRepresentable]) -> Function {
            vm.createFunction(nargs: 4) {
                try fn(Userdata.unwrap(self.vm, $0[0]).toCustomType(), A1.unwrap(self.vm, $0[1]), A2.unwrap(self.vm, $0[2]), A3.unwrap(self.vm, $0[3]))
            }
        }
    }
}
