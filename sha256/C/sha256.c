#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>

#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>

#define HASH_BASE_ADDR 0x00
#define STATUS_ADDR 0x20
#define MSG_SIZE1_ADDR 0x24
#define MSG_SIZE2_ADDR 0x28
#define MSG_BASE_ADDR 0x2c

int main(int argc, char* argv[]) {

  if(argc!=2){
    printf("Usage: sha256 <message>\n");
    exit(EXIT_FAILURE);
  }

  int i;
	int fd;

  char *M = argv[1];
  uint32_t M_size = strlen(argv[1]);
  uint64_t M_bits = M_size * 8;
  uint32_t nblocks = (M_size*8 + 64 + 1 + 512)/512;

  char *data_buffer;
  uint32_t status;

  #ifndef DEBUG
  uint32_t hash[8];
  #else
  uint32_t file_content[8 + 1 + 2 + nblocks*16]; // Hash + status + size + msg
  #endif

  #ifndef DEBUG
  if((fd=open("/dev/sha256", O_RDWR))==-1) {
    fprintf(stderr, "Error: no sha256 device driver.\n");
    abort();
  }
  #else
  if((fd=open("bogus", O_RDWR))==-1) {
    fprintf(stderr, "Error: no sha256 device driver.\n");
    abort();
  }
  #endif

  // Message padding
  data_buffer=malloc(nblocks*64*sizeof(char));
  if (memset(data_buffer, 0, nblocks*64*sizeof(char)) == NULL) {
    fprintf(stderr, "Error: Couldn't allocate data_buffer.\n");
    abort();
  }
  // 1) Add message
  if(memcpy(data_buffer, M, M_size) == NULL) {
    fprintf(stderr, "Error: Couldn't allocate data_buffer.\n");
    abort();
  }

  // 2) Append 1
  data_buffer[M_size]=0x80;

  // 3) Append zeroes and message length
  for(i=0; i<8; i++) {
    data_buffer[nblocks*64 - 1 - i] = (M_bits >> 8*i ) & 0xff;
  }

  // Send nblocks
  pwrite(fd, &nblocks, 4, MSG_SIZE1_ADDR);

  // Send padded message
  for(i=0; i<nblocks*16; i++) {
    pwrite(fd, &data_buffer[i*4], 4, MSG_BASE_ADDR+i*4);
  }

  // Poll status bit until done
  pread(fd, &status, 4, STATUS_ADDR);
  while( (status & 0x01) != 1) {
    pread(fd, &status, 4, STATUS_ADDR);
  }

  #ifndef DEBUG
  // Extract & print hash

  // Print hash
  for(i=0; i<8; i++) {
    pread(fd, &hash[i], 4, HASH_BASE_ADDR+i*4);
    printf("%08x ", hash[i]);
  }
 #else
 // Extract & print all
 for(i=0; i<8+1+2+nblocks*16; i++) {
    pread(fd, &file_content[i], 4, HASH_BASE_ADDR+i*4);
    printf("%08x ", file_content[i]);
 }
 #endif

  printf("\n");
	close(fd);

  return 0;
}
