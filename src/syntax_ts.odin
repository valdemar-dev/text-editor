#+feature dynamic-literals
#+private file
package main

import "core:strings"
import ts "../../odin-tree-sitter"

@(private="package")
ts_ts_colors : map[string]vec4 = {
    "string.fragment"=TOKEN_COLOR_02,
    "string"=TOKEN_COLOR_02,
    "async"=TOKEN_COLOR_10,
    "variable.declaration"=TOKEN_COLOR_01,
    "error"=TOKEN_COLOR_00,
    "keyword"=TOKEN_COLOR_00,
    "keyword.special"=TOKEN_COLOR_10,
    "control.flow"=TOKEN_COLOR_10,
    "constant"=TOKEN_COLOR_05,
    "variable.builtin"=TOKEN_COLOR_05,
    "escape_sequence"=TOKEN_COLOR_07,
    "private_field"=TOKEN_COLOR_06,
    "punctuation.delimiter"=TOKEN_COLOR_03,
    "punctuation.bracket"=TOKEN_COLOR_03,
    "punctuation.parenthesis"=TOKEN_COLOR_03,
    "punctuation.special"=TOKEN_COLOR_03,
    "operator"=TOKEN_COLOR_03,
    "function.method"=TOKEN_COLOR_04,
    "function"=TOKEN_COLOR_04,
    "comment"=TOKEN_COLOR_03,
    "property"=TOKEN_COLOR_06,
    "parameter"=TOKEN_COLOR_06,
    "number"=TOKEN_COLOR_11, 
    "constant.builtin"=TOKEN_COLOR_09,
    "type.builtin"=TOKEN_COLOR_07,
    "type"=TOKEN_COLOR_08,
    "string.special"=TOKEN_COLOR_00,
}

@(private="package")
ts_ts_query_src := strings.clone_to_cstring(strings.concatenate({`
(ERROR) @error

["meta"] @property
(property_identifier) @property

(function_expression
  name: (identifier) @function)
(function_declaration
  name: (identifier) @function)
(method_definition
  name: (property_identifier) @function.method)

(pair
  key: (property_identifier) @function.method
  value: [(function_expression) (arrow_function)])

(assignment_expression
  left: (member_expression
    property: (property_identifier) @function.method)
  right: [(function_expression) (arrow_function)])

(variable_declarator
  name: (identifier) @function
  value: [(function_expression) (arrow_function)])

(assignment_expression
  left: (identifier) @function
  right: [(function_expression) (arrow_function)])

(call_expression
  function: (identifier) @function)

(call_expression
  function: (member_expression
    property: (property_identifier) @function.method))

([
    (identifier)
    (shorthand_property_identifier)
    (shorthand_property_identifier_pattern)
 ] @constant
 (#match? @constant "^[A-Z_][A-Z\\d_]+$"))

(escape_sequence) @escape_sequence
(this) @variable.builtin
(super) @variable.builtin

[
  (true)
  (false)
  (null)
  (undefined)
] @constant.builtin

(comment) @comment

(template_string
 (string_fragment) @string)

(template_literal_type
 (string_fragment) @string)


(private_property_identifier) @private_field

(formal_parameters (required_parameter (identifier) @parameter))

(string) @string

(regex) @string.special
(number) @number

[
  ";"
  (optional_chain)
  "."
  ","
] @punctuation.delimiter

[
  "-"
  "--"
  "-="
  "+"
  "++"
  "+="
  "*"
  "*="
  "**"
  "**="
  "/"
  "/="
  "%"
  "%="
  "<"
  "<="
  "<<"
  "<<="
  "="
  "=="
  "==="
  "!"
  "!="
  "!=="
  "=>"
  ">"
  ">="
  ">>"
  ">>="
  ">>>"
  ">>>="
  "~"
  "^"
  "&"
  "|"
  "^="
  "&="
  "|="
  "&&"
  "-?:"
  "?"
  "||"
  "??"
  "&&="
  "||="
  "??="
  ":"
  "@"
  "..."
] @operator

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
  "${"
]  @punctuation.bracket

[
  "as"
  "class"
  "const"
  "continue"
  "debugger"
  "delete"
  "export"
  "extends"
  "from"
  "function"
  "get"
  "import"
  "in"
  "instanceof"
  "new"
  "return"
  "set"
  "static"
  "target"
  "typeof"
  "void"
  "yield"
] @keyword

[
  "var"
  "let"
] @variable.declaration

[
  "while"
  "if"
  "else"
  "break"
  "throw"
  "with"
  "catch"
  "finally"
  "case"
  "switch"
  "try"
  "do"
  "default"
  "of"
  "for"
] @control.flow

[
  "async"
  "await"
] @async

[
    "global"
    "module"
    "infer"
    "extends"
    "keyof"
    "as"
    "asserts"
    "is"
] @keyword.special

(type_identifier) @type
(predefined_type) @type.builtin

((identifier) @type
 (#match? @type "^[A-Z]"))

(type_arguments
  "<" @punctuation.bracket
  ">" @punctuation.bracket)

(required_parameter (identifier) @variable.parameter)
(optional_parameter (identifier) @variable.parameter)

[ "abstract"
  "declare"
  "enum"
  "export"
  "implements"
  "interface"
  "keyof"
  "namespace"
  "private"
  "protected"
  "public"
  "type"
  "readonly"
  "override"
  "satisfies"
] @keyword

`, " [\"`\"] @string"}));

@(private="package")
ts_lsp_colors := map[string]vec4{
    "parameter"=TOKEN_COLOR_06,
}


@(private="package")
ts_override_node_type :: proc(
    node_type: ^string,
    node: ts.Node, 
    source: []u8,
    start_point,
    end_point: ^ts.Point,
    tokens: ^[dynamic]Token,
    priority: ^u8,
) {
    if node_type^ == "function.method" || node_type^ == "parameter" {
        resize(tokens, len(tokens)-1)
    } else if len(tokens) > 0 {
        latest_token := tokens[len(tokens)-1]

        if latest_token.char == i32(start_point.col) {
            node_type^ = "SKIP"
        }
    }
}

