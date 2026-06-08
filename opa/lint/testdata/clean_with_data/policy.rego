package clean_with_data

import rego.v1

default allow := false

# METADATA
# entrypoint: true
allow if {
	role := data.permissions[input.name]
	role == input.role
}
