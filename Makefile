
DB_NAME_GTFS=mobility-test
DB_NAME_QUERY=mobility-query
SQL_FILE=Master-Thesis/scripts/query.sql
GTFS_FILE=Master-Thesis/scripts/gtfs.sql
CLASSIC_GTFS_FILE=Master-Thesis/scripts/classic_gtfs.sql
NORESET_FILE=Master-Thesis/scripts/noreset_query.sql
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

reinit-meos:
	rm -rR build --force
	mkdir build
	cd build && cmake -DMEOS=on .. && make && sudo make install && sudo service postgresql restart

compile:
	cd build && make && sudo make install && sudo service postgresql restart

query:
	dropdb -U $(DB_USER) --if-exists $(DB_NAME_QUERY) 
	createdb -U $(DB_USER) $(DB_NAME_QUERY)
	psql -U $(DB_USER) -d $(DB_NAME_QUERY) -f $(SQL_FILE)  # > output.log 2>&1

query-clean:
	dropdb -U $(DB_USER) --if-exists $(DB_NAME_QUERY) 
	createdb -U $(DB_USER) $(DB_NAME_QUERY)
	psql -U $(DB_USER) -d $(DB_NAME_QUERY) -c '\x' -f $(SQL_FILE) -A -t -P pager=off 

# gtfs:
# 	dropdb -U $(DB_USER) --if-exists $(DB_NAME_GTFS) 
# 	createdb -U $(DB_USER) $(DB_NAME_GTFS)
# 	# psql -U $(DB_USER) -d $(DB_NAME_GTFS) -c '\x' -f $(GTFS_FILE) -A -t -P pager=off 
# 	psql -U $(DB_USER) -d $(DB_NAME_GTFS) -f $(GTFS_FILE)

# gtfs-clean:
# 	dropdb -U $(DB_USER) --if-exists $(DB_NAME_GTFS) 
# 	createdb -U $(DB_USER) $(DB_NAME_GTFS)
# 	psql -U $(DB_USER) -d $(DB_NAME_GTFS) -c '\x' -f $(GTFS_FILE) -A -t -P pager=off 

no-reset-gtfs:
	psql -U $(DB_USER) -d $(DB_NAME_GTFS) -c '\x' -f $(NORESET_FILE) -A -t -P pager=off

no-reset-gtfs-out:
	psql -U $(DB_USER) -d $(DB_NAME_GTFS) -f $(NORESET_FILE) -o output-gtfs.log 2>&1

example:
	cd meos/examples/ && gcc -Wall -g -I/usr/local/include -o 01_meos_hello_world 01_meos_hello_world.c -L/usr/local/lib -lmeos && ./01_meos_hello_world

sandbox:
	cd meos/examples/ && gcc -Wall -g -I/usr/local/include -o sandbox sandbox.c -L/usr/local/lib -lmeos && ./sandbox

sandbox-val:
	cd meos/examples/ && gcc -Wall -g -I/usr/local/include -o sandbox sandbox.c -L/usr/local/lib -lmeos &&  valgrind --leak-check=yes ./sandbox

sandbox-gdb:	
	cd meos/examples/ && gcc -Wall -g -I/usr/local/include -o sandbox sandbox.c -L/usr/local/lib -lmeos &&  gdb ./sandbox

test:
	# ctest -N        # list all tests
	cd build && ctest # run all tests
	# ctest -R regex  # run all tests whose name match regex

test-22:
	cd build && ctest -R 022

debug:
	sudo gdb -p $(PID) # e.g. `make debug PID=3205`

devdoc: #useless
	mkdir build
	cd build && cmake -DMEOS=on -DDOC_DEV=on .. && make -j && make doc_dev

diff: # lists changes made by a merge (helpfull for debugging)
	git diff $(shell git rev-parse HEAD)~ $(shell git rev-parse HEAD) > merge_diff.txt

clean:
	rm -rR build --force