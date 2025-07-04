//
//  ContentView.swift
//  Turing_patterns
//
//  Created by David Tudor on 04/07/2025.
//


///
/// Bitmap to store an image.
///


import SwiftUI
import SwiftData

import Foundation
import Cocoa
import UniformTypeIdentifiers

struct ScreenImage {
    var bitmap: Bitmap
    let width: Int
    let height: Int
    
    func set_pix(x: Int, y: Int, r: Int, g: Int, b : Int, a: Int = 255) {
        bitmap[x, y] = Bitmap.RGBA(r: UInt8(r), g: UInt8(g), b: UInt8(b), a: UInt8(a))
    }
    
    func get_rgba(x: Int, y: Int) -> [Int] {
        let pix = bitmap[x, y]
        return [Int(pix.r), Int(pix.g), Int(pix.b), Int(pix.a)]
    }
    
    static func initWithBitmap(bitmap: Bitmap) -> ScreenImage {
        return ScreenImage(bitmap: bitmap, width: bitmap.width, height: bitmap.height)
    }
    
    static func initWithSize(width: Int, height: Int) -> ScreenImage {
        return ScreenImage(bitmap: nil, width: width, height: height)
    }
    
    init(bitmap: Bitmap?, width: Int?, height: Int?) {
        let default_size = [200, 200]
        self.width = width ?? default_size[0]
        self.height = height ?? default_size[1]
        self.bitmap = bitmap ?? {
                return try! Bitmap(width: width ?? default_size[0], height: height ?? default_size[1])
        }()
//        self.bitmap.draw { ctx in
//            ctx.setFillColor(.black)
//            ctx.fill([CGRect(x: 5, y: 5, width: 20, height: 20)])
//        }
//        let rgbaPixel = bitmap[4, 3]
//        bitmap[4, 3] = Bitmap.RGBA(r: 255, g: 0, b: 0, a: 255)
    }

}

// code turning bits to Image from https://stackoverflow.com/questions/78627849/turning-an-array-of-rgb-pixel-data-into-cgimage-in-swift
extension CGImage
{
    var png: Data?
    {
        let cfdata: CFMutableData = CFDataCreateMutable(nil, 0)
        if let destination = CGImageDestinationCreateWithData(cfdata, String(describing: UTType.png) as CFString, 1, nil)
        {
            CGImageDestinationAddImage(destination, self, nil)
            if CGImageDestinationFinalize(destination)
            {
                return cfdata as Data
            }
        }
        return nil
    }
}

struct PixelData {
    var a:UInt8 = 255
    var r:UInt8
    var g:UInt8
    var b:UInt8
}

func pixeldata_to_image(pixels: [PixelData], width: Int, height: Int) -> CGImage
{
    assert(pixels.count == Int(width * height))
    let bitsPerComponent: Int = 8
    let bitsPerPixel: Int = 32
    let bitsPerByte = 8
    let bytesPerPixel: Int = bitsPerPixel/bitsPerByte
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)

    var data = pixels
    guard
        let providerRef = CGDataProvider(data: NSData(bytes: &data, length: data.count * bytesPerPixel))
    else
    {
        fatalError("CGDataProvider failure")
    }
    guard
        let image = CGImage(
            width: width,
            height: height,
            bitsPerComponent:bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: width * bytesPerPixel,
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    else
    {
        fatalError("CGImage failure")
    }
    return image
}

func testUsage()
{
    let range_x: Int = 200
    let range_y: Int = 200
    let greyPixel = PixelData(a: 255, r: 128, g: 128, b: 128)
    let blackPixel = PixelData(a: 255, r: 0, g: 0, b: 0)
    let whitePixel = PixelData(a: 255, r: 255, g: 255, b: 255)
    let yellowPixel = PixelData(a: 255, r: 255, g: 255, b: 0)
    let greenPixel = PixelData(a: 255, r: 0, g: 255, b: 0)
    let redPixel = PixelData(a: 255, r: 255, g: 0, b: 0)
    var pixelData = [PixelData](repeating: greyPixel, count: Int(range_x * range_y))
    var index: Int = 0
    //populate pixelData
    for x in 0 ..< range_x
    {
        for y in 0 ..< range_y
        {
            let pixel: PixelData
            if x == 0 && y == 0 || x == 0 && y == range_x - 1 || x == 8 && y == 8
            {
                //grey draw specfic pixels
                pixel = greyPixel
            }
            else if x == y
            {
                //yellow draw diagonal from top-left to bottom-right
                pixel = yellowPixel
            }
            else if y == 0 || x == 0
            {
                //dblack raw top line and draw left line
                pixel = blackPixel
            }
            else if y == range_y - 1 || x == range_y - 1
            {
                //white draw bottom line and draw right line
                pixel = whitePixel
            }
            else if y == range_y / 2 || x == range_x / 2
            {
                //green draw horizontal center line and draw vertical center line
                pixel = greenPixel
            }
            else
            {
                pixel = redPixel
            }
            //print("x:", x, "y:", y, "index:", index, "pixel:", pixel) //sanity check
            pixelData[index] = pixel
            index += 1
        }
    }
    let image: CGImage = pixeldata_to_image(pixels: pixelData, width: range_x, height: range_y)
    try? image.png!.write(to: URL(fileURLWithPath: "pixeldata.png"))
}


struct ContentView: View {
    
//    var screenImage = ScreenImage.initWithSize(width: 200, height: 200)

    var bitmap = try! Bitmap(width:200,height: 200)
    
    
//    init() {
//    }
    
    
    var body: some View {
        
    
//        let cg = bitmap.makeCGImage()
//        Image(cg, scale: 1, label: Text("gi"))
    }
}

