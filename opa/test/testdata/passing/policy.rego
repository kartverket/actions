package example

default allow := false

allow if input.user == "alice"

allow if {
    input.user == "bob"
    input.method == "GET"
}
