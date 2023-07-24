
DB_NAME=mobility-test
SQL_FILE=Master-Thesis/scripts/tochar.sql
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
	dropdb -U $(DB_USER) --if-exists $(DB_NAME) 
	createdb -U $(DB_USER) $(DB_NAME)
	psql -U $(DB_USER) -d $(DB_NAME) -f $(SQL_FILE)  # > output.log 2>&1


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

clean:
	rm -rR build --force