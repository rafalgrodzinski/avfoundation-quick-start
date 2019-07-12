//
//  URL+TempFile.swift
//  AVFoundation Quick Start Part 2
//
//  Created by Rafal Grodzinski on 11/07/2019.
//  Copyright © 2019 UnalignedByte. All rights reserved.
//

import Foundation

extension URL {
    static func tempFile(withFileExtension fileExtension: String) -> URL {
        let fileName = "\(NSUUID().uuidString).\(fileExtension)"
        let filePathString = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
        return URL(fileURLWithPath: filePathString)
    }
}
