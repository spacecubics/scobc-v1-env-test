# Environment test script for SC-OBC Module V1

## RPU

### Build

```shell
$ west build -p always -b scobc_v1 scobc-v1-env-test/rpu
```

### Start test

```shell
uart:~$ test start
```

### Stop test

```shell
uart:~$ test stop
```

### Start APU

```shell
uart:~$ apu start
```

### Stop APU

```shell
uart:~$ apu stop
```

## APU

### Requiresments

- ```stress-ng```
- ```taskset```
- ```libgpiod```

### APU only

```shell
# ./test-apu.sh
```

### APU + FPGA

```shell
# ./test-apu-fpga.sh
```

## Host PC

### Requiresments

- ``tio``

### Logging

```shell
# ./log1.sh apu
```

```shell
# ./log2.sh rpu
```
