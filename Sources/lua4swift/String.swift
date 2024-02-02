import CLua

extension String: LuaValueRepresentable, SimpleUnwrapping {
    public func push(_ vm: Lua.State) {
      lua_pushstring(vm.state, self.cString(using: .utf8))
    }
}
