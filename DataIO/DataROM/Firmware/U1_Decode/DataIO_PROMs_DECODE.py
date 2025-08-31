from src.chiptester.DataIOPROMs.impls.Decode import MemoryDecode

rom = []

for unused in range(0,4):
    for rnw in (False, True):
        for addr in range(0, 65536, 16):
            a = [bool(addr & 2 ** x) for x in range(0, 16)]

            for banks in range(0, 16):  # 16
                block = [bool(banks & 2 ** x) for x in range(0, 4)]

                # OLD SCHEME
                if block[0] == 0:
                    u19, u14 = MemoryDecode.u19_and_u14_old_scheme(rnw, addr)
                else:
                    u19, u14 = MemoryDecode.u19_and_u14_new_scheme(rnw, addr)

                rom.append(u19 << 4 | u14)

print(len(rom))

newFile = open("TSSOP_DecoderWR.bin", "wb")
# write to file
for byte in rom:
    newFile.write(byte.to_bytes(1, byteorder='big'))

newFile.close()
