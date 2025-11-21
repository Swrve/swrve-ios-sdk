// Method Swizzling for the getNow function of Swrve
// Please make sure to swizzle/unswizzle in each test's respective setup/teardown function
extension Swrve {

    static var originalGetNowMethod: Method?
    static var swizzledGetNowMethod: Method?

    static let swizzle: Void = {
        let originalSelector = #selector(Swrve.getNow)
        let swizzledSelector = #selector(Swrve.mockGetNow)

        originalGetNowMethod = class_getInstanceMethod(Swrve.self, originalSelector)
        swizzledGetNowMethod = class_getInstanceMethod(Swrve.self, swizzledSelector)

        if let originalMethod = originalGetNowMethod,
            let swizzledMethod = swizzledGetNowMethod
        {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }()

    @objc func mockGetNow() -> Date {
        Date(timeIntervalSince1970: 1362873600)  // March 10, 2013
    }

    // Unswizzle to restore the original method behavior
    static func unswizzle() {
        if let originalMethod = originalGetNowMethod, let swizzledMethod = swizzledGetNowMethod {
            method_exchangeImplementations(swizzledMethod, originalMethod)
        }
    }
}
