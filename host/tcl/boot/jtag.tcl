connect
tar -set -filter {name =~ "Versal *"}

# Switch boot mode
mwr 0xf1260200 0x0100
mrd 0xf1260200

# Set MULTIBOOT address to 0
mwr -force 0xF1110004 0x0

# Perform reset
tar -set -filter {name =~ "PMC"}
rst
