# Build Release Checklist

## CRITICAL: Native binaries are ALREADY built!

The native binaries (ss-local, privoxy, plugins) are **already present** in the repository!
They were downloaded from the original repositories and are stored in:
- `ShadowsocksX-NG/ss-local/`
- `ShadowsocksX-NG/privoxy/`
- `ShadowsocksX-NG/v2ray-plugin/`
- etc.

**DO NOT run `make -C deps`** - it will fail and is not necessary!
The binaries are already there and ready to use.

## Correct Build Process

1. **Build the release:**
   ```bash
   make VERSION=x.y.z release
   ```

2. **Create DMG:**
   ```bash
   make release-dmg
   ```

That's it! No need to build deps.

## Project Renaming (as of v0.7.0)

The project has been rebranded from ShadowsocksX-NG to **ProxyForge**.

- Bundle identifier: `com.doubleniki.ProxyForge`
- Product name: ProxyForge
- **DMG filename should be: `ProxyForge.dmg`** (not ShadowsocksX-NG.dmg)
- Need to update Makefile to use ProxyForge name for DMG

## Common Mistakes to Avoid

- ❌ DO NOT run `make -C deps` - binaries already exist
- ❌ DO NOT use old ShadowsocksX-NG name for DMG in new releases
- ✅ Binaries are pre-built and included in the repo
- ✅ Use ProxyForge name for all release artifacts
