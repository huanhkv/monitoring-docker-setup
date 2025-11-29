.PHONY: run clean deep-clean

run:
	docker-compose up

clean:
	docker-compose down

deep-clean:
	docker-compose down --volumes
