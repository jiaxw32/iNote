//: [Previous](@previous)

import Foundation

print("======== \(String(describing: Bool.self)) ========")
print("size:\t\t \(MemoryLayout<Bool>.size)")
print("stride:\t\t \(MemoryLayout<Bool>.stride)")
print("alignment:\t \(MemoryLayout<Bool>.alignment)")


print("======== \(String(describing: Int.self)) ========")
print("size:\t\t \(MemoryLayout<Int>.size)")
print("stride:\t\t \(MemoryLayout<Int>.stride)")
print("alignment:\t \(MemoryLayout<Int>.alignment)")


struct Puppy {
    let age: Int
    let isTrained: Bool
}

print("======== \(String(describing: Puppy.self)) ========")
print("size:\t\t \(MemoryLayout<Puppy>.size)")
print("stride:\t\t \(MemoryLayout<Puppy>.stride)")
print("alignment:\t \(MemoryLayout<Puppy>.alignment)")

struct AnotherPuppy {
    let isTrained: Bool
    let age: Int
}

print("======== \(String(describing: AnotherPuppy.self)) ========")
print("size:\t\t \(MemoryLayout<AnotherPuppy>.size)")
print("stride:\t\t \(MemoryLayout<AnotherPuppy>.stride)")
print("alignment:\t \(MemoryLayout<AnotherPuppy>.alignment)")

struct CertifiedPuppy {
    let age: Int
    let isTrained: Bool
    let isCertified: Bool
}

print("======== \(String(describing: CertifiedPuppy.self)) ========")
print("size:\t\t \(MemoryLayout<CertifiedPuppy>.size)")
print("stride:\t\t \(MemoryLayout<CertifiedPuppy>.stride)")
print("alignment:\t \(MemoryLayout<CertifiedPuppy>.alignment)")

struct AnotherCertifiedPuppy {
    let isTrained: Bool
    let age: Int
    let isCertified: Bool
}

print("======== \(String(describing: AnotherCertifiedPuppy.self)) ========")
print("size:\t\t \(MemoryLayout<AnotherCertifiedPuppy>.size)")
print("stride:\t\t \(MemoryLayout<AnotherCertifiedPuppy>.stride)")
print("alignment:\t \(MemoryLayout<AnotherCertifiedPuppy>.alignment)")


class EmptyClass {
    
}

print("======== \(String(describing: EmptyClass.self)) ========")
print("size:\t\t\t \(MemoryLayout<EmptyClass>.size)") // 8
print("stride:\t\t\t \(MemoryLayout<EmptyClass>.stride)") // 8
print("alignment:\t\t \(MemoryLayout<EmptyClass>.alignment)") // 8
print("instance size:\t \(class_getInstanceSize(EmptyClass.self))") // 16

class PuppyClass {
    let isTrained: Bool = false
    let age: Int = 3
}

print("======== \(String(describing: PuppyClass.self)) ========")
print("size:\t\t\t \(MemoryLayout<PuppyClass>.size)") // 8
print("stride:\t\t\t \(MemoryLayout<PuppyClass>.stride)") // 8
print("alignment:\t\t \(MemoryLayout<PuppyClass>.alignment)") // 8
print("instance size:\t \(class_getInstanceSize(PuppyClass.self))") // 16

class AnotherPuppyClass {
    let age: Int = 3
    let isTrained: Bool = false
}

print("======== \(String(describing: AnotherPuppyClass.self)) ========")
print("size:\t\t\t \(MemoryLayout<AnotherPuppyClass>.size)") // 8
print("stride:\t\t\t \(MemoryLayout<AnotherPuppyClass>.stride)") // 8
print("alignment:\t\t \(MemoryLayout<AnotherPuppyClass>.alignment)") // 8
print("instance size:\t \(class_getInstanceSize(AnotherPuppyClass.self))") // 16



//: [Next](@next)
