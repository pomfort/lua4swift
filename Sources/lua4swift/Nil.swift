import CLua

extension Lua {
    open class Nil: LuaValueRepresentable, Equatable {
        open func push(_ vm: Lua.VirtualMachine) {
            lua_pushnil(vm.state)
        }

        open var kind: Lua.Kind { return .nil }

        open class func arg(_ vm: Lua.VirtualMachine, value: LuaValueRepresentable) -> String? {
            if value.kind != .nil { return "nil" }
            return nil
        }

        public static func ==(_: Nil, _: Nil) -> Bool {
            true
        }
    }
}
