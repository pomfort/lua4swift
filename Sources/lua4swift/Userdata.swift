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

        public func createMethod(_ typeCheckers: [TypeChecker], _ fn: @escaping (T, Arguments) -> [LuaValueRepresentable]) -> Function {
            var typeCheckers = typeCheckers
            typeCheckers.insert(CustomType<T>.arg, at: 0)
            return vm.createFunction(typeCheckers) { (args: Arguments) in
                let o: T = args.customType()
                return fn(o, args)
            }
        }
    }
}
