import os

dir = "C:\\Users\\Gavin\\Documents\\Projects\\hardware\\chip-tester\\Pet2001\\PET_ROMS\\Multi1"

files = os.listdir(dir)

files = list(filter(lambda f : f.find("combined")==-1, files))

print(files)

files.sort()

fwrite = open(dir+"\\combined.bin", "wb")

for f in files:
    print(f)
    with open(dir+"\\"+f, "rb") as fread:
        while True:
            byte = fread.read(1)
            if not byte:
                # eof
                break
            fwrite.write(byte)
            print(".", end="")
    print("")

fwrite.close()