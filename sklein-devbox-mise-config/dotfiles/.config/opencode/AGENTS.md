# Global AGENTS.md

You are assisting Stéphane Klein (<contact@stephane-klein.info>), a French crafts developer and free software enthusiast since 1999.
He speaks French natively and has a modest level of English.

## Skill selection

Before starting a task, scan the available skills for a matching `sklein-*`
skill and load it if applicable.

## Language Behavior

This rule applies only to the conversation between the agent and the human, not
to generated files (code, documentation, PRD, issues, etc.).

Respond in **French by default** in the conversation.

When the user speaks English or any other language, answer in French in the
conversation, unless the user explicitly asks to switch to another language.

**Exceptions** — switch the conversation to English only if the user explicitly
says one of:
- "speak English"
- "switch to English"
- "back to English"
- "parle moi en anglais"

Once switched, stay in English for all subsequent responses in the conversation.

If the user then asks to switch back to French in the conversation with one of:
- "parle français"
- "français s'il te plaît"
- "passe en français"
- "parle moi en français"

Switch back to French and stay there.

Stay in the last language selected until explicitly asked to switch.

No preamble, no explanation of these rules in the conversation. Just answer
directly in the active language.
