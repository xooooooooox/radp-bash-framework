# Configuration System

The framework uses a YAML-based configuration system with automatic variable mapping and environment variable overrides.

## Configuration Files

Configuration files are loaded from `src/main/shell/config/`:

```
config/
├── config.yaml           # Base configuration
├── config-dev.yaml       # Development overrides
├── config-staging.yaml   # Staging overrides
└── config-prod.yaml      # Production overrides
```

## Configuration Structure

```yaml
# config/config.yaml
radp:
  env: default              # Active environment

  fw:                       # Framework settings
    banner-mode: on         # on, off, log
    log:
      debug: false          # Enable debug logging
      level: info           # Log level
      console:
        enabled: true       # Log to console
      file:
        enabled: false      # Log to file
    user:
      config:
        automap: true       # Auto-map user config to variables

  extend:                   # Application-specific settings
    myapp:
      version: v1.0.0
      api_url: https://api.example.com
      timeout: 30
```

## Variable Mapping

YAML keys are automatically converted to shell variables:

| YAML Path | Shell Variable |
|-----------|----------------|
| `radp.env` | `gr_radp_env` |
| `radp.fw.log.debug` | `gr_radp_fw_log_debug` |
| `radp.extend.myapp.api_url` | `gr_radp_extend_myapp_api_url` |

Access in code:

```bash
echo "$gr_radp_extend_myapp_api_url"  # https://api.example.com
echo "$gr_radp_extend_myapp_timeout"  # 30
```

## Environment Overrides

Override any configuration via environment variables using `GX_` prefix:

```bash
# Override radp.fw.log.debug
GX_RADP_FW_LOG_DEBUG=true myapp hello

# Override radp.extend.myapp.api_url
GX_RADP_EXTEND_MYAPP_API_URL=http://localhost:8080 myapp hello
```

Mapping rules:
- Prefix: `GX_`
- Dots → underscores
- Hyphens → underscores
- Uppercase

| YAML Path | Environment Variable |
|-----------|---------------------|
| `radp.fw.log.debug` | `GX_RADP_FW_LOG_DEBUG` |
| `radp.fw.banner-mode` | `GX_RADP_FW_BANNER_MODE` |

## Environment-Specific Config

Set `radp.env` to load environment-specific config:

```yaml
# config/config.yaml
radp:
  env: dev    # Load config-dev.yaml
```

Or via environment:

```bash
GX_RADP_ENV=prod myapp hello  # Loads config-prod.yaml
```

## Configuration Priority

1. **Framework defaults** (`framework_config.yaml`)
2. **Base config** (`config/config.yaml`)
3. **Environment config** (`config/config-{env}.yaml`)
4. **Environment variables** (`GX_*`)

Later sources override earlier ones.

## Framework Settings

### Banner Mode

```yaml
radp:
  fw:
    banner-mode: on    # on, off, log
```

- `on` - Show banner on startup
- `off` - No banner
- `log` - Log banner instead of displaying

### Logging

```yaml
radp:
  fw:
    log:
      debug: false        # Enable debug level
      level: info         # Minimum level: debug, info, warn, error
      console:
        enabled: true     # Output to console
      file:
        enabled: false    # Output to file
        path: /var/log/myapp.log
```

Enable debug logging:

```bash
GX_RADP_FW_LOG_DEBUG=true myapp hello
```

## Best Practices

1. **Keep secrets out of config files** - Use environment variables for API keys, passwords
2. **Use environment-specific configs** - Don't put production URLs in base config
3. **Document your extensions** - Comment what each `radp.extend.*` setting does
4. **Validate required config** - Check for required values at startup

```bash
if [[ -z "${gr_radp_extend_myapp_api_url:-}" ]]; then
  radp_log_error "Missing required config: radp.extend.myapp.api_url"
  exit 1
fi
```
