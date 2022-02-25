//: [Previous](@previous)

import Foundation
import Darwin


let count = 2
let stride = MemoryLayout<Int>.stride
let alignment = MemoryLayout<Int>.alignment
let byteCount = stride * count

//: ## Raw Pointer

do {
    print("Raw pointers")
    
    let ptr = UnsafeMutableRawPointer.allocate(byteCount: stride * count, alignment: alignment)
    
    defer {
        ptr.deallocate()
    }
    
    ptr.storeBytes(of: 42, as: Int.self)
    ptr.advanced(by: stride).storeBytes(of: 6, as: Int.self)
    ptr.load(as: Int.self)
    ptr.advanced(by: stride).load(as: Int.self)
    
    let ptrBuffer = UnsafeRawBufferPointer(start: ptr, count: byteCount)
    for (index, byte) in ptrBuffer.enumerated() {
        print("byte \(index): \(byte)")
    }
}

//: ## Typed Pointer

do {
    let pointer = UnsafeMutablePointer<Int>.allocate(capacity: count)
    pointer.initialize(repeating: 0, count: count)
    
    defer {
        pointer.deinitialize(count: count)
        pointer.deallocate()
    }
    
    pointer.pointee = 42
    pointer.advanced(by: 1).pointee = 6
    pointer.pointee
    pointer.advanced(by: 1).pointee
    (pointer + 1).pointee
    
    let bufferPointer = UnsafeBufferPointer(start: pointer, count: count)
    for (index, value) in bufferPointer.enumerated() {
        print("value \(index): \(value)")
    }
}

//: ## Convert Raw pointer to Typed pointer

do {
    let rawPointer = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: alignment)
    
    let typedPtr = rawPointer.bindMemory(to: Int.self, capacity: count)
    typedPtr.initialize(repeating: 0, count: count)
//    defer {
//        typedPtr.deinitialize(count: count)
//    }
    
    typedPtr.pointee = 42
    (typedPtr + 1).pointee = 6
    typedPtr.pointee
    (typedPtr + 1).pointee
    
    let bufferPtr = UnsafeBufferPointer(start: typedPtr, count: count)
    for (index, value) in bufferPtr.enumerated() {
        print("value \(index): \(value)")
    }
    
    typedPtr.deinitialize(count: count)
    rawPointer.deallocate()
}

//: ## Get the bytes of an instance

//: ### Struct

do {
    var i = 32
    withUnsafeBytes(of: &i) { bytes in
        for byte in bytes {
            print(String(format:"%02X", byte), terminator: " ")
        }
        print("")
    }
    
    struct Puppy {
        let age: Int
        let isTrained: Bool
    }
    
    var puppy1 = Puppy(age: 3, isTrained: true)
    withUnsafeBytes(of: &puppy1) { bytes in
        for byte in bytes {
            print(String(format:"%02X", byte), terminator: " ")
        }
        print("")
    }
    
    struct AnotherPuppy {
        let isTrained: Bool
        let age: Int
    }
    
    var puppy2 = AnotherPuppy(isTrained: true, age: 4)
    withUnsafeBytes(of: &puppy2) { bytes in
        for byte in bytes {
            print(String(format:"%02X", byte), terminator: " ")
        }
        print("")
    }
}

//: ### Class

do {
    class EmptyClass { }
    
    print("======== \(String(describing: EmptyClass.self)) ========")
    print("size:\t\t\t \(MemoryLayout<EmptyClass>.size)") // 8
    print("stride:\t\t\t \(MemoryLayout<EmptyClass>.stride)") // 8
    print("alignment:\t\t \(MemoryLayout<EmptyClass>.alignment)") // 8
    print("instance size:\t \(class_getInstanceSize(EmptyClass.self))") // 16
    
    var obj = EmptyClass()
    
    let ptr = UnsafeRawPointer(bitPattern: unsafeBitCast(obj, to: UInt.self))!
    print("The pointer value: \(ptr)")
    
    print("The bytes of class pointer: ", terminator: "")
    withUnsafeBytes(of: &obj) { bytes in
        for byte in bytes {
            print(String(format:"%02X", byte), terminator: " ")
        }
        print("")
    }
    
    print("The bytes of instance content: ", terminator: "")
    let size = malloc_size(ptr)
    for i in 0..<size {
        let value = (ptr + i).load(as: UInt8.self)
        print(String(format:"%02X", value), terminator: " ")
    }
    print("")
    
    let obj2 = EmptyClass()
    let ptr2 = UnsafeRawPointer(bitPattern: unsafeBitCast(obj2, to: UInt.self))!
    
    print("The bytes of instance content: ", terminator: "")
    for i in 0..<malloc_size(ptr2) {
        let value = (ptr2 + i).load(as: UInt8.self)
        print(String(format:"%02X", value), terminator: " ")
    }
    print("")
}

//: [Next](@next)
