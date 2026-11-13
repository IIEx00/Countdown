# Countdown screen saver
#
#   make            build the saver into build/Build/Products/Release/Countdown.saver
#   make install    build and copy it to ~/Library/Screen Savers
#   make preview    build and launch the Preview app
#   make uninstall  remove the installed saver
#   make clean      remove build output

SCHEME      := Countdown
PREVIEW     := Preview
CONFIG      := Release
BUILD_DIR   := build
PRODUCT     := $(BUILD_DIR)/Build/Products/$(CONFIG)/Countdown.saver
SAVER_DIR   := $(HOME)/Library/Screen Savers

# Prefer a full Xcode install even when xcode-select points at the
# Command Line Tools, which cannot build app bundles.
ifneq ($(wildcard /Applications/Xcode.app/Contents/Developer),)
export DEVELOPER_DIR := /Applications/Xcode.app/Contents/Developer
endif

.PHONY: all build install preview uninstall clean

all: build

build:
	xcodebuild -project Countdown.xcodeproj -scheme $(SCHEME) \
		-configuration $(CONFIG) -derivedDataPath $(BUILD_DIR) build

install: build
	@mkdir -p "$(SAVER_DIR)"
	@rm -rf "$(SAVER_DIR)/Countdown.saver"
	cp -R "$(PRODUCT)" "$(SAVER_DIR)/"
	@xattr -dr com.apple.quarantine "$(SAVER_DIR)/Countdown.saver" 2>/dev/null || true
	@codesign --verify --deep "$(SAVER_DIR)/Countdown.saver" \
		&& echo "Installed $(SAVER_DIR)/Countdown.saver"
	@echo "Restarting the screen saver host..."
	@killall legacyScreenSaver 2>/dev/null || true
	@echo
	@echo "Quit System Settings with Cmd-Q and reopen it,"
	@echo "then choose Wallpaper -> Screen Saver -> Countdown -> Options."

preview:
	xcodebuild -project Countdown.xcodeproj -scheme $(PREVIEW) \
		-configuration Debug -derivedDataPath $(BUILD_DIR) build
	open "$(BUILD_DIR)/Build/Products/Debug/$(PREVIEW).app"

uninstall:
	@rm -rf "$(SAVER_DIR)/Countdown.saver"
	@echo "Removed $(SAVER_DIR)/Countdown.saver"

clean:
	rm -rf "$(BUILD_DIR)"
