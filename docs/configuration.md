# Configuration System

The framework uses a YAML-based configuration system with automatic variable mapping and environment variable overrides.

## Complete Configuration Reference

Below is a complete configuration file with all available options and their default values:

```yaml
# config/config.yaml - Complete Configuration Reference
radp:
  # Active environment (determines which config-{env}.yaml to load)
  env: default

  # Framework settings
  fw:
    # Banner display mode
    # - on: Show banner on startup
    # - off: No banner
    # - log: Log banner instead of displaying
    banner-mode: on

    # Logging configuration
    log:
      # Enable debug level logging
      debug: false

      # Minimum log level: debug, info, warn, error
      level: info

      # Console output settings
      console:
        enabled: true

      # File output settings
      file:
        enabled: true
        # Log file path (supports variable expansion)
        name: $HOME/logs/radp/radp_bash.log

      # Log file rolling policy
      rolling-policy:
        enabled: true
        # Number of days to keep log files
        max-history: 7
        # Maximum total size of all log files
        total-size-cap: 5GB
        # Maximum size per log file
        max-file-size: 10MB

      # Log format patterns
      # Supported placeholders:
      #   %d - Date/time
      #   %p - Log level
      #   %P - Process ID (PID)
      #   %t - Thread/script name
      #   %F - Filename
      #   %M - Function name
      #   %L - Line number
      #   %m - Message
      #   %n - Newline
      #
      # Color syntax (console only):
      #   %clr(text){color} - Apply specified color to text
      #   %clr(text) - Apply log-level color to text
      #
      # Color names: black, red, green, yellow, blue, magenta, cyan, white, faint, default
      # ANSI codes: 30-37 (normal), 90-97 (bright)
      pattern:
        console: "%clr(%d){faint} %clr(|){faint} %clr(%p) %clr(%P) %clr(|){faint} %clr(%t){cyan} %clr(|){faint} %clr(%L:%F#%M){cyan} %clr(|){faint} %m"
        file: "%d | %p %P | %t | %L:%F#%M | %m"

      # Log level colors (for %clr(text) without color parameter)
      color:
        debug: faint      # Gray
        info: green       # Green
        warn: yellow      # Yellow
        error: red        # Red

    # User configuration settings
    user:
      config:
        # Auto-map radp.extend.* to shell variables
        automap: true
      lib:
        # Custom library path (default: ${gr_fw_root_path}/../lib)
        path: ${gr_fw_root_path}/../lib

  # Application-specific settings
  # All keys under extend.* are auto-mapped to gr_radp_extend_* variables
  extend:
    myapp:
      version: v1.0.0
      api:
        url: https://api.example.com
        timeout: 30
      database:
        host: localhost
        port: 5432
        name: myapp_db
      features:
        cache_enabled: true
        max_retries: 3
```

## Configuration Files

Configuration files are loaded from `src/main/shell/config/`:

```
config/
├── config.yaml           # Base configuration
├── config-dev.yaml       # Development overrides
├── config-staging.yaml   # Staging overrides
└── config-prod.yaml      # Production overrides
```

## Variable Mapping

YAML keys are automatically converted to shell variables:

| YAML Path                       | Shell Variable                     |
|---------------------------------|------------------------------------|
| `radp.env`                      | `gr_radp_env`                      |
| `radp.fw.log.debug`             | `gr_radp_fw_log_debug`             |
| `radp.fw.banner-mode`           | `gr_radp_fw_banner_mode`           |
| `radp.extend.myapp.api.url`     | `gr_radp_extend_myapp_api_url`     |
| `radp.extend.myapp.api.timeout` | `gr_radp_extend_myapp_api_timeout` |

Access in code:

```bash
echo "$gr_radp_extend_myapp_api_url" # https://api.example.com
echo "$gr_radp_extend_myapp_api_timeout" # 30
```

## Environment Overrides

Override any configuration via environment variables using `GX_` prefix:

