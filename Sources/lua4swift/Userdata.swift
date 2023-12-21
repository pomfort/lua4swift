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

        public static func arg(_ vm: Lua.VirtualMachine, value: LuaValueRepresentable) -> String? {
            fatalError("unimplemented")
        }
    }

    open class LightUserdata: Lua.StoredValue, LuaValueRepresentable {
        open var kind: Lua.Kind { return .lightUserdata }

        open class func arg(_ vm: Lua.VirtualMachine, value: LuaValueRepresentable) -> String? {
            if value.kind != .lightUserdata { return "light userdata" }
            return nil
        }
    }

    open class CustomType<T: LuaCustomTypeInstance>: Table {
        override open class func arg(_ vm: Lua.VirtualMachine, value: LuaValueRepresentable) -> String? {
            value.push(vm)
            let isLegit = luaL_testudata(vm.state, -1, T.luaTypeName().cString(using: .utf8)) != nil
            vm.pop()
            if !isLegit { return T.luaTypeName() }
            return nil
        }

        override internal init(_ vm: Lua.VirtualMachine) {
            super.init(vm)
        }

        open var gc: ((T) -> Void)?
        open var eq: ((T, T) -> Bool)?

        public func createMethod(_ fn: @escaping (T) -> Void) -> Function {
            vm.createFunction([CustomType<T>.arg]) {
                fn(($0[0] as! Userdata).toCustomType())
                return []
            }
        }

        public func createMethod<R: LuaValueRepresentable>(_ fn: @escaping (T) -> R) -> Function {
            vm.createFunction([CustomType<T>.arg]) {
                [fn(($0[0] as! Userdata).toCustomType())]
            }
        }

        public func createMethod(_ fn: @escaping (T) -> [LuaValueRepresentable]) -> Function {
            vm.createFunction([CustomType<T>.arg]) {
                 fn(($0[0] as! Userdata).toCustomType())
            }
        }

        public func createMethod<A1: LuaValueRepresentable>(_ fn: @escaping (T, A1) -> Void) -> Function {
            vm.createFunction([CustomType<T>.arg, A1.arg]) {
                fn(($0[0] as! Userdata).toCustomType(), $0[1] as! A1)
                return []
            }
        }

        public func createMethod<A1: LuaValueRepresentable, R: LuaValueRepresentable>(_ fn: @escaping (T, A1) -> R) -> Function {
            vm.createFunction([CustomType<T>.arg, A1.arg]) {
                [fn(($0[0] as! Userdata).toCustomType(), $0[1] as! A1)]
            }
        }

        public func createMethod<A1: LuaValueRepresentable>(_ fn: @escaping (T, A1) -> [LuaValueRepresentable]) -> Function {
            vm.createFunction([CustomType<T>.arg, A1.arg]) {
                fn(($0[0] as! Userdata).toCustomType(), $0[1] as! A1)
            }
        }

        public func createMethod<A1: LuaValueRepresentable, A2: LuaValueRepresentable>(_ fn: @escaping (T, A1, A2) -> Void) -> Function {
            vm.createFunction([CustomType<T>.arg, A1.arg, A2.arg]) {
                fn(($0[0] as! Userdata).toCustomType(), $0[1] as! A1, $0[2] as! A2)
                return []
            }
        }

        public func createMethod<A1: LuaValueRepresentable, A2: LuaValueRepresentable, R: LuaValueRepresentable>(_ fn: @escaping (T, A1, A2) -> R) -> Function {
            vm.createFunction([CustomType<T>.arg, A1.arg, A2.arg]) {
                [fn(($0[0] as! Userdata).toCustomType(), $0[1] as! A1, $0[2] as! A2)]
            }
        }

        public func createMethod<A1: LuaValueRepresentable, A2: LuaValueRepresentable>(_ fn: @escaping (T, A1, A2) -> [LuaValueRepresentable]) -> Function {
            vm.createFunction([CustomType<T>.arg, A1.arg, A2.arg]) {
                fn(($0[0] as! Userdata).toCustomType(), $0[1] as! A1, $0[2] as! A2)
            }
        }

        public func createMethod<A1: LuaValueRepresentable, A2: LuaValueRepresentable, A3: LuaValueRepresentable>(_ fn: @escaping (T, A1, A2, A3) -> Void) -> Function {
            vm.createFunction([CustomType<T>.arg, A1.arg, A2.arg, A3.arg]) {
                fn(($0[0] as! Userdata).toCustomType(), $0[1] as! A1, $0[2] as! A2, $0[3] as! A3)
                return []
            }
        }

        public func createMethod<A1: LuaValueRepresentable, A2: LuaValueRepresentable, A3: LuaValueRepresentable, R: LuaValueRepresentable>(_ fn: @escaping (T, A1, A2, A3) -> R) -> Function {
            vm.createFunction([CustomType<T>.arg, A1.arg, A2.arg, A3.arg]) {
                [fn(($0[0] as! Userdata).toCustomType(), $0[1] as! A1, $0[2] as! A2, $0[3] as! A3)]
            }
        }

        public func createMethod<A1: LuaValueRepresentable, A2: LuaValueRepresentable, A3: LuaValueRepresentable>(_ fn: @escaping (T, A1, A2, A3) -> [LuaValueRepresentable]) -> Function {
            vm.createFunction([CustomType<T>.arg, A1.arg, A2.arg, A3.arg]) {
                fn(($0[0] as! Userdata).toCustomType(), $0[1] as! A1, $0[2] as! A2, $0[3] as! A3)
            }
        }
    }
}
