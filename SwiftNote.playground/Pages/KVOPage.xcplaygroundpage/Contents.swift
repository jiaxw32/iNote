//: [Previous](@previous)

import Foundation

/*
 1. KVO 与属性观察(willSet 和 didSet) 类似，但是 KVO 可以在类型定义外添加观察者
 2. KVO 依赖 Objective-C 的 Runtime，在纯 Swift 代码中并不适用
 3. 只有继承自 NSObject 的类，可以使用 KVO，需要观察的属性使用 @objc 和 dynamic 修饰符标记
 */

extension NSKeyValueObservation {
    @objc func _swizzle_me_observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSString : Any]?, context: UnsafeMutableRawPointer?) {
        print("_swizzle_me_observeValue gets called")
    }
}

//: ## KVO 示例一

class Person: NSObject {
    @objc dynamic var name: String = "Taylor Swift"
}

let person = Person()
person.observe(\Person.name, options: .new) { person, change in
    print("I'm now called \(person.name)")
}

person.name = "Justin Bieber"

//: ## KVO 示例二

// MyObjectToObserve 必须继承于 NSObject
class MyObjectToObserve: NSObject {
    // 使用 @objc 和 dynamic 修饰需要观察的属性
    @objc dynamic var myDate = NSDate(timeIntervalSince1970: 0)
    
    func updateDate() {
        myDate = myDate.addingTimeInterval(Double(2 << 30)) // Adds about 68 years.
    }
}

// MyObserver 也要继承自 NSObject
class MyObserver: NSObject {
    @objc var objectToObserve: MyObjectToObserve
    var observation: NSKeyValueObservation?
    
    init(object: MyObjectToObserve) {
        objectToObserve = object
        super.init()
        
        observation = observe(\.objectToObserve.myDate, options: [.new, .old], changeHandler: { object, change in
            print("myDate changed from \(change.oldValue!), updated to: \(change.newValue!)")
        })
    }
}

let observed = MyObjectToObserve()
let observer = MyObserver(object: observed)
observed.updateDate()

//: ## 参考资料

//: * [What is key-value observing?](https://www.hackingwithswift.com/example-code/language/what-is-key-value-observing)
//: * [Using Key-Value Observing in Swift](https://developer.apple.com/documentation/swift/cocoa_design_patterns/using_key-value_observing_in_swift)
//: * [Method Swizzling: What, Why and How](https://trinhngocthuyen.github.io/posts/tech/method-swizzling-what-why-and-how/)


//: [Next](@next)
