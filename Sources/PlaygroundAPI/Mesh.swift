//
//  Mesh.swift
//  wwdc-app
//
//  Created by Lukas Valine on 4/2/17.
//  Copyright © 2017 Lukas Valine. All rights reserved.
//

import Foundation
import GLKit


class Mesh {
    
    init(vertices: [GLfloat], indices: [GLshort] , normals: [GLfloat] ) {
        
        self.vertices = vertices
        self.indices = indices
        self.normals = normals
    }
    
    var effect: GLKBaseEffect? = nil
    
    var vertexArray: GLuint = 0
    var vertexBuffer: GLuint = 0
    
    var program: GLuint = 0
    
    var vertices: [GLfloat] = []
    var indices: [GLshort] = []
    var normals: [GLfloat] = []
    
    func setup(color: GLKVector4, glossyFac: GLfloat) {
        
        program = glCreateProgram()
        
        if(self.loadShaders() == false) {
            print("Failed to load shaders")
        }
        
        self.effect = GLKBaseEffect()
        self.effect!.light0.enabled = GLboolean(GL_TRUE)
        self.effect!.light0.diffuseColor = color
//        
//        // Load texture for reflection
//        let mTextureDataHandle = createTexture(fileName: "empty");
//        
//        glActiveTexture(GLenum(GL_TEXTURE0));
//        glBindTexture(GLenum(GL_TEXTURE_CUBE_MAP), mTextureDataHandle);
//        
//        let textureUniformHandle = glGetUniformLocation(program, "uTexture");
//        // here GL_TEXTURE0 is used so the uniform must be set to 0
//        glUniform1i(textureUniformHandle, 0);
//        
        glGenVertexArraysOES(1, &vertexArray)
        glBindVertexArrayOES(vertexArray)
        
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(MemoryLayout<GLfloat>.size * (self.vertices.count)), self.vertices, GLenum(GL_STATIC_DRAW))
        
