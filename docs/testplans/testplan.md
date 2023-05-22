# CORE-V Wally Design Verification Test Plan

CORE-V Wally is functionally tested in the following ways.  Each test is run in lock-step against ImperasDV to ensure all architectural state is correct after each instruction.

| Functions      | Coverage Method | Status |
| ----------- | ----------- |----|
|  Instructions | riscv-arch-test | Pass   |
| Privileged Unit   | wally-riscv-arch-test        | Pass   |
| Virtual Memory | wally-riscv-arch-test | Pass |
| PMP | wally-riscv-arch-test | Pass
| Peripherals | wally-riscv-arch-test | Pass |
| Floating-Point | TestFloat | Pass |
| General | Code Coverage | 91% |
| General | Boot Linux in Sim | Pass | 
| General | Boot Linux on FPGA | Pass |


The following performance validation is also run:
| Function | Method | Status |
| --- | --- | --- |
| Overall Performance | embench | Pass|
| Overall Performance | coremark | Pass |
| Branch Predictor | *** | Pass |
| Cache Miss Rate | *** | Pass |



* Run [RISC-V Architecture Compatibility Tests](https://github.com/riscv-non-isa/riscv-arch-test) in lock-step against the ImperasDV reference model.
* Run custom tests to cover virtual memory, PMP, privileged unit, and peripherals in lock step against ImperasDV.
* ***pending: Run random tests generated by risc-dv
* Run CoreMark and Embench benchmarks.
* Run performance validation against reference models for the branch predictor and caches.
* Run the TestFloat suite against all precisions of all operations for the FPU unit.
* *** 83.5% coverage of statements, branches, expressions, and FSM states and transitions
* Boot Buildroot Linux in lock-step against ImperasDV.
* Boot Buildroot Linux on an FPGA and run programs.

# Running Tests

# 

# Detailed Test Plans

The test plans for specific units are lined below:

* Privileged Unit
* Memory Management Unit
* Peripherals
* Branch Predictor Performance Validation
* Cache Performance Validation

Wally is described in an upcoming textbook, *RISC-V System-on-Chip Design*, by Harris, Stine, Thompson, and Harris.  