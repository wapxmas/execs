# execs
Tool to run stack exec prj-exe more easy

## Usage
```
> execs
```
Finds in .cabal file first executable project and run it with `stack exec`

```
> execs -r
```
First run `stack clean` and `stack build` if commands are lucky then runs as above written.
