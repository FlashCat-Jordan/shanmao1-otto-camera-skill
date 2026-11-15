# Agent Rules

When using this Skill:

1. Read `SKILL.md` first, then only the reference needed for the task.
2. Run `scripts/check-env.sh` before claiming the environment is ready.
3. Never expose or modify the user's Wi-Fi credentials or NVS without explicit permission.
4. Prefer app-only flashing when the user wants to keep provisioning.
5. Do not change GPIOs, servo limits, partition tables or wake-word models without confirming the hardware/model source.
6. Do not claim a fix is verified from a successful build; hardware behavior needs a real board test.
7. Keep changes minimal and explain the owning layer.
8. Do not add camera preview/vision tasks to a firmware that is supposed to show only the two-eye face.
9. Respect third-party licenses (ESP-SR models, firmware, assets).
