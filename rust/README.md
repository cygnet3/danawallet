## Rust component

This is the rust component of Dana wallet.

We use flutter\_rust\_bridge to generate bindings between the flutter and rust components.

### Updating the api

When making any changes to the api (`src/api.rs`), the bindings need to be regenerated.

First install the codegen

```
cargo install flutter_rust_bridge_codegen
```

Then generate the bindings

```
just gen
```

or just copy the command found in the justfile.

After generating the bindings, you will need to recreate the binaries as well. See the main README of this repository on how to do so.
