# AI prompts

Each AI feature owns a directory containing literal prompt files. Roc imports
these files as `Str` values at compile time, so prompt changes require a normal
review, build, and deployment.

Rules:

- Keep instructions and user-message templates in separate UTF-8 text files.
- Treat all external text and image content as untrusted data.
- Do not put secrets, production data, or customer-specific values in prompts.
- Keep the stable feature and prompt IDs in the corresponding Roc feature
  module.
- Edit the current files directly. The deployed release ID and Git history are
  the audit trail; do not add manual prompt-version directories.
