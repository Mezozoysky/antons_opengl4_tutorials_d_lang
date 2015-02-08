module main;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import std.stdio;
import std.string;
import std.exception;
import std.conv;
import std.datetime;

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


const string logFileName = "gl.log";

bool restartGLLog()
{
  try
  {
    auto file = File( logFileName, "w" );
    auto time = Clock.currTime();
    file.writefln( "GLLog stars. Local time: %s", time );
    file.writefln( "build time: %s %s", __DATE__, __TIME__ );
  }
  catch ( Exception ex )
  {
    return false;
  }
  return true;
}

bool glLog( string message ) nothrow
{
  try
  {
    auto file = File( logFileName, "a" );
    file.writeln( message );
  }
  catch( Exception ex )
  {
    return false;
  }
  return true;
}

bool glLogErr( string message ) nothrow
{
  try
  {
    stderr.writeln( message );
    auto file = File( logFileName, "a" );
    file.writeln( message );
  }
  catch ( Exception ex )
  {
    return false;
  }
  return true;
}

extern (C) void glfwErrorCallback( int error, const ( char )* description ) nothrow
{
  glLogErr( "GLFW Error #" ~ to!(string)( error ) ~ ": " ~ to!(string)( description ) );
}

int gGLWidth = 640;
int gGLHeight = 480;

extern (C) void glfwWindowSizeCallback( GLFWwindow* window, int width, int height ) nothrow
{
  gGLWidth = width;
  gGLHeight = height;
  glLog( "Resize: " ~ to!(string)( width ) ~ ", " ~ to!(string)( height ) );
  /*update here*/
}

void logGLParams()
{
  glLog( "-------------------------" );
  glLog( "GL context params:" );

  int v;
  glGetIntegerv( GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, &v );
  glLog( GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS.stringof ~ ": " ~ to!string( v ) );
  glGetIntegerv( GL_MAX_CUBE_MAP_TEXTURE_SIZE, &v );
  glLog( GL_MAX_CUBE_MAP_TEXTURE_SIZE.stringof ~ ": " ~ to!string( v ) );
  glGetIntegerv( GL_MAX_DRAW_BUFFERS, &v );
  glLog( GL_MAX_DRAW_BUFFERS.stringof ~ ": " ~ to!string( v ) );
  glGetIntegerv( GL_MAX_FRAGMENT_UNIFORM_COMPONENTS, &v );
  glLog( GL_MAX_FRAGMENT_UNIFORM_COMPONENTS.stringof ~ ": " ~ to!string( v ) );
  glGetIntegerv( GL_MAX_TEXTURE_IMAGE_UNITS, &v );
  glLog( GL_MAX_TEXTURE_IMAGE_UNITS.stringof ~ ": " ~ to!string( v ) );
  glGetIntegerv( GL_MAX_TEXTURE_SIZE, &v );
  glLog( GL_MAX_TEXTURE_SIZE.stringof ~ ": " ~ to!string( v ) );
  glGetIntegerv( GL_MAX_VARYING_FLOATS, &v );
  glLog( GL_MAX_VARYING_FLOATS.stringof ~ ": " ~ to!string( v ) );
  glGetIntegerv( GL_MAX_VERTEX_ATTRIBS, &v );
  glLog( GL_MAX_VERTEX_ATTRIBS.stringof ~ ": " ~ to!string( v ) );
  glGetIntegerv( GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS, &v );
  glLog( GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS.stringof ~ ": " ~ to!string( v ) );
  glGetIntegerv( GL_MAX_VERTEX_UNIFORM_COMPONENTS, &v );
  glLog( GL_MAX_VERTEX_UNIFORM_COMPONENTS.stringof ~ ": " ~ to!string( v ) );

  int[2] va;
  glGetIntegerv( GL_MAX_VIEWPORT_DIMS, va.ptr );
  glLog( GL_MAX_VIEWPORT_DIMS.stringof ~ ": " ~ to!string( va[ 0 ] ) ~ ", " ~ to!string( va[ 1 ] ) );

  ubyte s = 0;
  glGetBooleanv( GL_STEREO, &s );
  glLog( GL_STEREO.stringof ~ ": " ~ to!string( s ) );
}

double prevSecs;
int frameCount;

