# ✨ TwinklePub ✨

TwinklePub is a friendly [Micropub](https://indieweb.org/Micropub) server written in [Gleam](https://gleam.run), enabling you to publish content to your personal website using standardized [IndieWeb](https://indieweb.org) protocols.

## Installation

### Prequisites
- Gleam (Tested on v1.11)
- Erlang/OTP (Tested on v28)

### Quick Start

This application requires some environment variables to be configured, see below for details.

Start by cloning this repository.

```sh
cd twinkle_pub

# Install dependencies
gleam deps download

# Configure environment variables
cp .example.env .env # Edit these variables according to your requirements

# Build and run
gleam run
```

## Configuration

The following environment variables should be configured before running the server.

### Required

TOKEN_ENDPOINT: The URL of your IndieAuth token endpoint (e.g., https://tokens.indieauth.com/token)
ME: The URL of your personal website

### Optional

MEDIA_ENDPOINT: The URL of the media endpoint Micropub clients should use
SYNDICATE_TO: A JSON array of syndication targets
LOG_LEVEL: Logging verbosity level - defaults to `INFO`. Supports: `DEBUG`, `INFO`, `WARN`, `ERROR`, `CRITICAL`



