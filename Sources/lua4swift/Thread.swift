import CLua

open class Thread: Lua.StoredValue {
    override open func kind() -> Lua.Kind { return .thread }

    override open class func arg(_ vm: Lua.VirtualMachine, value: LuaValue) -> String? {
        if value.kind() != .thread { return "thread" }
        return nil
    }
}
