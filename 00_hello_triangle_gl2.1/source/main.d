module main;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import std.stdio;
import std.string;
import std.exception;
import std.conv;

static this()
{
	DerelictGL3.load();
	DerelictGLFW3.load();
}

static ~this()
{
	DerelictGLFW3.unload();
	DerelictGL3.unload();
}


int main( string[] args )
{
	const GLubyte* rendererStr;
	const GLubyte* versionStr;
	GLuint vao;
	GLuint vbo;

	GLfloat[] points = [
		0.0f, 0.5f, 0.0f,
		0.5f, -0.5f, 0.0f,
		-0.5f, -0.5f, 0.0f
	];

	string vShaderCode =
`
#version 120

in vec3 vp;
void main()
{
	gl_Position = vec4( vp, 1.0 );
}

`;

	string fShaderCode =
`
#version 120

out vec4 frag_color;
void main()
{
	frag_color = vec4( 0.5, 0.0, 0.5, 1.0 );
}

`;

	GLuint vShader, fShader;
	GLuint shaderProgram;

	enforce( glfwInit(), "GLFW Init failed." );
	scope ( exit ) glfwTerminate();
	
	glfwWindowHint( GLFW_CONTEXT_VERSION_MAJOR, 2 );
	glfwWindowHint( GLFW_CONTEXT_VERSION_MINOR, 1 );
	//glfwWindowHint( GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE );
	//glfwWindowHint( GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE );
	
	auto window = glfwCreateWindow( 800, 600, ("Hello Triangle").toStringz(), null, null );
	enforce( window !is null, "Can't create window" );
	
	glfwMakeContextCurrent( window );
	
	auto glVersion = DerelictGL3.reload();

	writefln("Vendor:   %s",   to!string(glGetString(GL_VENDOR)));
  writefln("Renderer: %s",   to!string(glGetString(GL_RENDERER)));
  writefln("Version:  %s",   to!string(glGetString(GL_VERSION)));
  writefln("GLSL:     %s\n", to!string(glGetString(GL_SHADING_LANGUAGE_VERSION)));

  glEnable( GL_DEPTH_TEST );
  glDepthFunc( GL_LESS );

  glGenBuffers( 1, &vbo );
  glBindBuffer( GL_ARRAY_BUFFER, vbo );
  glBufferData( GL_ARRAY_BUFFER, points.length * GLfloat.sizeof, points.ptr, GL_STATIC_DRAW );
  writeln( "VBO +" );

  glGenVertexArrays( 1, &vao );
  writeln("1");
  glBindVertexArray( vao );
  writeln("2");
  glEnableVertexAttribArray( 0 );
  writeln("3");
  glBindBuffer( GL_ARRAY_BUFFER, vbo );
  writeln("4");
  glVertexAttribPointer( 0, 3, GL_FLOAT, GL_FALSE, 0, null );
  writeln( "VAO +" );

  vShader = glCreateShader( GL_VERTEX_SHADER );
  const( char* ) vCodePtr = vShaderCode.ptr;
  glShaderSource( vShader, 1, &vCodePtr, null );
  glCompileShader( vShader );
  writeln( "vShader +" );
  fShader = glCreateShader( GL_FRAGMENT_SHADER );
  const( char* ) fCodePtr = fShaderCode.ptr;
  glShaderSource( fShader, 1, &fCodePtr, null );
  glCompileShader( fShader );
  writeln( "fShader +" );

  shaderProgram = glCreateProgram();
  glAttachShader( shaderProgram, vShader );
  glAttachShader( shaderProgram, fShader );
  glLinkProgram( shaderProgram );
  writeln( "Program +" );

// extra test >> //
  int status, logLen;
  glGetProgramiv( shaderProgram, GL_LINK_STATUS, &status );
  glGetProgramiv( shaderProgram, GL_INFO_LOG_LENGTH, &logLen );

  if ( logLen > 1 )
  {
  	char[] log = new char[]( logLen );
  	glGetProgramInfoLog( shaderProgram, logLen, null, log.ptr );
  	writefln( "Shader program linking log:\n%s", log );
  }
// << extra test //

	glDeleteShader( vShader );
	glDeleteShader( fShader );

  writeln("BEFORE LOOP");
	while (!glfwWindowShouldClose(window))
	{
		glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
		//glUseProgram( shaderProgram );
		glBindVertexArray( vao );

		glDrawArrays( GL_TRIANGLES, 0, 3 );

		glfwPollEvents();

		glfwSwapBuffers(window);
	}

	return ( 0 );
}
