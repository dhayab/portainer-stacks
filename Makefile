.PHONY: build
.SILENT: build validate

build:
	HEADER="$$(printf '# Use `make build` to generate and update this file\ninclude:')"; \
	DEFAULT_TMP=$$(mktemp /tmp/compose-default.XXXXXX); \
	TARGET_DIR=$$(mktemp -d /tmp/compose-targets.XXXXXX); \
	GENERATED="docker-compose.yml"; \
	cleanup() { rm -f "$$DEFAULT_TMP"; rm -rf "$$TARGET_DIR"; }; \
	trap cleanup EXIT; \
	for file in $$(find services -type f -name '*.yml' | sort); do \
		targets=$$(sed -n 's/^ *x-target *: *//p' "$$file"); \
		if [ -n "$$targets" ]; then \
			for target in $$targets; do \
				tmp="$$TARGET_DIR/$$target"; \
				[ -f "$$tmp" ] || : > "$$tmp"; \
				echo "  - $$file" >> "$$tmp"; \
			done; \
		else \
			echo "  - $$file" >> "$$DEFAULT_TMP"; \
		fi; \
	done; \
	printf "%s\n" "$$HEADER" > docker-compose.yml; \
	cat "$$DEFAULT_TMP" >> docker-compose.yml; \
	for tmpfile in "$$TARGET_DIR"/*; do \
		[ -e "$$tmpfile" ] || continue; \
		target=$${tmpfile##*/}; \
		out="docker-compose-$$target.yml"; \
		printf "%s\n" "$$HEADER" > "$$out"; \
		cat "$$tmpfile" >> "$$out"; \
		GENERATED="$$GENERATED $$out"; \
	done; \
	for existing in docker-compose-*.yml; do \
		for keep in $$GENERATED; do \
			[ "$$existing" = "$$keep" ] && continue 2; \
		done; \
		rm -f "$$existing"; \
	done

validate: build
	set -e; \
	for file in docker-compose*.yml; do \
		[ -e "$$file" ] || continue; \
		echo "Validating $$file"; \
		docker-compose -f "$$file" config -q; \
	done
