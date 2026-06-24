# Faunty i18n Workflow

1. **Add new strings in code**
   - Use: `translation(context: context, 'Text')`
   - The `context:` parameter is optional but useful if the widget would ever need its own language.

2. **Extract all translation keys**
   - Run in terminal:
     ```sh
     dart lib/tools/extract_t_strings_ast.dart
     ```

3. **Autotranslate missing keys**
   - Use Copilot to fill missing keys in `de.i18n.json`, `tr.i18n.json`, `ru.i18n.json`.

4. **Generate slang files**
   - Run in terminal:
     ```sh
     dart run slang
     ```

5. **Done!**

---

Automation will be added in the future. 