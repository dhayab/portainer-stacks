.PHONY: validate
.SILENT: validate

validate:
	docker-compose $$(ls *.yml | sed -e 's/^/-f /') config -q
