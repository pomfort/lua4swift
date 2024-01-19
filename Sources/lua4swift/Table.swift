import CLua

extension Lua {
    open class Table: Lua.StoredValue, LuaValueRepresentable {
        open var kind: Lua.Kind { return .table }
        public class var typeName: String { Lua.Kind.table.description }

        open class func unwrap(_ vm: Lua.VirtualMachine, _ value: LuaValueRepresentable) throws -> Self {
            guard value.kind == .table else { throw Lua.TypeGuardError(kind: .table) }
            return value as! Self
        }

        open subscript(key: LuaValueRepresentable) -> LuaValueRepresentable {
            get {
                push(vm)

                key.push(vm)
                lua_gettable(vm.state, -2)
                let v = vm.popValue(-1)

                vm.pop()
                return v!
            }

            set {
                push(vm)

                key.push(vm)
                newValue.push(vm)
                lua_settable(vm.state, -3)

                vm.pop()
            }
        }

        open func keys() -> [LuaValueRepresentable] {
            var k = [LuaValueRepresentable]()
            push(vm) // table
            lua_pushnil(vm.state)
            while lua_next(vm.state, -2) != 0 {
                vm.pop() // val
                let key = vm.popValue(-1)!
                k.append(key)
                key.push(vm)
            }
            vm.pop() // table
            return k
        }

        public var description: String {
            "[\n" + self.keys().map {
                let v = self[$0]
                let t = v as? Table
                return "   \($0): \(t.map { $0.kind.description + "…" } ?? "\(v)")"
            }.joined(separator: ",\n")
            + "\n]"
        }

        open func becomeMetatableFor(_ thing: LuaValueRepresentable) {
            thing.push(vm)
            self.push(vm)
            lua_setmetatable(vm.state, -2)
            vm.pop() // thing
        }

        private func asTupleArray() -> [(LuaValueRepresentable, LuaValueRepresentable)] {
            var v = [(LuaValueRepresentable, LuaValueRepresentable)]()
            for key in keys() {
                let val = self[key]
                v.append((key, val))
            }
            return v
        }

        public func asDictionary<K0, K>(_ kfn: (K0) -> K? = { $0 as? K }) -> [K: LuaValueRepresentable] where K0: LuaValueRepresentable, K: Hashable {
            self.asTupleArray().reduce(into: [K: LuaValueRepresentable]()) {
                guard let k0 = $1.0 as? K0, let k = kfn(k0) else { return }
                $0[k] = $1.1
            }
        }

        public func asArray() -> [any LuaValueRepresentable]? {
            var sequence = [any LuaValueRepresentable]()

            let dict: [Int64: LuaValueRepresentable] = asDictionary({ (k: Number) in k.toInteger() })

            // if it has no numeric keys, then it's empty; job well done, team, job well done.
            if dict.count == 0 { return sequence }

            // ensure table has no holes and keys start at 1
            let sortedKeys = dict.keys.sorted(by: <)
            if [Int64](1...sortedKeys.last!) != sortedKeys { return nil }

            // append values to the array, in order
            for i in sortedKeys {
                dict[i].map { sequence.append($0) }
            }

            return sequence
        }

        public func asArray<T: LuaValueRepresentable>() -> [T]? {
            self.asArray().map { $0.compactMap{ $0 as? T } }
        }

        func storeReference(_ v: LuaValueRepresentable) -> Int {
            v.push(vm)
            return vm.ref(RegistryIndex)
        }

        func removeReference(_ ref: Int) {
            vm.unref(RegistryIndex, ref)
        }
    }
}
