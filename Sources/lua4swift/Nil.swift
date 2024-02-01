import CLua

extension Lua {
    public final class Nil: LuaValueRepresentable, Equatable {
        public func push(_ vm: Lua.State) {
            lua_pushnil(vm.state)
        }

        public var kind: Lua.Kind { return .nil }
        public static var typeName: String { Lua.Kind.nil.description }

        public static func unwrap(_ vm: Lua.State, _ value: LuaValueRepresentable) throws -> Nil {
            guard value.kind == .nil else { throw Lua.TypeGuardError(kind: .nil) }
            return .nil
        }

        public static func ==(_: Nil, _: Nil) -> Bool {
            true
        }

        private init() { }
        public static let `nil`: Nil = .init()

        public var description: String { (nil as Int?).debugDescription }
    }
}
