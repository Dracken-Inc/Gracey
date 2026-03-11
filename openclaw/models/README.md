# Models Directory

Place local model files here, one subdirectory per model.

---

## Expected Layout

```
models/
├── README.md           ← this file
├── default/            ← symlink or copy of the currently active model
│   ├── config.json
│   ├── tokenizer.json
│   ├── tokenizer_config.json
│   ├── special_tokens_map.json
│   └── model-*.safetensors   (or pytorch_model-*.bin)
├── llama-3-70b/        ← example: Meta Llama 3 70B
│   └── …
└── mistral-7b/         ← example: Mistral 7B Instruct
    └── …
```

Point `openclaw_config.yaml → model.path` at the relevant subdirectory.

---

## Supported Formats

| Format | Extension | Notes |
|--------|-----------|-------|
| SafeTensors | `.safetensors` | Preferred — faster loading, safe deserialization |
| PyTorch | `.bin` | Legacy format; works but slower to load |
| GGUF | `.gguf` | For llama.cpp-style backends (future support) |

---

## Downloading Models

### From HuggingFace Hub

```bash
pip install huggingface_hub

# Download to /opt/gracey/models/llama-3-70b/
huggingface-cli download meta-llama/Meta-Llama-3-70B \
    --local-dir /opt/gracey/models/llama-3-70b \
    --local-dir-use-symlinks False
```

You may need to accept the model's license on huggingface.co first, then
authenticate with `huggingface-cli login`.

### Symlink the Active Model

```bash
ln -sfn /opt/gracey/models/llama-3-70b /opt/gracey/models/default
```

---

## Storage Recommendations

- Use the NVMe drive for all model files.  
- Keep at least 20 GB free on the model volume at all times.
- Models in SafeTensors format load noticeably faster than `.bin` files.

---

## File Exclusions

Model weight files are excluded from git via the root `.gitignore`:

```
openclaw/models/**/*.safetensors
openclaw/models/**/*.bin
openclaw/models/**/*.gguf
openclaw/models/**/*.pt
```

Only this `README.md` and small metadata files (e.g. `config.json`) should be
committed to version control.
