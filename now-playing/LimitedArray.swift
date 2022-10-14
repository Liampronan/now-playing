struct LimitedArray<T> {
    private(set) var storage: [T] = []
    public let maxSize: Int

    /// creates an empty array
    public init(maxSize: Int) {
        self.maxSize = maxSize
    }

    /// takes the max N elements from the given collection
    public init<S: Sequence>(from other: S, maxSize: Int) where S.Element == T {
        self.maxSize = maxSize
        storage = Array(other.prefix(maxSize))
    }

    /// adds a new item to the array, does nothing if the array has reached its maximum capacity
    /// returns a bool indicated the operation success
    @discardableResult public mutating func append(_ item: T) -> Bool {
        if storage.count < maxSize {
            storage.append(item)
            return true
        } else {
            return false
        }
    }

    /// inserts an item at the specified position. if this would result in
    /// the array exceeding its maxSize, the extra element are dropped
    public mutating func insert(_ item: T, at index: Int) {
        storage.insert(item, at: index)
        if storage.count > maxSize {
            storage.remove(at: maxSize)
        }
    }

    // add here other methods you might need
}

// let's benefit all the awesome operations like map, flatMap, reduce, filter, etc
extension LimitedArray: MutableCollection {
    public var startIndex: Int { return storage.startIndex }
    public var endIndex: Int { return storage.endIndex }

    public subscript(_ index: Int) -> T {
        get { return storage[index] }
        set { storage[index] = newValue }
    }

    public func index(after i: Int) -> Int {
        return storage.index(after: i)
    }
}
