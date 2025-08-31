class MemoryDecode:

    def u19_and_u14_old_scheme(rnw, addr):
        u19_old = None
        if rnw and (0x6000 <= addr <= 0x9bff):
            u19_old = 0
        elif (not rnw) and (0x9e00 <= addr <= 0x9eff):
            u19_old = 2
        elif 0x9c00 <= addr <= 0x9cff:
            u19_old = 4
        elif 0x9d00 <= addr <= 0x9dff:
            u19_old = 5
        elif rnw and (0x9e00 <= addr <= 0x9eff):
            u19_old = 6
        elif (not rnw) and (0x9f00 <= addr <= 0x9fff):
            u19_old = 7
        elif (not rnw) and (0x0000 <= addr <= 0x00ff):
            u19_old = 12
        else:
            u19_old = 15

        u14_old = 0x000f

        if (not rnw) and (0x00A0 <= addr <= 0x00AF):
            u14_old &= 0x000f ^ 1

        if rnw and (0x6000 <= addr <= 0x9bff):
            u14_old &= 0x000f ^ 2

        if (not rnw) and ((0x0090 <= addr <= 0x009f)
                          or (0x00b0 <= addr <= 0x00ff)):
            u14_old &= 0x000f ^ 4

        if rnw and (0x6000 <= addr <= 0x9eff):
            u14_old &= 0x000f ^ 8

        if (not rnw) and ((0x0090 <= addr <= 0x00ff)
                          or (0x9c00 <= addr <= 0x9cff)
                          or (0x9d00 <= addr <= 0x9dff)
                          or (0x9e00 <= addr <= 0x9eff)
                          or (0x9f00 <= addr <= 0x9fff)):
            u14_old &= 0x000f ^ 8

        return u19_old, u14_old


    def u19_and_u14_new_scheme(rnw, addr):
        u19_new = None

        if rnw and (0x6000 <= addr <= 0x9Bff):
            u19_new = 0
        elif (not rnw) and (0x9E00 <= addr <= 0x9Eff):
            u19_new = 2
        elif (not rnw) and (0x6000 <= addr <= 0x60ff):
            u19_new = 3  # u7 pin 12 page register write
        elif 0x9C00 <= addr <= 0x9Cff:
            u19_new = 4
        elif 0x9d00 <= addr <= 0x9dff:
            u19_new = 5
        elif rnw and (0x9E00 <= addr <= 0x9Eff):
            u19_new = 6
        elif (not rnw) and (0x9f00 <= addr <= 0x9fff):
            u19_new = 7
        elif (not rnw) and (0x0000 <= addr <= 0x00ff):
            u19_new = 12
        else:
            u19_new = 15

        u14_new = 0x000f

        if (not rnw) and (0x00A0 <= addr <= 0x00AF):
            u14_new &= 0x000f ^ 1

        if rnw and (0x6000 <= addr <= 0x9bff):
            u14_new &= 0x000f ^ 2

        # if (not rnw) and (0x6000 <= addr <= 0x7fff):
        #     u14_new |= 2

        if (not rnw) and ((0x0090 <= addr <= 0x009f)
                          or (0x00b0 <= addr <= 0x00ff)):
            u14_new &= 0x000f ^ 4

        if rnw and (0x6000 <= addr <= 0x9eff):
            u14_new &= 0x000f ^ 8

        if (not rnw) and ((0x0090 <= addr <= 0x00ff)
                          or (0x6000 <= addr <= 0x60ff)
                          or (0x9c00 <= addr <= 0x9cff)
                          or (0x9d00 <= addr <= 0x9dff)
                          or (0x9e00 <= addr <= 0x9eff)
                          or (0x9f00 <= addr <= 0x9fff)):
            u14_new &= 0x000f ^ 8
        return u19_new, u14_new