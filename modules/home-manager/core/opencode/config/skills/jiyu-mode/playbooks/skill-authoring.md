# Author or evaluate a skill

1. Identify real requests the skill should handle and nearby requests it must not capture.
2. Read the upstream instructions, references and license before adapting them. Keep one source pin
   and explain meaningful local changes. Runtime-specific fields must match actual tools.
3. Put the trigger and essential decisions in SKILL.md. Move conditional detail to references. Do
   not copy generic advice, a whole manual or a second workflow router into every skill.
4. Validate frontmatter, identity, links and discovery in the target runtime. For a substantial
   behavior change, try a realistic task in an isolated workspace before and after when useful. A
   file-shape check proves packaging, not model quality. Keep comparisons blind where practical.
5. Read the resulting artifacts and verify observable behavior. Report what was tested and what was
   not. Do not install globally, publish, or alter unrelated skills outside the requested scope.
