#!/bin/bash
# Script to update verification progress in TASKS.md

TASKS_FILE="/Users/johnrobertdelinila/AndroidStudioProjects/Juan-Heart-Mobile/TASKS.md"

# Count verified tasks (looking for "✅ VERIFIED" status)
VERIFIED_COUNT=$(grep -c "✅ VERIFIED" "$TASKS_FILE" 2>/dev/null || echo "0")
TOTAL=11

PERCENT=$((VERIFIED_COUNT * 100 / TOTAL))

# Visual progress bar
FILLED=$((VERIFIED_COUNT))
EMPTY=$((TOTAL - VERIFIED_COUNT))
BAR=$(printf '⬛%.0s' $(seq 1 $FILLED))$(printf '⬜%.0s' $(seq 1 $EMPTY))

echo "Verification Progress: $VERIFIED_COUNT/$TOTAL ($PERCENT%)"
echo "Progress: $BAR"
echo ""
echo "Remaining: $EMPTY tasks"
