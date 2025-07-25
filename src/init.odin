package main

import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import "base:runtime"
import "core:math"
import "core:strings"
import "core:fmt"
import "core:thread"
import "core:time"
import "core:encoding/json"
import "core:os"

window : glfw.WindowHandle
fb_size := vec2{}

init :: proc() {
    load_configs()

    init_window()
    init_opengl()
    init_fonts()

    update_thread_allocator = context.allocator

    init_update_thread()
    init_message_thread()

    fb_width, fb_height := glfw.GetFramebufferSize(window)
    fb_size = vec2{f32(fb_width), f32(fb_height)}

    home_dir := os.get_env("HOME")
    defer delete(home_dir)

    if home_dir != "" {
        os.set_current_directory(home_dir)
    }
    
    if default_cwd != "" {
        cwd = default_cwd
    } else {
        cwd = os.get_current_directory()
    }
}

size_callback :: proc "c" (
    window_handle: glfw.WindowHandle,
    width: i32,
    height: i32
) {
    fb_size = vec2{f32(width), f32(height)}
    gl.Viewport(0,0,width,height)
    
    context = runtime.default_context()
    resize_terminal()
}

@(private="package")
update_thread : ^thread.Thread
init_update_thread :: proc() {
    when ODIN_DEBUG {
        fmt.println("Initializing update thread.")
    }

    update_thread = thread.create(update)

    thread.start(update_thread)
}

@(private="package")
message_thread : ^thread.Thread

@(private="package")
terminal_thread : ^thread.Thread

@(private="package")
init_message_thread :: proc() {
    if message_thread != nil {
        when ODIN_DEBUG {
            fmt.println("Destroying existing LSP message thread..")
        }

        thread.terminate(message_thread, 9)
        thread.destroy(message_thread)
    }

    when ODIN_DEBUG {
        fmt.println("Initializing LSP message thread..")
    }

    message_thread = thread.create(message_loop)

    thread.start(message_thread)
}

init_terminal_thread :: proc() {
    if terminal_thread != nil {
        thread.terminate(terminal_thread, 9)
        thread.destroy(terminal_thread)
    }
    
    terminal_thread = thread.create(terminal_loop)

    thread.start(terminal_thread)
}

init_window :: proc() {
    when ODIN_DEBUG {
        fmt.println("Initializing window.")
    }

    did_succeed := glfw.Init()

    if (!did_succeed) {
        fmt.println("failed to init glfw")
    }


    glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, glfw.TRUE)

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    

    glfw.WindowHintString(glfw.WAYLAND_APP_ID, "Koderum")

    glfw.WindowHintString(glfw.X11_CLASS_NAME,    "Koderum")
    glfw.WindowHintString(glfw.X11_INSTANCE_NAME, "Koderum")

    primary_monitor := glfw.GetPrimaryMonitor()
    mode := glfw.GetVideoMode(primary_monitor)

    when ODIN_DEBUG {
        fmt.println("Mode:",mode)
        fmt.println("Primary Monitor:",primary_monitor)
    }
    
    window = glfw.CreateWindow(
        640,
        480,
        "Koderum",
        nil,
        nil,
    )

    if window == nil {
        panic("Could not create window.") 
    }

    glfw.SetWindowSizeLimits(window, glfw.DONT_CARE, glfw.DONT_CARE, glfw.DONT_CARE, glfw.DONT_CARE)
    
    width, height := glfw.GetWindowSize(window)

    fb_size = vec2{
        f32(width), f32(height),
    }

    glfw.SetFramebufferSizeCallback(window, size_callback)

    glfw.SetKeyCallback(window, key_callback)
    glfw.SetCharCallback(window, char_callback)

    glfw.SetScrollCallback(window, scroll_callback)
    glfw.SetCursorPosCallback(window, cursor_callback)
    glfw.SetMouseButtonCallback(window, mouse_button_callback)

    glfw.MakeContextCurrent(window)

    glfw.SwapInterval(1)

    gl.load_up_to(3, 3, glfw.gl_set_proc_address)
}

vbo : u32
vao : u32
ebo : u32

@(private="package")
projection_loc : i32

@(private="package")
view_loc : i32

@(private="package")
first_texture_loc : i32

@(private="package")
world_tint_loc : i32

@(private="package")
shader_id : u32

init_opengl :: proc() {
    when ODIN_DEBUG {
        fmt.println("Initializing opengl.")
    }

    gl.GenBuffers(1, &vbo)
    gl.GenBuffers(1, &ebo)
    gl.GenVertexArrays(1, &vao)

    vertex_source :: #load("./shaders/vertex.glsl")
    fragment_source :: #load("./shaders/fragment.glsl")

    prog_id, ok := gl.load_shaders_source(
        string(vertex_source),
        string(fragment_source),
    )

    shader_id = prog_id

    if !ok {
        fmt.println("Failed to load vertex and fragment shader")

        infoLog : [^]u8 = {}
        gl.GetShaderInfoLog(prog_id,512,nil,infoLog)
        
        fmt.println(infoLog)

        panic("Critical failure.")
    }

    projection_loc = gl.GetUniformLocation(prog_id, "cameraProjection")
    view_loc = gl.GetUniformLocation(prog_id, "cameraView")
    first_texture_loc = gl.GetUniformLocation(prog_id, "firstTexture")

    gl.BindVertexArray(vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 9 * size_of(f32), uintptr(0))
    gl.EnableVertexAttribArray(0)

    gl.VertexAttribPointer(1, 2, gl.FLOAT, false, 9 * size_of(f32), uintptr(3 * size_of(f32)))
    gl.EnableVertexAttribArray(1)

    gl.VertexAttribPointer(2, 4, gl.FLOAT, false, 9 * size_of(f32), uintptr(5 * size_of(f32)))
    gl.EnableVertexAttribArray(2)

    gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)

    gl.GenTextures(1, &font_texture_id)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, font_texture_id)
}
