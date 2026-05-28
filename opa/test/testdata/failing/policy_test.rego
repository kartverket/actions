package example_test

import data.example

# This test asserts the opposite of what the policy does — it expects alice to
# be denied, but the policy allows her. Used by the test workflow to verify the
# action correctly fails when tests fail.
test_alice_denied if not example.allow with input as {"user": "alice"}
