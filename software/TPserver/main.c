/* Target Protect Project*/

// function: Create a socket server. Dump the received message from the client and loopack the message to client.
// usage: TPServer PortNum, PortNum is a interger larger than 2000.

// Mods histories:
// Oct.10,2018, SL: created from the DE10 Nano TCP socket demo example
// May 4,2019, SL: add capability to accept more than one TCP connections.

// It's working with two connections using blocking functions accept and join, but not ideal.
// if the first connection ends before the 2nd connection ends, then it could not connect again until the 2nd connection ends.
// Needs to use non-blocking accept or join methods to make it beautiful.
// Another remained issue is: if the first connection access too often, the 2nd connection times out, it seems 
// it could not assign fair bandwidth to both connections.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h> 
#include <sys/socket.h>
#include <netinet/in.h>

#include <pthread.h>


#include "main.h"


void error_exit(const char *msg)
{
    perror(msg);
    exit(1);
}

int cmd_proc(char *cmdString_in , int *value_back, char **string_back, int **array_Ptr, int *array_Dim);
void Load_Conf();


void* VR_BASE;



void *TCP_connection(void *void_newsockfd)
{
 char cmdString[256];
 int n,value, sendTrue, strLength;
 int *array_Ptr,array_Dim;
 int array_Index;
 char valueString[50],arrayString[STRING_MAX_LENGTH];
 char *string_back;

 int *newsockfd = void_newsockfd;
 int loop = 0;
   
 while(1) {
            bzero(cmdString,256);
            n=read(*newsockfd,cmdString,255);
            if ( n <= 0) {perror(" i am in com_proc, connection closed by client"); break; }
            else printf("loop=%d, Received message: %s, n=%d \n",loop++,cmdString,n);
            
            sendTrue = cmd_proc(cmdString,&value, &string_back, &array_Ptr, &array_Dim);  	 /* process the command */
              
            if (sendTrue != 0 ){
		        if (sendTrue == 1){
			        sprintf(valueString,"%d\r\n",value);
			        strLength = strlen(valueString);
			        printf("value readback from FPGA = %d \n",value);
			        if ( write(*newsockfd,valueString,strLength) < 0) //Send to client
			            {perror("ERROR writing to client"); break; }
		        }   
		        if (sendTrue == 3){
			        arrayString[0]= '\0';
			        for (array_Index=0; array_Index<array_Dim; array_Index++) {
				        if(array_Index == array_Dim - 1)
					        sprintf(valueString,"%d\r\n",*(array_Ptr +array_Index)); 
					        //the termination chars changed from \n\r to \r\n, due to Labview TCP_read requires so, SL, 2018_0531
				        else  sprintf(valueString,"%d,",*(array_Ptr +array_Index));
				        if ( (strLength = strlen(arrayString)) < (STRING_MAX_LENGTH - strlen(valueString)) )
					        strcat(arrayString, valueString);
				        else printf("Main.c: data is too long for the output string \n\r");
			        }
			        strLength = strlen(arrayString);
    			    if (write(*newsockfd, arrayString, strLength) < 0)	
				        {perror("ERROR writing to client"); break; }
				    else printf("FIFO transfer successfully string length = %d \n\r",strLength);    
			    }
            }
            
            if ( write(*newsockfd,"0",1) < 0) //ack to client
			   {perror("ERROR writing to client"); break; }
            
  }       
}




int main(int argc, char* argv[])
{
    if (argc < 2) {
         fprintf(stderr,"ERROR, no port provided\n");
         fprintf(stderr,"Usage: TPServer portnum\n");
         exit(1);
     }
     
    // Mappming address of the FPGA registers/fifo to user space
  	
	int fd;
	
	if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) {
		error_exit("open \"/dev/mem\"");
        
	}

	VR_BASE = mmap( NULL, HW_REGS_SPAN,( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE );
	
	if( VR_BASE == MAP_FAILED ) {
    	close( fd );
		error_exit("mmap");	       
	}
                       
    
     int sockfd, newsockfd1,newsockfd2,portno;
     socklen_t clilen;
     
     struct sockaddr_in serv_addr, cli_addr;
          
     sockfd = socket(AF_INET, SOCK_STREAM, 0);
     if (sockfd < 0) 
        error_exit("ERROR opening socket"); 
     
     bzero((char *) &serv_addr, sizeof(serv_addr));
     portno = atoi(argv[1]);
     serv_addr.sin_family = AF_INET;
     serv_addr.sin_addr.s_addr = INADDR_ANY;
     serv_addr.sin_port = htons(portno);
     
     if (bind(sockfd, (struct sockaddr *) &serv_addr,sizeof(serv_addr)) < 0) 
        error_exit("ERROR on binding");
     
     listen(sockfd,5); //non-blocking, return immediatly
     clilen = sizeof(cli_addr);
     
     
	 //char arrayString[STRING_MAX_LENGTH];
	 
	 //load configration from eeprom
	 Load_Conf();
       
	 
	 pthread_t TCP1_thread,TCP2_thread;  
	 
		 
	 printf("Accepting for connection request...\n");    
     newsockfd1 = accept(sockfd, (struct sockaddr *) &cli_addr, &clilen); //blocking until received a connection request
     if (newsockfd1 < 0) error_exit("ERROR on accept");
     
      
     printf("TCP Socket XTpage Connection Established!\n"); 
        
        /* create a TCP thread  */
     if(pthread_create(&TCP1_thread, NULL, TCP_connection, &newsockfd1)) error_exit("Error creating thread 1\n");
       
     while(1) {
   
        printf("Accepting for Labview connection request...\n");    
        newsockfd2 = accept(sockfd, (struct sockaddr *) &cli_addr, &clilen); //blocking until received a connection request
        if (newsockfd2 < 0) error_exit("ERROR on accept");
        
        printf("TCP Socket Labview Connection Established!\n");     
 
        if(pthread_create(&TCP2_thread, NULL, TCP_connection, &newsockfd2)) error_exit("Error creating thread 2\n");
           
         
        //the following statement is blocking, this needs to be solved.
        if(pthread_join(TCP2_thread, NULL)) error_exit("Error joining thread\n");
        close(newsockfd2); 
        
          
     } //waitting for connection request
 
 
     if(pthread_join(TCP1_thread, NULL)) error_exit("Error joining thread\n");
     close(newsockfd1);
     
close(sockfd);
return 0; 

     

}
//this is the awake bpm write format: 
 //com+' '+str(data)+'\r\n'   
//Disable FIFO Interrupts
//    writeReg(fifo_csr_addr, 3, 0x00000000);
     