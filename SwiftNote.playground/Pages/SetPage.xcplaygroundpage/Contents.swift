//: [Previous](@previous)

import Foundation

//: ## 创建集合

print("\n## Initialize a set\n")

do {
    // 指定类型创建集合
    let setA: Set<String> = ["a", "b", "c"]
    print("The type of 'setA':", type(of: setA))
    print("The content of 'setA':", setA)
    
    // 使用类型推断，创建集合
    let setB: Set = ["a", "b", "c"]
    print("The type of 'setB':", type(of: setB))
    print("The content of 'setB':", setB)
    
    // 使用集合构造器初始化集合
    let setC = Set(["a", "b", "c"])
    print("The type of 'setC':", type(of: setC))
    print("The content of 'setC':", setC)
    
    // > 注：集合中的元素是无序的，每次打印结果并不相同
}

//: ## 访问集合中的元素

print("\n## Accessing elements in a set\n")

do {
    let setC = Set(["a", "b", "c"])
    for element in setC {
        print(element, terminator: " ")
    }
    print("")
    
    for (idx, value) in setC.enumerated() {
        if idx == setC.count-1 {
            print("(\(idx): \(value))")
        } else {
            print("(\(idx): \(value))", terminator: ", ")
        }
    }
}

//: ## 集合分析

print("\n## Set Analysis\n")

//: - 集合大小

let setA = Set(["a", "b", "c"])
print("The size of 'setA': ", setA.count)

//: - 判断集合是否为空

if setA.isEmpty {
    print("'setA' is empty.")
} else {
    print("'setA' is not empty.")
}

let setB: Set<String> = []
if setB.isEmpty {
    print("'setB' is empty.")
} else {
    print("'setB' is not empty.")
}

//: - 判断集合是否包含指定元素

let flag = setA.contains("a")
if flag {
    print("'setA' contain element 'a'")
} else {
    print("'setA' doesn't contain element 'a'")
}

if setA.contains("d") {
    print("'setA' contain element 'd'")
} else {
    print("'setA' doesn't contain element 'd'")
}

//: ## 集合中添加与删除元素

print("\n## Adding and removing elements from a set\n")

do {
    var aSet: Set<String> = ["a", "b", "c"]
    
    // 从集合中删除一个元素
    _ = aSet.remove("c") // Optional("c")
    
    // 从集合中删除一个不存在的元素
    _ = aSet.remove("d") // nil
    
    // 往集合中添加一个元素
    let (success, ele) = aSet.insert("d")
    print(success, ele)
    
    // 往集合中重复添加一个元素
    let ret = aSet.insert("d")
    print(ret)
    
    print(aSet)
}

//: ## 集合的比较

print("\n## Comparison of sets\n")

do {
    let setA: Set = [1, 2, 3, 4, 5]
    let setB: Set = [1, 2, 3, 4, 5]
    let setC: Set = [1, 2, 3]
    
    if setA == setB {
        print("'setA' is equal to 'setB'.")
    }
    
    if setA == setC {
        print("'setA' is equal to 'setC'.")
    } else {
        print("'setA' is not equal to 'setC'.")
    }
    
    _ = setC.isSubset(of: setA) // true
    _ = setB.isSubset(of: setA) // true
    
    _ = setB.isStrictSubset(of: setA) // false
    _ = setC.isStrictSubset(of: setA) // true
    
    _ = setA.isSuperset(of: setC) // true
    _ = setA.isStrictSuperset(of: setC) // true
}

//: ## 集合的并集与交集

print("\n## Union and intersection of sets\n")

do {
    let setA: Set = [1, 2, 3]
    let setB: Set = [2, 3, 4]
    
    let unionSetAB = setA.union(setB)
    print(unionSetAB)
    
    let intersectionAB = setA.intersection(setB)
    print(intersectionAB)
}


//: [Next](@next)
