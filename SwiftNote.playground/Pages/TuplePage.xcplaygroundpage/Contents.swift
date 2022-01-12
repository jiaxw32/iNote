//: [Previous](@previous)

import Foundation


//: [Next](@next)


//: # Swift Tuple

//: ## 初始化 Tuple

//: - 省略标签

// 元组中的元素数据类型可以不同
let tuple0 = ("John", 35, true)
print(type(of: tuple0))
print(tuple0)

//: - 使用标签
var tuple1 = (name: "John", age: 35, gender: true)
print(tuple1)

//: ## 访问元素中的元素

//: - 通过索引访问元素
let element0 = tuple1.0
print(element0)

//: - 使用标签访问元素
let element1 = tuple1.age
print(element1)

//: - 分解元素，使用下划线(_)可以忽略元素
let (element_0, element_1, _) = tuple0
print(element_0, element_1)

//: ## 修改元组元素

print("The tuple before update: \(tuple1)")
tuple1.age = 60
print("The tuple after update: \(tuple1)")

//: ## 作为函数返回值

func getATuple() -> (String, Int, Bool) {
    return ("John", 35, true)
}

// 使用下划线忽略元组值
let (name, age, _) = getATuple()
print("\(name)'s age was \(age)")
