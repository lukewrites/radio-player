import Testing
import Foundation
@testable import RadioPlayer

@Suite("ImageCache")
struct ImageCacheTests {

    @Test("stores and retrieves data by URL")
    func storeAndRetrieve() {
        let cache = ImageCache()
        let url = URL(string: "https://example.com/img/show-a")!
        let data = Data([0x89, 0x50, 0x4E, 0x47]) // fake PNG header

        cache[url] = data
        #expect(cache[url] == data)
    }

    @Test("returns nil for unknown URL")
    func cacheMiss() {
        let cache = ImageCache()
        let url = URL(string: "https://example.com/img/unknown")!
        #expect(cache[url] == nil)
    }

    @Test("different URLs are independent")
    func differentURLsIndependent() {
        let cache = ImageCache()
        let urlA = URL(string: "https://archive.org/services/img/OTRR_Gunsmoke_Singles")!
        let urlB = URL(string: "https://archive.org/services/img/OTRR_Abbott_Costello_Singles")!
        let dataA = Data([0x01])
        let dataB = Data([0x02])

        cache[urlA] = dataA
        cache[urlB] = dataB

        #expect(cache[urlA] == dataA)
        #expect(cache[urlB] == dataB)
    }

    @Test("overwriting a URL replaces data")
    func overwrite() {
        let cache = ImageCache()
        let url = URL(string: "https://example.com/img/show")!

        cache[url] = Data([0x01])
        cache[url] = Data([0x02])

        #expect(cache[url] == Data([0x02]))
    }

    @Test("clear removes all entries")
    func clearAll() {
        let cache = ImageCache()
        let url = URL(string: "https://example.com/img/show")!
        cache[url] = Data([0x01])

        cache.clear()

        #expect(cache[url] == nil)
    }
}
