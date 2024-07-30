.PHONY: build
.SILENT: build validate

build:
	HEADER=$$(head -n 2 docker-compose.yml); \
	SERVICES=$$(find services -type f -name '*.yml' -exec echo "  - {}" \;); \
	echo "$$HEADER\n$$SERVICES" > docker-compose.yml

validate: build
	docker-compose config -q
