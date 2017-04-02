//
//  ModelIO.swift
//  wwdc-app
//
//  Created by Lukas Valine on 4/2/17.
//  Copyright © 2017 Lukas Valine. All rights reserved.
//

import Foundation
import GLKit


class ModelIO {
    
    static func importOBJ(name: String) -> Mesh {
        
        let path = Bundle.main.path(forResource: name, ofType: "obj")!
        
        let file = StreamReader.init(path: path)
        
        
        var vertices = [GLfloat]()
        var indices = [GLshort]()
        var normalIndices = [GLshort]()
        
        var rawNormalsX = [GLfloat]()
        var rawNormalsY = [GLfloat]()
        var rawNormalsZ = [GLfloat]()
        
        while let line = file?.nextLine() {
            
            let prefix = line.components(separatedBy:  " ").first!
            
            if prefix == "v" {
                
                let values  = line.components(separatedBy:  " ")
                
                for value in values {

                    if let floatValue = GLfloat(value) {
                        vertices.append(floatValue)
                    }
                }
                
            } else if prefix == "f" {
                
                let values  = line.components(separatedBy:  " ")
                
                for value in values {
                    
                    if value != "f" {
                        let subValues = value.components(separatedBy: "//")
                
                        if subValues.count == 2 {
                            indices.append(GLshort(subValues[0])! - 1)
                            normalIndices.append(GLshort(subValues[1])! - 1)
                        }
                    }
                }
                
                
            } else if prefix == "vn" {
                let values  = line.components(separatedBy:  " ")
                
                let floatValue = GLfloat(values[1])
                rawNormalsX.append(floatValue!)

                let floatValuey = GLfloat(values[2])
                rawNormalsY.append(floatValuey!)
                
                let floatValuez = GLfloat(values[3])
                rawNormalsZ.append(floatValuez!)

                
            }
        }
        
        var normals = [GLfloat](repeating: 0, count:normalIndices.count * 3)
        
        var k = 0;
        for value in normalIndices {
            
            let vertex: Int16 = indices[k]
            
            normals[Int(vertex * 3)] = rawNormalsX[Int(value)]
            normals[Int(vertex * 3) + 1] = rawNormalsY[Int(value)]
            normals[Int(vertex * 3) + 2] = rawNormalsZ[Int(value)]
            
            k += 1
        }
        
        var mixedVertsAndNormals = [GLfloat]()
        
        for i in 0...(vertices.count / 3)  - 1 {
            mixedVertsAndNormals.append(vertices[i * 3])
            mixedVertsAndNormals.append(vertices[i * 3 + 1])
            mixedVertsAndNormals.append(vertices[i * 3 + 2])
            
            mixedVertsAndNormals.append(normals[i * 3])
            mixedVertsAndNormals.append(normals[i * 3 + 1])
            mixedVertsAndNormals.append(normals[i * 3 + 2])
        }
        
        return Mesh(vertices: mixedVertsAndNormals, indices: indices, normals: normals)
    }
}


class StreamReader  {
    
    let encoding : UInt
    let chunkSize : Int
    
    var fileHandle : FileHandle!
    let buffer : NSMutableData!
    let delimData : NSData!
    var atEof : Bool = false
    
    init?(path: String, delimiter: String = "\n", chunkSize : Int = 4096) {
        self.chunkSize = chunkSize
        self.encoding = String.Encoding.utf8.rawValue
        
        if let fileHandle = FileHandle(forReadingAtPath: path),
            let delimData = delimiter.data(using: String.Encoding(rawValue: encoding)),
            let buffer = NSMutableData(capacity: chunkSize)
        {
            self.fileHandle = fileHandle
            self.delimData = delimData as NSData!
            self.buffer = buffer
        } else {
            self.fileHandle = nil
            self.delimData = nil
            self.buffer = nil
            return nil
        }
    }
    
    deinit {
        self.close()
    }
    
    /// Return next line, or nil on EOF.
    func nextLine() -> String? {
        precondition(fileHandle != nil, "Attempt to read from closed file")
        
        if atEof {
            return nil
        }
        
        // Read data chunks from file until a line delimiter is found:
        var range = buffer.range(of: delimData as Data, options: [], in: NSMakeRange(0, buffer.length))
        while range.location == NSNotFound {
            let tmpData = fileHandle.readData(ofLength: chunkSize)
            if tmpData.count == 0 {
                // EOF or read error.
                atEof = true
                if buffer.length > 0 {
                    // Buffer contains last line in file (not terminated by delimiter).
                    let line = NSString(data: buffer as Data, encoding: encoding)
                    
                    buffer.length = 0
                    return line as String?
                }
                // No more lines.
                return nil
            }
            buffer.append(tmpData)
            range = buffer.range(of: delimData as Data, options: [], in: NSMakeRange(0, buffer.length))
        }
        
        // Convert complete line (excluding the delimiter) to a string:
        let line = NSString(data: buffer.subdata(with: NSMakeRange(0, range.location)),
                            encoding: encoding)
        // Remove line (and the delimiter) from the buffer:
        buffer.replaceBytes(in: NSMakeRange(0, range.location + range.length), withBytes: nil, length: 0)
        
        return line as String?
    }
    
    /// Start reading from the beginning of file.
    func rewind() -> Void {
        fileHandle.seek(toFileOffset: 0)
        buffer.length = 0
        atEof = false
    }
    
    /// Close the underlying file. No reading must be done after calling this method.
    func close() -> Void {
        fileHandle?.closeFile()
        fileHandle = nil
    }
}


