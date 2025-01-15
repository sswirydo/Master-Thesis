# Master-Thesis

Support repository for my Master Thesis in MobilityDB.

- *doc/* contains the corresponding master's thesis document as well as the corresponding thesis defence slides
- *code/* contains the periodic extension of MobilityDB as further explained below
- *scripts/* contains various queries and support code
- *datasets/* contains GTFS files used as basis for queries and doc
  
## Code

Although we have provided the implemented code files in the *code/* directory, we recommend using the implementation on [sswirydo/MobilityDB-P/develop-periodic](https://github.com/sswirydo/MobilityDB-P/tree/develop-periodic), where these files are directly integrated within MobilityDB and compiled as illustrated in *scripts/Makefile/reinit*.
  
### Implementation notes

- Not production ready.
- Code is split into Temporal and Periodic, and should be merged into a single Temporal data structure if future development is pursued. This split allowed us to test and implement without worrying about parallel changes made to the upstream MobilityDB extension.
- Temporal and Periodic only differ by additional Input/Output methods which can be merged. Additional functions are independent of the data structure implementation.
- Currently only `pint` and periodic `pgeompoint` are supported; the support for other subtypes will be immediate after the merge.
- Meanwhile, Temporal and Periodic can be interchangeably casted using `(Temporal *)` and `(Periodic *)`in C, or using `::tgeompoint` and `::pgeompoint` in SQL, depending on the wanted functions and output format.
