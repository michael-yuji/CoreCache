
public enum Branch<T> {
    case tree(SigularTree<T>)
    case leaf(T)
    
    @discardableResult
    public func treeValue() -> SigularTree<T>? {
        if case let .tree(t) = self {
            return t
        }
        return nil
    }
    
    @discardableResult
    public func leafValue() -> T? {
        if case let .leaf(t) = self {
            return t
        }
        return nil
    }
}

public final class SigularTree<T> {
    
    public init() {}
    
    var branches = [String : Branch<T>]()
    
    //    public subscript(queries: String...) -> T? {
    //        get {
    //            var current: SigularTree<T> = self
    //            var queries = queries
    //            let lastquery = queries.removeLast()
    //            for query in queries {
    //                guard let result = branches[query] else {
    //                    return nil
    //                }
    //                switch result {
    //                case let .tree(t):
    //                    current = t
    //                default:
    //                    return nil
    //                }
    //            }
    //            return current.branches[lastquery]?.leafValue()
    //        } set {
    //            if let newValue = newValue {
    //                addLeaf(at: queries, as: newValue)
    //            }
    //        }
    //    }
    
    
    public subscript(queries: String...) -> Branch<T>? {
        
        get {
            var current: SigularTree<T> = self
            var queries = queries
            let lastquery = queries.removeLast()
            for query in queries {
                guard let result = branches[query] else {
                    return nil
                }
                switch result {
                case let .tree(t):
                    current = t
                default:
                    return nil
                }
            }
            
            
            return current.branches[lastquery]
        }
        
        set(newValue) {
            switch newValue {
            case let .some(V):
                switch V {
                case .tree:
                    addBranch(at: queries)
                case let .leaf(leaf):
                    addLeaf(at: queries, as: leaf)
                }
            case .none:
                addLeaf(at: queries, as: nil)
            }
        }
    }
    
    @discardableResult
    public func addLeaf(at queries: String..., as x: T?) -> Void? {
        var queries = queries
        let lastq = queries.removeLast()
        var current: SigularTree<T> = self
        for query in queries {
            var result = branches[query]
            if result == nil  {
                branches[query] = .tree(SigularTree<T>())
                result = branches[query]
            }
            switch result! {
            case let .tree(t):
                current = t
            default:
                return nil
            }
        }
        
        guard let x = x else {
            current.branches[lastq] = nil
            return Void()
        }
        
        current.branches[lastq] = .leaf(x)
        return Void()
    }
    
    @discardableResult
    public func addBranch(at queries: String..., as1 tx: SigularTree<T>? = SigularTree<T>()) -> Void? {
        var queries = queries
        let lastq = queries.removeLast()
        var current: SigularTree<T> = self
        for query in queries {
            var result = branches[query]
            if result == nil  {
                branches[query] = .tree(SigularTree<T>())
                result = branches[query]
            }
            switch result! {
            case let .tree(t):
                current = t
            default:
                return nil
            }
        }
        
        guard let x = tx else {
            current.branches[lastq] = nil
            return Void()
        }
        
        current.branches[lastq] = .tree(x)
        return Void()
    }
    
    @discardableResult
    public func addLeaf(at queries: [String], as x: T?) -> Void? {
        var queries = queries
        let lastq = queries.removeLast()
        var current: SigularTree<T> = self
        for query in queries {
            var result = branches[query]
            if result == nil  {
                branches[query] = .tree(SigularTree<T>())
                result = branches[query]
            }
            switch result! {
            case let .tree(t):
                current = t
            default:
                return nil
            }
        }
        
        guard let x = x else {
            current.branches[lastq] = nil
            return Void()
        }
        
        current.branches[lastq] = .leaf(x)
        return Void()
    }
    
    @discardableResult
    public func addBranch(at queries: [String]) -> Void? {
        var queries = queries
        let lastq = queries.removeLast()
        var current: SigularTree<T> = self
        for query in queries {
            var result = branches[query]
            if result == nil  {
                branches[query] = .tree(SigularTree<T>())
                result = branches[query]
            }
            switch result! {
            case let .tree(t):
                current = t
            default:
                return nil
            }
        }
        current.branches[lastq] = .tree(SigularTree<T>())
        return Void()
    }
    
    public static func make<T>(branches: () -> [String: Branch<T>]) -> Branch<T> {
        let root = SigularTree<T>()
        root.branches = branches()
        return .tree(root)
    }
}
