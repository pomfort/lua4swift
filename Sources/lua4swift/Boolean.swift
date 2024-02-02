import CLua

extension Bool: LuaValueRepresentable, SimpleUnwrapping {
    public func push(_ vm: Lua.State) {
        lua_pushboolean(vm.state, self ? 1 : 0)
    }
}
