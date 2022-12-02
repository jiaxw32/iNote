const mainModule = Process.enumerateModulesSync()[0];
var startAddr = mainModule.base;
var endAddr = startAddr.add(mainModule.size);
console.log("Module name: " + mainModule.name + ", size: " + mainModule.size);
console.log('base address: ' + startAddr + ', end address: ' + endAddr);

// console.log(hexdump(mainModule.base));

var addr = Module.findExportByName("libSystem.B.dylib", "_dyld_get_image_vmaddr_slide");
var _dyld_get_image_vmaddr_slide = new NativeFunction(addr, "long", ["uint"]);
var slide = _dyld_get_image_vmaddr_slide(0);
console.log("slide: 0x" + slide.toString(16));

const pattern = '01 10 00 D4'; // svc 0x80

Memory.scan(mainModule.base, mainModule.size, pattern, {
    onMatch(address, size) {
       const offset = address.sub(slide);
       console.log('found svc instruction at', address, ", offset: ", offset);
    },
    onComplete() {
      console.log('Memory.scan() complete');
    }
});