```bash
# Override radp.fw.log.debug
GX_RADP_FW_LOG_DEBUG=true myapp hello

# Override radp.extend.myapp.api.url
GX_RADP_EXTEND_MYAPP_API_URL=http://localhost:8080 myapp hello

# Override radp.fw.banner-mode
GX_RADP_FW_BANNER_MODE=off myapp hello

```

Mapping rules:

- Prefix: `GX_`
- Dots → underscores
- Hyphens → underscores
- Uppercase

| YAML Path                   | Environment Variable           |
|-----------------------------|--------------------------------|
| `radp.fw.log.debug`         | `GX_RADP_FW_LOG_DEBUG`         |
| `radp.fw.banner-mode`       | `GX_RADP_FW_BANNER_MODE`       |
| `radp.extend.myapp.api.url` | `GX_RADP_EXTEND_MYAPP_API_URL` |

## Environment-Specific Config

Set `radp.env` to load environment-specific config:

```yaml
# config/config.yaml
radp:
  env: dev    # Load config-dev.yaml
```

Or via environment:

```bash
GX_RADP_ENV=prod myapp hello # Loads config-prod.yaml
```

Example environment override file:

```yaml
# config/config-prod.yaml
radp:
  fw:
    banner-mode: off
    log:
      debug: false
      level: warn
      file:
        enabled: true
        name: /var/log/myapp/myapp.log

  extend:
    myapp:
      api:
        url: https://api.production.example.com
        timeout: 60
      database:
        host: db.production.example.com
        port: 5432
        name: myapp_production
```

## Configuration Priority

1. **Framework defaults** (`framework_config.yaml`)
2. **Base config** (`config/config.yaml`)
3. **Environment config** (`config/config-{env}.yaml`)
4. **Environment variables** (`GX_*`)

Later sources override earlier ones.

## Framework Settings Reference

### Banner Mode

| Value | Description                      |
|-------|----------------------------------|
| `on`  | Show banner on startup           |
| `off` | No banner                        |
| `log` | Log banner instead of displaying |

### Log Levels

| Level   | Description                    |
|---------|--------------------------------|
| `debug` | Detailed debugging information |
| `info`  | General information messages   |
| `warn`  | Warning messages               |
| `error` | Error messages only            |

### Log Pattern Placeholders

| Placeholder | Description                          |
|-------------|--------------------------------------|
| `%d`        | Date and time                        |
| `%p`        | Log level (DEBUG, INFO, WARN, ERROR) |
| `%P`        | Process ID (PID)                     |
| `%t`        | Thread/script name                   |
| `%F`        | Source filename                      |
| `%M`        | Function name                        |
| `%L`        | Line number                          |
| `%m`        | Log message                          |
| `%n`        | Newline                              |

### Color Names

| Name      | Description      |
|-----------|------------------|
| `black`   | Black            |
| `red`     | Red              |
| `green`   | Green            |
| `yellow`  | Yellow           |
| `blue`    | Blue             |
| `magenta` | Magenta          |
| `cyan`    | Cyan             |
| `white`   | White            |
| `faint`   | Gray (dim)       |
| `default` | Terminal default |

## Best Practices

1. **Keep secrets out of config files** - Use environment variables for API keys, passwords

2. **Use environment-specific configs** - Don't put production URLs in base config

3. **Document your extensions** - Comment what each `radp.extend.*` setting does

4. **Validate required config** - Check for required values at startup

```bash
if [[ -z "${gr_radp_extend_myapp_api_url:-}" ]]; then
  radp_log_error "Missing required config: radp.extend.myapp.api.url"
  exit 1
fi
```

5. **Use sensible defaults** - Define defaults in base config, override in environment configs

```yaml
# config/config.yaml - defaults
radp:
  extend:
    myapp:
      api:
        timeout: 30  # sensible default

# config/config-prod.yaml - production override
radp:
  extend:
    myapp:
      api:
        timeout: 60  # longer timeout for production
```