void updateFPSCounter( GLFWwindow* window )
{
  double currSecs, elapsedSecs;

  currSecs = glfwGetTime();
  elapsedSecs = currSecs - prevSecs;
  if ( elapsedSecs > 0.25 )
  {
    prevSecs = currSecs;
    double fps = cast(double)( frameCount ) / elapsedSecs;
    glfwSetWindowTitle( window, ("opengl @ fps: " ~ to!string( fps )).toStringz() );
    frameCount = 0;
  }
  ++frameCount;
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
#version 410

in vec3 vp;
void main()
{
	gl_Position = vec4( vp, 1.0 );
}

`;

	string fShaderCode =
`
#version 410

out vec4 frag_color;
void main()
{
	frag_color = vec4( 0.5, 0.0, 0.5, 1.0 );
}

`;

	GLuint vShader, fShader;
	GLuint shaderProgram;

  enforce( restartGLLog(), "Can't start GLLog" );
  glLog( "Starting GLFW " ~ to!(string)( glfwGetVersionString() ) );
  glfwSetErrorCallback( &glfwErrorCallback );

	enforce( glfwInit(), "GLFW Init failed." );
	scope ( exit ) glfwTerminate();
	
	glfwWindowHint( GLFW_CONTEXT_VERSION_MAJOR, 4 );
	glfwWindowHint( GLFW_CONTEXT_VERSION_MINOR, 1 );
	glfwWindowHint( GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE );
	glfwWindowHint( GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE );
	
  /*
  auto mon = glfwGetPrimaryMonitor();
  auto vmode = glfwGetVideoMode( mon );
  auto window = glfwCreateWindow( vmode.width, vmode.height, "Extended GL Init", mon, null );
  */
	auto window = glfwCreateWindow( 800, 600, ("Extended init").toStringz(), null, null );
	enforce( window !is null, "Can't create window" );

  glfwSetWindowSizeCallback( window, &glfwWindowSizeCallback );
	glfwMakeContextCurrent( window );
	
  glfwWindowHint( GLFW_SAMPLES, 4 );

	auto glVersion = DerelictGL3.reload();

	writefln("Vendor:   %s",   to!string(glGetString(GL_VENDOR)));
  writefln("Renderer: %s",   to!string(glGetString(GL_RENDERER)));
  writefln("Version:  %s",   to!string(glGetString(GL_VERSION)));
  writefln("GLSL:     %s\n", to!string(glGetString(GL_SHADING_LANGUAGE_VERSION)));

  logGLParams();

  glEnable( GL_DEPTH_TEST );
  glDepthFunc( GL_LESS );

  glGenBuffers( 1, &vbo );
  glBindBuffer( GL_ARRAY_BUFFER, vbo );
  glBufferData( GL_ARRAY_BUFFER, points.length * GLfloat.sizeof, points.ptr, GL_STATIC_DRAW );

  glGenVertexArrays( 1, &vao );
  glBindVertexArray( vao );
  glEnableVertexAttribArray( 0 );
  glBindBuffer( GL_ARRAY_BUFFER, vbo );
  glVertexAttribPointer( 0, 3, GL_FLOAT, GL_FALSE, 0, null );

  vShader = glCreateShader( GL_VERTEX_SHADER );
  const( char* ) vCodePtr = vShaderCode.ptr;
  glShaderSource( vShader, 1, &vCodePtr, null );
  glCompileShader( vShader );
  fShader = glCreateShader( GL_FRAGMENT_SHADER );
  const( char* ) fCodePtr = fShaderCode.ptr;
  glShaderSource( fShader, 1, &fCodePtr, null );
  glCompileShader( fShader );

  shaderProgram = glCreateProgram();
  glAttachShader( shaderProgram, vShader );
  glAttachShader( shaderProgram, fShader );
  glLinkProgram( shaderProgram );

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

	while (!glfwWindowShouldClose(window))
	{
    updateFPSCounter( window );

		glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    //glViewport( 0, 0, 800, 600 );
		glUseProgram( shaderProgram );
		glBindVertexArray( vao );

		glDrawArrays( GL_TRIANGLES, 0, 3 );

		glfwPollEvents();
    if ( GLFW_PRESS == glfwGetKey( window, GLFW_KEY_ESCAPE ) )
    {
      glfwSetWindowShouldClose( window, 1 );
    }

		glfwSwapBuffers(window);
	}

	return ( 0 );
}
