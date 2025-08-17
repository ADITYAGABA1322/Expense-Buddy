import Foundation

class CacheService {
    static let shared = CacheService()
    
    private let cache = NSCache<NSString, CacheItem>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Setup cache directory
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent("ExpenseBuddyCache")
        
        // Create cache directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configure memory cache
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    // MARK: - Memory Cache
    func setMemoryCache<T: Codable>(_ object: T, forKey key: String, expiry: TimeInterval = 300) {
        let cacheItem = CacheItem(data: object, expiry: Date().addingTimeInterval(expiry))
        cache.setObject(cacheItem, forKey: NSString(string: key))
    }
    
    func getMemoryCache<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let cacheItem = cache.object(forKey: NSString(string: key)),
              !cacheItem.isExpired else {
            cache.removeObject(forKey: NSString(string: key))
            return nil
        }
        return cacheItem.data as? T
    }
    
    // MARK: - Disk Cache
    func setDiskCache<T: Codable>(_ object: T, forKey key: String) {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        
        do {
            let data = try JSONEncoder().encode(object)
            try data.write(to: url)
        } catch {
            print("Failed to cache to disk: \(error)")
        }
    }
    
    func getDiskCache<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            return nil
        }
    }
    
    // MARK: - Cache Management
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func removeCacheForKey(_ key: String) {
        cache.removeObject(forKey: NSString(string: key))
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        try? fileManager.removeItem(at: url)
    }
}

private class CacheItem: NSObject {
    let data: Any
    let expiry: Date
    
    init(data: Any, expiry: Date) {
        self.data = data
        self.expiry = expiry
    }
    
    var isExpired: Bool {
        return Date() > expiry
    }
}
