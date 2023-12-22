import CLua

extension Lua {
    public final class Nil: LuaValueRepresentable, Equatable, CustomDebugStringConvertible {
        public func push(_ vm: Lua.VirtualMachine) {
            lua_pushnil(vm.state)
        }

        public var kind: Lua.Kind { return .nil }

        public static func unwrap(_ vm: Lua.VirtualMachine, _ value: LuaValueRepresentable) throws -> Nil {
            guard value.kind == .nil else { throw Lua.TypeGuardError(kind: .nil) }
            return .nil
        }

        public static func ==(_: Nil, _: Nil) -> Bool {
            true
        }

        public static let `nil`: Nil = .init()

        public var debugDescription: String { (nil as Int?).debugDescription }
    }
}
