# Mir

Mir is a Metal-powered framework for interactive maps and navigation experiences.

![The default Mir globe, rendered offscreen by the test suite](.github/assets/globe.png)

## Testing

Run the tests with `xcodebuild`, which compiles the Metal shaders (`swift test` doesn't):

```bash
cd Mir
xcodebuild test -scheme Mir -destination 'platform=macOS'
```

To save the frames the render tests draw as PNG files, pass a folder in `TEST_RUNNER_MIR_TEST_OUTPUT_DIR`.
