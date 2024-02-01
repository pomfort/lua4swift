import CLua

extension String: LuaValueRepresentable {
    public func push(_ vm: Lua.State) {
      lua_pushstring(vm.state, self.cString(using: .utf8))
    }

    public var kind: Lua.Kind { return .string }
    public static var typeName: String { Lua.Kind.string.description }

    public static func unwrap(_ vm: Lua.State, _ value: LuaValueRepresentable) throws -> Self {
        guard value.kind == .string else { throw Lua.TypeGuardError(kind: .string) }
        return value as! String
    }
}
