//
//  DataToImage.swift
//  Turing_patterns
//
//  Created by David Tudor on 04/07/2025.
//

// code turning bits to Image from https://stackoverflow.com/questions/78627849/turning-an-array-of-rgb-pixel-data-into-cgimage-in-swift

import Foundation
import Cocoa
import UniformTypeIdentifiers

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

// My own code:

typealias Colour = [Int]

enum Colour_enum {
    case black
    case white
    case grey
    case blue
    case red
    case green
}

func rgb_for(col: Colour_enum) -> Colour {
    switch col {
    case .black: return [0, 0, 0]
    case .white: return [255, 255, 255]
    case .grey: return [210, 210, 210]
    case .blue: return [0, 0, 255]
    case .red: return [255, 0, 0]
    case .green: return [0, 255, 0]
    }
}


func make_PixelData(rgb: Colour) -> PixelData {
    return PixelData(a: 255, r: UInt8(rgb[0]), g: UInt8(rgb[1]), b: UInt8(rgb[2]))
}

