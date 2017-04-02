import GLKit
import OpenGLES

func BUFFER_OFFSET(_ i: Int) -> UnsafeRawPointer {
    return UnsafeRawPointer(bitPattern: i)!
}

let UNIFORM_MODELVIEWPROJECTION_MATRIX = 0
let UNIFORM_NORMAL_MATRIX = 1
var uniforms = [GLint](repeating: 0, count: 2)

class GlViewController: GLKViewController {
    
    var modelViewProjectionMatrix:GLKMatrix4 = GLKMatrix4Identity
    var normalMatrix: GLKMatrix3 = GLKMatrix3Identity
    var rotation: Float = 0.0

    var context: EAGLContext? = nil

    deinit {
        self.tearDownGL()
        
        if EAGLContext.current() === self.context {
            EAGLContext.setCurrent(nil)
        }
    }
    
    var miPadModel: Mesh?
    
    var glass: Mesh?
    var camera: Mesh?
    var logo: Mesh?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        
        //// LOAD model from obj
        
        miPadModel = ModelIO.importOBJ(name: "case")
        glass = ModelIO.importOBJ(name: "glass")
        camera = ModelIO.importOBJ(name: "camera")
        logo = ModelIO.importOBJ(name: "logo")
        
        self.context = EAGLContext(api: .openGLES2)
        
        if !(self.context != nil) {
            print("Failed to create ES context")
        }
        
        let view = self.view as! GLKView
        view.context = self.context!
        view.drawableDepthFormat = .format24
        
        self.setupGL()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        if self.isViewLoaded && (self.view.window != nil) {
            self.view = nil
            
            self.tearDownGL()
            
            if EAGLContext.current() === self.context {
                EAGLContext.setCurrent(nil)
            }
            self.context = nil
        }
    }
    
    func setupGL() {
        EAGLContext.setCurrent(self.context)

        miPadModel?.setup(color: GLKVector4Make(0.6, 0.6, 0.6, 1.0), glossyFac: 0.3)
        glass?.setup(color: GLKVector4Make(0.05, 0.05, 0.05, 1.0), glossyFac: 0.3)
        logo?.setup(color: GLKVector4Make(0.3, 0.3, 0.3, 1.0), glossyFac: 0.3)
        camera?.setup(color: GLKVector4Make(0.1, 0.1, 0.1, 1.0), glossyFac: 0.3)
        
        glEnable(GLenum(GL_DEPTH_TEST))
        
    }
    
    func tearDownGL() {
        EAGLContext.setCurrent(self.context)
        
        miPadModel?.tearDown()
        glass?.tearDown()
        camera?.tearDown()
        logo?.tearDown()
    }
    
    func update() {
        let aspect = fabsf(Float(self.view.bounds.size.width / self.view.bounds.size.height))
        let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), aspect, 0.1, 100.0)
        
        var baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -10.0)
        baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, rotation, 1.0, 1.0, 0.0)
        
        var modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -10.5)
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, rotation, 1.0, 1.0, 1.0)
        modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix)

        modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, 0)
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, rotation, 1.0, 1.0, 1.0)
        modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix)
        
        normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), nil)
        modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix)
        
        miPadModel?.update(modelViewMatrix: modelViewMatrix, projectionMatrix: projectionMatrix)
        glass?.update(modelViewMatrix: modelViewMatrix, projectionMatrix: projectionMatrix)
        camera?.update(modelViewMatrix: modelViewMatrix, projectionMatrix: projectionMatrix)
        logo?.update(modelViewMatrix: modelViewMatrix, projectionMatrix: projectionMatrix)
        
        rotation += Float(self.timeSinceLastUpdate * 0.10)
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClearColor(0.9, 0.91, 0.93, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
        
        miPadModel?.draw()
        glass?.draw()
        camera?.draw()
        logo?.draw()

    }
    
    
}

