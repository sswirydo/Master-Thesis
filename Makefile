
DB_NAME=mobility-test
SQL_FILE=Master-Thesis/scripts/test.sql
DB_USER=postgres

all:

psql:
	sudo service postgresql restart

init:
	mkdir build
	cd build && cmake .. && make && sudo make install && sudo service postgresql restart

reinit:
	rm -rR build --force
	mkdir build
	cd build && cmake .. && make && sudo make install && sudo service postgresql restart

compile:
	cd build && make && sudo make install && sudo service postgresql restart

test:
	dropdb -U $(DB_USER) --if-exists $(DB_NAME) 
	createdb -U $(DB_USER) $(DB_NAME)
	psql -U $(DB_USER) -d $(DB_NAME) -f "Master-Thesis/scripts/test.sql"  # > output.log 2>&1

debug:
	sudo gdb -p $(PID) # e.g. `make debug PID=3205`