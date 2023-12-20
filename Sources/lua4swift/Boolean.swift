import CLua

extension Bool: LuaValue {
    public func push(_ vm: Lua.VirtualMachine) {
        lua_pushboolean(vm.state, self ? 1 : 0)
    }

    public func kind() -> Lua.Kind { return .boolean }

    public static func arg(_ vm: Lua.VirtualMachine, value: LuaValue) -> String? {
        if value.kind() != .boolean { return "boolean" }
        return nil
    }
}
