package example_test

import data.example

test_alice_allowed if example.allow with input as {"user": "alice"}

test_bob_get_allowed if example.allow with input as {"user": "bob", "method": "GET"}

test_bob_post_denied if not example.allow with input as {"user": "bob", "method": "POST"}

test_stranger_denied if not example.allow with input as {"user": "eve"}
