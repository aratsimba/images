#!/bin/bash
# ValidateService FAILING hook - deliberately exits with code 1
# Used to test automatic rollback behavior

echo "ValidateService (FAIL): This script is designed to FAIL."
echo "ValidateService (FAIL): Simulating a validation failure..."
exit 1