        let positionHandle = Int(glGetAttribLocation(program, UnsafePointer("position")))
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 24, UnsafeRawPointer(bitPattern: positionHandle))
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.normal.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.normal.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 24, BUFFER_OFFSET(12))
        
        glBindVertexArrayOES(0)
    }
    
    func update(modelViewMatrix: GLKMatrix4, projectionMatrix: GLKMatrix4) {
        
        
        self.effect?.transform.modelviewMatrix = modelViewMatrix
        
        self.effect?.transform.projectionMatrix = projectionMatrix
    }
    
    func draw() {
        
        glBindVertexArrayOES(vertexArray)
        
        // Render the object with GLKit
        self.effect?.prepareToDraw()
        
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei((self.indices.count)), GLenum(GL_UNSIGNED_SHORT), self.indices)
    }
    
    func loadShaders() -> Bool {
        var vertShader: GLuint = 0
        var fragShader: GLuint = 0
        var vertShaderPathname: String
        var fragShaderPathname: String
        
        // Create shader program.
        program = glCreateProgram()
        
        // Create and compile vertex shader.
        vertShaderPathname = Bundle.main.path(forResource: "Shader", ofType: "vsh")!
        if self.compileShader(&vertShader, type: GLenum(GL_VERTEX_SHADER), file: vertShaderPathname) == false {
            print("Failed to compile vertex shader")
            return false
        }
        
        // Create and compile fragment shader.
        fragShaderPathname = Bundle.main.path(forResource: "Shader2", ofType: "fsh")!
        if !self.compileShader(&fragShader, type: GLenum(GL_FRAGMENT_SHADER), file: fragShaderPathname) {
            print("Failed to compile fragment shader")
            return false
        }
        
        // Attach vertex shader to program.
        glAttachShader(program, vertShader)
        
        // Attach fragment shader to program.
        glAttachShader(program, fragShader)
        
        // Bind attribute locations.
        // This needs to be done prior to linking.
        glBindAttribLocation(program, GLuint(GLKVertexAttrib.position.rawValue), "position")
        glBindAttribLocation(program, GLuint(GLKVertexAttrib.normal.rawValue), "normal")
        
        // Link program.
        if !self.linkProgram(program) {
            print("Failed to link program: \(program)")
            
            if vertShader != 0 {
                glDeleteShader(vertShader)
                vertShader = 0
            }
            if fragShader != 0 {
                glDeleteShader(fragShader)
                fragShader = 0
            }
            if program != 0 {
                glDeleteProgram(program)
                program = 0
            }
            
            return false
        }
        
        // Get uniform locations.
        uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(program, "modelViewProjectionMatrix")
        uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(program, "normalMatrix")
        
        // Release vertex and fragment shaders.
        if vertShader != 0 {
            glDetachShader(program, vertShader)
            glDeleteShader(vertShader)
        }
        if fragShader != 0 {
            glDetachShader(program, fragShader)
            glDeleteShader(fragShader)
        }
        
        return true
    }
    
    func linkProgram(_ prog: GLuint) -> Bool {
        var status: GLint = 0
        glLinkProgram(prog)
        
        glGetProgramiv(prog, GLenum(GL_LINK_STATUS), &status)
        if status == 0 {
            return false
        }
        
        return true
    }
    
    func validateProgram(prog: GLuint) -> Bool {
        var logLength: GLsizei = 0
        var status: GLint = 0
        
        glValidateProgram(prog)
        glGetProgramiv(prog, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        if logLength > 0 {
            var log: [GLchar] = [GLchar](repeating: 0, count: Int(logLength))
            glGetProgramInfoLog(prog, logLength, &logLength, &log)
            print("Program validate log: \n\(log)")
        }
        
        glGetProgramiv(prog, GLenum(GL_VALIDATE_STATUS), &status)
        var returnVal = true
        if status == 0 {
            returnVal = false
        }
        return returnVal
    }
    
//    func createTexture(fileName:NSString)->GLuint{
//
//        
//        let pic1 = UIImage(named: "cube_tile_0001.png" as String)
//
//    
//        
//        if(pic1 == nil){
//
//            return 0;
//            
//        } else {
//            
//            //var pixelData: GLubyte!
//            
//            let imageCS = pic1!.cgImage!.colorSpace;
//            let width =  UInt(pic1!.size.width);
//            let height = UInt(pic1!.size.height);
//            let size = width * height * 8;
//            var pixelData = [GLubyte](repeating: 0, count: Int(size) );
//            
//           // pixelData.insert(size, at: 0);
//            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue);
//            let gc = CGContext(data: &pixelData, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: Int(UInt(width*4)), space: imageCS!, bitmapInfo: bitmapInfo.rawValue);
//            let rect = CGRect(x: 0, y: 0, width: pic1!.size.width, height: pic1!.size.height);
//            gc?.draw(pic1!.cgImage!, in: rect)
//        
//            //Create GL Texture
//            
//            var texture: GLuint = 0;
//            
//            glGenTextures(GLsizei(1), &texture);
////            
////            glBindTexture(GLenum(GL_TEXTURE_2D), texture);
////            
////            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR_MIPMAP_LINEAR);
////            
////            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR);
////            
////            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE);
////            
////            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE);
////            
////            glTexImage2D(GLenum(GL_TEXTURE_2D), GLint(0), GL_RGBA, GLsizei(pic!.size.width), GLsizei(pic!.size.height), GLint(0), GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), &pixelData);
////            
////            glGenerateMipmap(GLenum(GL_TEXTURE_2D));
//            
//            glBindTexture(GLenum(GL_TEXTURE_CUBE_MAP), texture);
//            
//            
//            // Load the bitmap into the bound texture.
//            //            GLUtils.texImage2D(GL_TEXTURE_2D, 0, bitmap, 0);
//            
//            glTexImage2D(GLenum(GL_TEXTURE_CUBE_MAP_POSITIVE_X),0, GL_RGB, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGB), GLenum(GL_UNSIGNED_BYTE), pixelData)
//            
//            glTexImage2D(GLenum(GL_TEXTURE_CUBE_MAP_POSITIVE_X + 1),0, GL_RGB, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGB), GLenum(GL_UNSIGNED_BYTE), pixelData)
//            
//            glTexImage2D(GLenum(GL_TEXTURE_CUBE_MAP_POSITIVE_X + 2),0, GL_RGB, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGB), GLenum(GL_UNSIGNED_BYTE), pixelData)
//            
//            glTexImage2D(GLenum(GL_TEXTURE_CUBE_MAP_POSITIVE_X + 3),0, GL_RGB, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGB), GLenum(GL_UNSIGNED_BYTE), pixelData)
//            
//            glTexImage2D(GLenum(GL_TEXTURE_CUBE_MAP_POSITIVE_X + 4),0, GL_RGB, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGB), GLenum(GL_UNSIGNED_BYTE), pixelData)
//            
//            glTexImage2D(GLenum(GL_TEXTURE_CUBE_MAP_POSITIVE_X + 5),0, GL_RGB, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGB), GLenum(GL_UNSIGNED_BYTE), pixelData)
//            
//            glTexImage2D(GLenum(GL_TEXTURE_CUBE_MAP_POSITIVE_X + 6),0, GL_RGB, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGB), GLenum(GL_UNSIGNED_BYTE), pixelData)
//            
//
//            
//            glGenerateMipmap(GLenum(GL_TEXTURE_CUBE_MAP));
//            
//            glTexParameteri(GLenum(GL_TEXTURE_CUBE_MAP), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR);
//            glTexParameteri(GLenum(GL_TEXTURE_CUBE_MAP), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR);
//            glTexParameteri(GLenum(GL_TEXTURE_CUBE_MAP), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE);
//            glTexParameteri(GLenum(GL_TEXTURE_CUBE_MAP), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE);
//            glTexParameteri(GLenum(GL_TEXTURE_CUBE_MAP), GLenum(GL_TEXTURE_WRAP_R), GL_CLAMP_TO_EDGE);
//            
//            return texture;
//            
//        }
//        
//    }

    
    
    func compileShader(_ shader: inout GLuint, type: GLenum, file: String) -> Bool {
        var status: GLint = 0
        var source: UnsafePointer<Int8>
        do {
            source = try NSString(contentsOfFile: file, encoding: String.Encoding.utf8.rawValue).utf8String!
        } catch {
            print("Failed to load vertex shader")
            return false
        }
        var castSource: UnsafePointer<GLchar>? = UnsafePointer<GLchar>(source)
        
        shader = glCreateShader(type)
        glShaderSource(shader, 1, &castSource, nil)
        glCompileShader(shader)
        
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &status)
        if status == 0 {
            glDeleteShader(shader)
            return false
        }
        return true
    }
    
    
    func tearDown() {
        
        glDeleteBuffers(1, &vertexBuffer)
        glDeleteVertexArraysOES(1, &vertexArray)
        
        self.effect = nil
        
        if program != 0 {
            glDeleteProgram(program)
            program = 0
        }

        
    }
}
