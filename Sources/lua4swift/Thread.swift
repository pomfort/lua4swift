import CLua

extension Lua {
    open class Thread: Lua.StoredValue {
        override open var kind: Lua.Kind { return .thread }

        override open class func arg(_ vm: Lua.VirtualMachine, value: LuaValueRepresentable) -> String? {
            if value.kind != .thread { return "thread" }
            return nil
        }
    }
}
