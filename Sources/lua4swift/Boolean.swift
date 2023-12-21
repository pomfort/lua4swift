import CLua

extension Bool: LuaValueRepresentable {
    public func push(_ vm: Lua.VirtualMachine) {
        lua_pushboolean(vm.state, self ? 1 : 0)
    }

    public var kind: Lua.Kind { return .boolean }

    public static func unwrap(_ vm: Lua.VirtualMachine, _ value: LuaValueRepresentable) throws -> Self {
        guard value.kind == .boolean else { throw Lua.TypeGuardError(kind: .boolean) }
        return value as! Bool
    }
}
