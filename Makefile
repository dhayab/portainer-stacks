.PHONY: build validate fmt
.SILENT: build validate fmt

build:
	HEADER="$$(printf '# Use `make build` to generate and update this file\ninclude:')"; \
	TARGETS=$$(find services -type f -name '*.yml' | sort | xargs grep -h 'x-target' 2>/dev/null | sed 's/.*x-target *: *//' | sort -u); \
	GENERATED="docker-compose.yml"; \
	for target in $$TARGETS; do \
		out="docker-compose-$$target.yml"; \
		{ printf '%s\n' "$$HEADER"; grep -rl "x-target: $$target" services/ | sort | sed 's/^/  - /'; } > "$$out"; \
		GENERATED="$$GENERATED $$out"; \
	done; \
	{ printf '%s\n' "$$HEADER"; find services -type f -name '*.yml' | sort | xargs grep -rL 'x-target' | sort | sed 's/^/  - /'; } > docker-compose.yml; \
	for existing in docker-compose-*.yml; do \
		[ -e "$$existing" ] || continue; \
		for keep in $$GENERATED; do \
			[ "$$existing" = "$$keep" ] && continue 2; \
		done; \
		rm -f "$$existing"; \
	done

fmt:
	find services -type f -name '*.yml' | xargs -I{} yq -i '.' {}

validate: fmt build
	set -e; \
	for file in docker-compose*.yml; do \
		[ -e "$$file" ] || continue; \
		echo "Validating $$file"; \
		docker compose -f "$$file" config -q; \
	done
