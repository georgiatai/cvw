// void fir(int x[], int c[], int y[], int n, int m)
// a0: base adr of x; a1: base adr of c; a2: base adr of y
// a3: n, a4: m

.global fir

fir:
# ending adr of j loop
sub  t0, a3, a4   # t0 = n-m
addi t0, t0, 1    # t0 = n-m+1
slli t0, t0, 2
add  t0, a2, t0   # t0 = &y[n-m+1]

# ending adr of i loop
slli t1, a4, 2
add  t1, a4, t1   # &c[m]


addi t2, a4, -1   # t2 = m-1
slli t2, t2, 2    
add  t2, a0, t2   # &x[m-1]

forj:
bge t2, t0, donej
li t3, 0          # sum = 0

li t4, 0


fir:
    li  t0, 0              # t0 = j = 0
    bge t0, a3, donej      # if j >= n, finish

jloop:
    li t1, 0               # t1 = i = 0
    li t2, 0               # t2 = sum = 0

iloop:
    bge t1, a4, donei      # if i >= m, finish

    # Load x[j-i+(m-1)] into t3
    sub  t3, t0, t1        # t3 = j-i
    addi t4, a4, -1         # t4 = m-1
    add  t3, t3, t4        # t3 = j-i + (m-1)
    slli t3, t3, 2  
    add  t3, t3, a0        # address of x[j-i+(m-1)]
    lw   t3, 0(t3) 

    # Load c[i] into t4
    slli t2, t2, 2
    add  t4, a1, t1        # address of c[i]
    lw   t4, 0(t4)

    # mul_q31
    mul  t5, t3, t4        # int * int -> long
    srai t5, t5, 31        # shift right by 31 bit
    addw t2, t2, t5

    addi t1, t1, 1         # i++
    j iloop

donei:
    # Store sum into y[j]
    slli t0, t0, 2
    add  t6, t0, a2        # get address of y[j]
    sw   t2, 0(t6)         # store sum in y[j]

    addi t0, t0, 1         # j++
    j iloop

donej:
    ret