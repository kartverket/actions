package clean_with_data_test

test_alice_read_returns_true if {
	data.clean_with_data.allow with input as {"name": "Alice", "role": "read"}
}
