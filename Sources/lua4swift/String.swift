import CLua

extension String: LuaValue {
    public func push(_ vm: Lua.VirtualMachine) {
      lua_pushstring(vm.state, self.cString(using: .utf8))
    }

    public func kind() -> Lua.Kind { return .string }

    public static func arg(_ vm: Lua.VirtualMachine, value: LuaValue) -> String? {
        if value.kind() != .string { return "string" }
        return nil
    }
}
