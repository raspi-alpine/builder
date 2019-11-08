#include <stdio.h>
#include <stdint.h>
#include <string.h>

char* uboot_file = "/uboot/uboot.dat";


void printHelp() {
    printf("Usage: uboot_tool [COMMAND]\n");
    printf("\n");
    printf("Commands:\n");
    printf(" part_current  - show current partition\n");
    printf(" part_switch   - switch active partition\n");
    printf(" reset_counter - reset boot counter\n");
    printf(" version       - show version of file\n");
}

uint32_t crc32(uint8_t* data, size_t length, uint32_t seed) {
    uint32_t crc = ~seed;
    while (length--) {
        crc ^= (*data++);
        for (unsigned int j = 0; j < 8; j++) {
            if (crc & 1) {
                crc = (crc >> 1) ^ 0xedb88320L;
            } else {
                crc =  crc >> 1;
            }
        }
    }
    return ~crc;
}

int main(int argc, char* argv[]) {
    // show help if no command given
    if (argc < 2) {
        printHelp();
        return 1;
    }
    char* cmd = argv[1];

    // read uboot file
    FILE* file = fopen(uboot_file, "rb");
    if (file == NULL) {
        printf("Failed to open uboot file: %s\n", uboot_file);
        return 2;
    }
    uint8_t data[1024];
    size_t err = fread(data, 1, sizeof(data), file);
    if (err == 0) {
        printf("Failed to read uboot file: %s\n", uboot_file);
        return 2;
    }
    fclose(file);

    // get crc from file
    uint32_t crc = (data[1023] << 24) + 
                   (data[1022] << 16) + 
                   (data[1021] << 8) + 
                    data[1020];

    // check if CRC is valid
    if (crc != crc32(data, 0x3FC, 0)) {
        fprintf(stderr, "Invalid CRC -> fallback to default\n");

        memset(data, 0, sizeof(data));

        // file version
        data[0] = 1;

        // boot counter
        data[1] = 0;

        // boot partition
        data[2] = 2; // A=2, B=3
    }

    // handle commands
    uint8_t save = 0;
    if (strcmp(cmd, "version") == 0) {
        printf("0x%02x\n", data[0]);

    } else if (strcmp(cmd, "part_current") == 0) {
        printf("%d\n", data[2]);

    } else if (strcmp(cmd, "part_switch") == 0) {
        if (data[2] == 2) {
            data[2] = 3;
        } else {
            data[2] = 2;
        }
        save = 1;

    } else if (strcmp(cmd, "reset_counter") == 0) {
        data[1] = 0;
        save = 1;

    } else {
        printf("Unknown command\n");
        return 10;
    }

    if (save == 1) {
        // calculate new CRC
        crc = crc32(data, 0x3FC, 0);
        data[1023] = (uint8_t)((crc & 0xFF000000U)>>24);
        data[1022] = (uint8_t)((crc & 0x00FF0000U)>>16);
        data[1021] = (uint8_t)((crc & 0x0000FF00U)>>8);
        data[1020] = (uint8_t)((crc & 0x000000FFU));

        // write uboot file
        file = fopen(uboot_file, "wb");
        if (file == NULL) {
            printf("Failed to open uboot file: %s\n", uboot_file);
            return 4;
        }
        size_t err = fwrite(data, 1, sizeof(data), file);
        if (err == 0) {
            printf("Failed to write uboot file: %s\n", uboot_file);
            return 4;
        }
        fclose(file);
    }

    return 0;
}
