import CLua

extension Lua {
    public final class Nil: LuaValueRepresentable, Equatable, SimpleUnwrapping, Sendable {
        public func push(_ vm: Lua.State) {
            lua_pushnil(vm.state)
        }

        public static func ==(_: Nil, _: Nil) -> Bool {
            true
        }

        private init() { }
        public static let `nil`: Nil = .init()

        public var description: String { (nil as Int?).debugDescription }
    }
}
