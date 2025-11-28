VERSION ?= 0.0.0
APP_NAME = ProxyForge

.PHONY: all
all: debug

.PHONY: debug
debug: set-version
	xcodebuild -workspace ShadowsocksX-NG.xcworkspace -scheme ShadowsocksX-NG -configuration Debug SYMROOT=$${PWD}/build

.PHONY: release
release: set-version
	xcodebuild -workspace ShadowsocksX-NG.xcworkspace -scheme ShadowsocksX-NG -configuration Release SYMROOT=$${PWD}/build

.PHONY: debug-dmg release-dmg
debug-dmg release-dmg: TARGET = $(subst -dmg,,$@)
debug-dmg release-dmg:
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
