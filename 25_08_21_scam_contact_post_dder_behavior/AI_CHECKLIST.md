# 🤖 AI ASSISTANT MANDATORY CHECKLIST

## WHEN USER SAYS "SAVE TO LOG" - FOLLOW THIS EXACTLY:

### ✅ STEP-BY-STEP PROTOCOL:

1. **FIRST**: Execute `date +%Y-%m-%d` command
2. **SECOND**: Copy the EXACT output (e.g., "2025-08-21")
3. **THIRD**: Create/update file `logs/[EXACT-DATE].md`
4. **FOURTH**: Use same EXACT date in content headers

### ❌ FORBIDDEN ACTIONS:
- NEVER assume what today's date is
- NEVER use dates from other files
- NEVER use hypothetical dates like "2025-01-15"
- NEVER skip the `date` command

### 🚨 RECENT CRITICAL ERROR EXAMPLE:
- ❌ BAD: Used "2025-01-15" when actual date was "2025-08-21"
- ✅ GOOD: Run `date +%Y-%m-%d` → get "2025-08-21" → use exactly that

## REMEMBER: THIS IS A CRITICAL USER REQUIREMENT
Wrong dates break their entire logging workflow!
