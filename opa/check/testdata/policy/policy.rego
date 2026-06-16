package clean_with_data

import rego.v1

default allow := false

# METADATA
# entrypoint: true
# schemas:
#   - input: schema["input"]
allow if {
    role := data.permissions[input.name]
    role == input.roles
}
