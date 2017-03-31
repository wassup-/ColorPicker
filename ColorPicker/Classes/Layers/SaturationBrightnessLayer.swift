//
//  SaturationBrightnessLayer.swift
//  ColorPicker-Swift
//
//  Created by Tom Knapen on 31/03/2017.
//

import CoreGraphics
import OpenGLES
import QuartzCore

class SaturationBrightnessLayer: CAEAGLLayer {

	enum Attribute: GLuint {
		case vertex = 0
		case color = 1
		case attributes = 2
	}

	private let glContext: EAGLContext = EAGLContext(api: .openGLES2)
	private var frameBuffer: GLuint = 0
	private var renderBuffer: GLuint = 0
	private var program: GLuint = 0

	var hue: CGFloat = 0 {
		didSet { setNeedsDisplay() }
	}

	override init() {
		super.init()
		commonInit()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}

	private func commonInit() {
		isOpaque = true

		EAGLContext.setCurrent(glContext)
		glGenRenderbuffers(1, &renderBuffer)
		glBindRenderbuffer(GLenum(GL_RENDERBUFFER), renderBuffer)
		glContext.renderbufferStorage(Int(GL_RENDERBUFFER), from: self)

		glGenFramebuffers(1, &frameBuffer)
		glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)
		glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER),
		                          GLenum(GL_COLOR_ATTACHMENT0),
		                          GLenum(GL_RENDERBUFFER),
		                          renderBuffer)
		loadShaders()
	}

	deinit {
		glDeleteFramebuffers(1, &frameBuffer)
		glDeleteRenderbuffers(1, &renderBuffer)
		glDeleteProgram(program)

		if EAGLContext.current() == glContext {
			EAGLContext.setCurrent(nil)
		}
	}

	override func layoutSublayers() {
		super.layoutSublayers()

		glBindRenderbuffer(GLenum(GL_RENDERBUFFER), renderBuffer)
		glContext.renderbufferStorage(Int(GL_RENDERBUFFER), from: self)
	}

	private func compileShader(_ shader: GLuint, source: String) {
		source.withCString {
			var ptr: UnsafePointer<GLchar>? = $0
			glShaderSource(shader, 1, &ptr, nil)
		}
		glCompileShader(shader)
	}

	private func loadShaders() {
		program = glCreateProgram()

		let vertexShader = glCreateShader(GLenum(GL_VERTEX_SHADER))
		let fragmentShader = glCreateShader(GLenum(GL_FRAGMENT_SHADER))

		do {
			let source = ["precision highp float;",
			              "attribute vec4 position;",
			              "varying vec2 uv;",

			              "void main()",
			              "{",
			              "  gl_Position = vec4(2.0 * position.x - 1.0, 2.0 * position.y - 1.0, 0.0, 1.0);",
			              "  uv = position.xy;",
			              "}",
			              ].joined()
			compileShader(vertexShader, source: source)
			glAttachShader(program, vertexShader)
		}

		do {
			let source = ["precision highp float;",
			              "varying vec2 uv;",
			              "uniform float hue;",

			              "vec3 hsb_to_rgb(float h, float s, float l)",
			              "{" ,
			              "  float c = l * s;",
			              "  h = mod((h * 6.0), 6.0);",
			              "  float x = c * (1.0 - abs(mod(h, 2.0) - 1.0));",
			              "  vec3 result;",

			              "  if (0.0 <= h && h < 1.0) {",
			              "      result = vec3(c, x, 0.0);",
			              "  } else if (1.0 <= h && h < 2.0) {",
			              "      result = vec3(x, c, 0.0);",
			              "  } else if (2.0 <= h && h < 3.0) {",
			              "      result = vec3(0.0, c, x);",
			              "  } else if (3.0 <= h && h < 4.0) {",
			              "      result = vec3(0.0, x, c);",
			              "  } else if (4.0 <= h && h < 5.0) {",
			              "      result = vec3(x, 0.0, c);",
			              "  } else if (5.0 <= h && h < 6.0) {",
			              "      result = vec3(c, 0.0, x);",
			              "  } else {",
			              "      result = vec3(0.0, 0.0, 0.0);",
			              "  }",

			              "  result.rgb += l - c;",

			              "  return result;",
			              "}",

			              "void main()",
			              "{",
			              "  gl_FragColor = vec4(hsb_to_rgb(hue, uv.x, uv.y), 1.0);",
			              "}",
			              ].joined()
			compileShader(fragmentShader, source: source)
			glAttachShader(program, fragmentShader)
		}

		glBindAttribLocation(program, Attribute.vertex.rawValue, "position")
		glLinkProgram(program)

		glDeleteShader(vertexShader)
		glDeleteShader(fragmentShader)
	}

	override func display() {
		super.display()

		EAGLContext.setCurrent(glContext)

		let squareVertices: [GLfloat] = [0, 0,
		                                 1, 0,
		                                 0, 1,
		                                 1, 1]

		glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)
		glViewport(0, 0, GLsizei(bounds.width), GLsizei(bounds.height))

		glUseProgram(program)


		glUniform1f(glGetUniformLocation(program, "hue"), GLfloat(hue))
		glVertexAttribPointer(Attribute.vertex.rawValue,
		                      2, GLenum(GL_FLOAT),
		                      0, 0,
		                      squareVertices)
		glEnableVertexAttribArray(Attribute.vertex.rawValue)

		glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
		glBindRenderbuffer(GLenum(GL_RENDERBUFFER), renderBuffer)
		glContext.presentRenderbuffer(Int(GL_RENDERBUFFER))
	}
}
