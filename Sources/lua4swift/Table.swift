import CLua

extension Lua {
    open class Table: Lua.StoredValue, LuaValueRepresentable, SimpleUnwrapping, CustomStringConvertible {
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

        private static func keySort(_ lhs: LuaValueRepresentable, _ rhs: LuaValueRepresentable) -> Bool {
            switch (lhs, rhs) {
            case (let l as Int64, let r as Int64):
                l < r
            case (is Int64, _):
                false
            case (_, is Int64):
                true
            case (let l as String, let r as String):
                l < r
            case (is String, _):
                false
            case (_, is String):
                true
            default:
                false
            }
        }

        public var description: String {
            "{\n" + self.keys().sorted(by: Self.keySort).map {
                let v = self[$0]
                let ist = v is Table
                return "   \($0)= \(ist ? Table.typeName + "…" : "\(v)")"
            }.joined(separator: ",\n")
            + "\n}"
        }

        open func becomeMetatableFor(_ thing: LuaValueRepresentable) {
            thing.push(vm)
            self.push(vm)
            lua_setmetatable(vm.state, -2)
            vm.pop() // thing
        }

        public func asTupleArray() -> [(LuaValueRepresentable, LuaValueRepresentable)] {
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

            let dict: [Int64: LuaValueRepresentable] = asDictionary({ (k: Int64) in k })

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
