package main

import "core:os"
import "core:fmt"
import "core:strings"
import gl "vendor:OpenGL"
import "vendor:glfw"
import "base:runtime"
import "core:unicode/utf8"
import "core:strconv"
import "core:path/filepath"
import ft "../../alt-odin-freetype"

highlight_start_line : int
highlight_start_char : int

@(private="package")
handle_highlight_input :: proc() {
    if is_key_pressed(glfw.KEY_ESCAPE) || is_key_pressed(glfw.KEY_V) {
        input_mode = .COMMAND

        return
    } 

    if is_key_pressed(glfw.KEY_Y) {
        key := key_store[glfw.KEY_Y]

        if key.modifiers == 2 {
            copy_to_clipboard(
                highlight_start_line,
                buffer_cursor_line,
                highlight_start_char,
                buffer_cursor_char_index,
            )
        } else {
            copy_to_yank_buffer(
                highlight_start_line,
                buffer_cursor_line,
                highlight_start_char,
                buffer_cursor_char_index,
            )
        }

        return
    }

    if is_key_pressed(glfw.KEY_C) {
        copy_to_yank_buffer(
            highlight_start_line,
            buffer_cursor_line,
            highlight_start_char,
            buffer_cursor_char_index,
        )

        remove_selection(
            highlight_start_line,
            buffer_cursor_line,
            highlight_start_char,
            buffer_cursor_char_index,
        )

        input_mode = .COMMAND

        return
    }
    
    if is_key_pressed(glfw.KEY_X) {
        remove_selection(
            highlight_start_line,
            buffer_cursor_line,
            highlight_start_char,
            buffer_cursor_char_index,
        )

        input_mode = .COMMAND

        return
    }
    
    if is_key_pressed(glfw.KEY_P) {
        remove_selection(
            highlight_start_line,
            buffer_cursor_line,
            highlight_start_char,
            buffer_cursor_char_index,
        )
            
        paste_string(yank_buffer.data[0], buffer_cursor_line, buffer_cursor_char_index)
        
        input_mode = .COMMAND
    }

    if is_key_pressed(glfw.KEY_G) {
        buffer_search_term = generate_highlight_string(
            highlight_start_line,
            buffer_cursor_line,
            highlight_start_char,
            buffer_cursor_char_index,
        ) 

        input_mode = .SEARCH

        find_search_hits()
    }
    
    if is_key_pressed(glfw.KEY_E) {
        indent_selection(
            highlight_start_line,
            buffer_cursor_line,
        )
        
        return
    }
    
    if is_key_pressed(glfw.KEY_W) {
        unindent_selection(
            highlight_start_line,
            buffer_cursor_line,
        )
        
        return
    }

    handle_movement_input()
}
