import CLua

extension Lua {
    open class Thread: Lua.StoredValue, LuaValueRepresentable {
        open var kind: Lua.Kind { return .thread }

        open class func arg(_ vm: Lua.VirtualMachine, value: LuaValueRepresentable) -> String? {
            if value.kind != .thread { return "thread" }
            return nil
        }
    }
}
