VERSION ?= 0.0.0
APP_NAME = ProxyForge

# Required binaries with minimum sizes (bytes)
BINARIES = ss-local:1000000 privoxy:1000000 v2ray-plugin:1000000 obfs-local:100000 client:1000000

.PHONY: all
all: debug

.PHONY: debug
debug: set-version
	xcodebuild -workspace ShadowsocksX-NG.xcworkspace -scheme ShadowsocksX-NG -configuration Debug SYMROOT=$${PWD}/build

.PHONY: release
release: set-version
	xcodebuild -workspace ShadowsocksX-NG.xcworkspace -scheme ShadowsocksX-NG -configuration Release SYMROOT=$${PWD}/build

.PHONY: verify-binaries
verify-binaries:
	@echo "Verifying binaries..."
	@for spec in $(BINARIES); do \
		name=$${spec%%:*}; \
		min_size=$${spec##*:}; \
		file=$$(find build -name "$$name" -type f 2>/dev/null | head -1); \
		if [ -z "$$file" ]; then \
			echo "ERROR: $$name not found in build"; exit 1; \
		fi; \
		size=$$(stat -f%z "$$file" 2>/dev/null || stat -c%s "$$file" 2>/dev/null); \
		if [ "$$size" -lt "$$min_size" ]; then \
			echo "ERROR: $$name is too small ($$size bytes, min $$min_size). Binary may be a placeholder!"; exit 1; \
		fi; \
		echo "OK: $$name ($$size bytes)"; \
	done
	@echo "All binaries verified."

.PHONY: debug-dmg release-dmg
debug-dmg release-dmg: TARGET = $(subst -dmg,,$@)
debug-dmg release-dmg: verify-binaries
	t="$(TARGET)" && t="`tr '[:lower:]' '[:upper:]' <<< $${t:0:1}`$${t:1}" \
	  && rm -rf build/$${t}/$(APP_NAME)/ \
	  && mkdir build/$${t}/$(APP_NAME) \
	  && cp -r build/$${t}/ShadowsocksX-NG.app build/$${t}/$(APP_NAME)/$(APP_NAME).app \
	  && ln -s /Applications build/$${t}/$(APP_NAME)/Applications \
	  && hdiutil create build/$${t}/$(APP_NAME).dmg -ov -volname "$(APP_NAME)" -fs HFS+ -srcfolder build/$${t}/$(APP_NAME)/ \
	  && rm -rf build/$${t}/$(APP_NAME)/

.PHONY: set-version
set-version:
	agvtool new-marketing-version $(VERSION)

.PHONY: clean
clean:
	rm -rf build/
