SHELL := /bin/bash

# Use `godot` from PATH when available, with a macOS app-install fallback.
GODOT ?= $(shell \
	if command -v godot >/dev/null 2>&1; then \
		command -v godot; \
	elif [ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]; then \
		printf '%s\n' "/Applications/Godot.app/Contents/MacOS/Godot"; \
	else \
		printf '%s\n' "godot"; \
	fi)

WEB_EXPORT_PRESET ?= Web
WEB_BUILD_DIR ?= build/web
WEB_ENTRYPOINT := $(WEB_BUILD_DIR)/index.html
NGINX_IMAGE ?= nginx:alpine
WEB_PORT ?= 8080
WEB_CONTAINER_NAME ?= chroma-sort-web

.PHONY: web-export webdeploy-local

web-export:
	mkdir -p "$(WEB_BUILD_DIR)"
	"$(GODOT)" --headless --path . --export-release "$(WEB_EXPORT_PRESET)" "$(WEB_ENTRYPOINT)"

webdeploy-local: web-export
	docker run --rm --name "$(WEB_CONTAINER_NAME)" \
		-p "$(WEB_PORT):80" \
		--mount type=bind,src="$(CURDIR)/$(WEB_BUILD_DIR)",dst=/usr/share/nginx/html,readonly \
		"$(NGINX_IMAGE)"
