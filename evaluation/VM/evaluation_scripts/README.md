Script for test schedule.

Before you run this script make sure you entered the correct the ip address of the 
Server where MongoDB is installed and set the value for dockered version or not.
Default port for MongoDB is 27017

Example document structure in $HOME/ycsb_tests directory
This structure will be generated automaticly.
Test results will be stored in the dependent directory for each test case.
Timestamp is YEAR-MONTH-DAY-HOUR-MINUTE
.
├── 16_threads
│   └── 201704241509
├── 1_threads
│   └── 201704241509
├── 2_threads
│   └── 201704241509
├── 32_threads
│   └── 201704241509
├── 4_threads
│   └── 201704241509
└── 8_threads
    └── 201704241509