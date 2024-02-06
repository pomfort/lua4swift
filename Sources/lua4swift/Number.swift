import CLua

extension Double: LuaValueRepresentable, SimpleUnwrapping {
    public func push(_ vm: Lua.State) {
        lua_pushnumber(vm.state, self)
    }
}

extension Int64: LuaValueRepresentable, SimpleUnwrapping {
    public func push(_ vm: Lua.State) {
        lua_pushinteger(vm.state, self)
    }
}

extension Int: LuaValueRepresentable {
    public static func unwrap(_: Lua.State, _ value: LuaValueRepresentable) throws -> Int {
        try Int(Int64.unwrap(value))
    }

    public func push(_ vm: Lua.State) {
        lua_pushinteger(vm.state, Int64(self))
    }
}
