import CLua

extension Bool: LuaValueRepresentable {
    public func push(_ vm: Lua.VirtualMachine) {
        lua_pushboolean(vm.state, self ? 1 : 0)
    }

    public var kind: Lua.Kind { return .boolean }

    public static func arg(_ vm: Lua.VirtualMachine, value: LuaValueRepresentable) -> String? {
        if value.kind != .boolean { return "boolean" }
        return nil
    }
}
