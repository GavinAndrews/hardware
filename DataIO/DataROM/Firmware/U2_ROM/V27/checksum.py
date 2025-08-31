import hashlib

for fname in ["U19_V27.bin", "U20_V27.BIN"]:

    with open(fname, "rb") as binary_file:
        # Read the whole file at once
        data_buffer = binary_file.read()

    for index in range(0, len(data_buffer), 2048):
        hash_object = hashlib.sha1(bytes(data_buffer[index:index+2048]))
        hash = hash_object.hexdigest()
        print(f"{fname} {index:04X} SHA1: {hash}")
