with open("V08\\U20_324-0059-015_G.BIN", "rb") as binary_file:
    # Read the whole file at once
    v08_u20 = binary_file.read()

with open("V08\\U21_324-0059-016_G.BIN", "rb") as binary_file:
    # Read the whole file at once
    v08_u21 = binary_file.read()

with open("V14\\V14_U19.bin", "rb") as binary_file:
    # Read the whole file at once
    v14_u19 = binary_file.read()

with open("V14\\V14_U20.bin", "rb") as binary_file:
    # Read the whole file at once
    v14_u20 = binary_file.read()

print(len(v08_u20))
print(len(v08_u21))

print(len(v14_u19))
print(len(v14_u20))

with open("V26\\324-0059-059_U19_27C512_CKS.0x0047-8E8E.BIN", "rb") as binary_file:
    # Read the whole file at once
    v26_u19 = binary_file.read()

with open("V26\\324-0059-060_U20_27C512_CKS.0x0037-2D2D.BIN", "rb") as binary_file:
    # Read the whole file at once
    v26_u20 = binary_file.read()

with open("V27\\U19_V27.bin", "rb") as binary_file:
    # Read the whole file at once
    v27_u19 = binary_file.read()

with open("V27\\U20_V27.BIN", "rb") as binary_file:
    # Read the whole file at once
    v27_u20 = binary_file.read()

print(len(v26_u19))
print(len(v26_u20))

print(len(v27_u19))
print(len(v27_u20))

newFile = open("TSSOP_ROMs.bin", "wb")


def write_to_file(file, bytes, invert_a13=False):
    munge = 1 << 13 if invert_a13 else 0
    for i in range(0, len(bytes)):
        file.write(bytes[i ^ munge].to_bytes(1, byteorder='big'))
        # print(f"{i:04X}, {i^munge:04X}, {munge:04X} ")



# Image 1

for r in range(0, 4):
    write_to_file(newFile, v08_u20)
    write_to_file(newFile, v08_u21)

# Image 2

for r in range(0, 2):
    write_to_file(newFile, v14_u19, True)

for r in range(0, 4):
    write_to_file(newFile, v14_u20, True)

# Image 3

write_to_file(newFile, v26_u19, True)
write_to_file(newFile, v26_u20, True)

# Image 4

write_to_file(newFile, v27_u19, True)
write_to_file(newFile, v27_u20, True)

newFile.close()
