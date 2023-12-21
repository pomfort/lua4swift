import CLua

extension String: LuaValueRepresentable {
    public func push(_ vm: Lua.VirtualMachine) {
      lua_pushstring(vm.state, self.cString(using: .utf8))
    }

    public var kind: Lua.Kind { return .string }

    public static func arg(_ vm: Lua.VirtualMachine, value: LuaValueRepresentable) -> String? {
        if value.kind != .string { return "string" }
        return nil
    }
}
