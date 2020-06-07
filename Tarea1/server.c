#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <time.h>
#include  <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
 #include <sys/types.h>
 #include "logger.h"
//Usar -lm al compilar

//ES NECESARIO INCLUIR TODO ESO:
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image/stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image/stb_image_write.h"
#include "filtro_mediana.h"
#include "filtro_media.h"
#include "clasificador.h"

const char* configDirection = "/etc/server/config.conf";
char header[] = 
"HTTP/1.1 200 OK\n"
"Access-Control-Allow-Origin: *\n"
"Content-Type: text/html, image/jpeg, image/png \n"
"Accept-Ranges: bytes\n"
"Connection: close\n"
"\n";
char msg1[] = "ok\n";

/**
 * Este método encuentra el tamño en bytes del archivo enviado
*/
int findlenght(char fname[100]){
    const char *ptr = strstr(fname, "Content-Length:");
    int index = 0;
    int index2 = 0;
    int result = 0;    
    int indextotal = 0;
    if(ptr) {
        index = ptr - fname;
        //printf("Found string at index = %d\n", index);
        indextotal = index + 16;
        const char *ptr2 = strstr(&fname[indextotal], "\n");
        if(ptr2){
            index2 = ptr2 - &fname[indextotal];
            //printf("Found line jump at index = %d\n", index2);
        }
        char length[index2];
        for(int i =indextotal; i<indextotal+index2; i++){
            length[i-indextotal]= fname[i];
        }
        //printf("Found length = %s\n", length);
        result=atoi(length);
        return result;
        // do something
    }
}

/**
 * Este método obtiene la hora en que se está ejecutando el archivo enviado
*/
void getTime(char *DirLog){
     time_t t = time(NULL);
    struct tm tm = *localtime(&t);
    char hour[8]; 
    sprintf(hour,"%02d",tm.tm_hour);
    char min[6];  
    sprintf(min,"%02d",tm.tm_min);
    char sec[3];  
    sprintf(sec,"%02d",tm.tm_sec);
    strcat(min,":");
    strcat(hour,":");
    strcat(min,sec);
    strcat(hour,min);
    if (logger(DirLog, "Time:") == -1) {
            perror("Logger Error: Accept Error");
        }
    if (logger(DirLog, hour) == -1) {
            perror("Logger Error: Accept Error");
        }
}
/**
 * Este método haya el puerto al que debe de hacer bind el servidor
*/
int port(){
    FILE *fp1;
    fp1 = fopen(configDirection, "r"); //cambiar 
    if(NULL == fp1)
    {
        printf("Error opening file");
        return 1;
    }
    char line[256];
    int linenum=0;
    while(fgets(line, 256, fp1) != NULL)
    {
        char LINE[256], port[256];
        linenum++;
        if(sscanf(line, "%s %s", LINE, port) != 2)
        {
            fprintf(stderr, "Syntax error, line %d\n", linenum);
            continue;
        }
        if(linenum==1){
            //printf("Line %d:  IP %s MAC %s\n", linenum, LINE, port);
            return atoi(port);
        }      
    }  
}
/**
 * Este método encuentra el nombre de la imagen enviada por el cliente
*/
char* findFileName(char fname[100],char *DirLog){
    const char *ptr = strstr(fname, "filename");
    int index = 0;
    int indexTotal = 0;
    int index2 = 0;
    index = ptr - fname;
    //printf("Found string at index = %d\n", index);
    indexTotal = index+10;
    const char *ptr2 = strstr(&fname[indexTotal], "\"");
    index2 = ptr2 - &fname[indexTotal];
    //printf("Found line jump at index = %d\n", index2);
    char name[index2];
    memset(name,0,sizeof name);
    for(int i =indexTotal; i<indexTotal+index2; i++){
        name[i-indexTotal]= fname[i];
    }
    name[index2] = '\0';
    //printf("Found name = %s\n", name);
    if (logger(DirLog, "File name:") == -1) {
            perror("Logger Error: File name");
        }
    if (logger(DirLog, name) == -1) {
            perror("Logger Error: File name");
        }
    char *fullName =  malloc(sizeof(name));
    
    strcpy(fullName, name);
   
    return fullName;

}
/**
 * Este método encuentra el nombre del cliente que envió la petición
*/
void findClientName(char fname[100],char *DirLog){
    const char *ptrC = strstr(fname, "User-Agent");
    int indexC= 0;
    int indexTotalC = 0;
    int index2C = 0;
    indexC = ptrC - fname;
    //printf("Found string at index = %d\n", indexC);
    indexTotalC = indexC+12;
    const char *ptr2C = strstr(&fname[indexTotalC], "\n");
    index2C = ptr2C - &fname[indexTotalC];
    //printf("Found line jump at index = %d\n", index2C);
    char nameC[index2C];
    memset(nameC,0,sizeof nameC);
    for(int i =indexTotalC; i<indexTotalC+index2C; i++){
        nameC[i-indexTotalC]= fname[i];
    }
    nameC[index2C] = '\0';
    ///printf("Found Client name = %s\n", nameC);
    if (logger(DirLog, "Client name:") == -1) {
            perror("Logger Error: Client name");
        }
    if (logger(DirLog, nameC) == -1) {
            perror("Logger Error: Client name");
        }
}
/**
 * Este método haya el path para guardar el histórico de imágenes
*/
char* findDirHist(){
    FILE *fp1;
    fp1 = fopen(configDirection, "r"); 
    if(NULL == fp1)
    {
        printf("Error opening file");
        exit(1);
    }
    char line[256];
    int linenum=0;
    while(fgets(line, 256, fp1) != NULL)
    {
        char LINE[256], dir[256];
        linenum++;
        if(sscanf(line, "%s %s", LINE, dir) != 2)
        {
            fprintf(stderr, "Syntax error, line %d\n", linenum);
            continue;
        }
        if(linenum==2){
            char *Dir =  malloc(sizeof(dir));
            strcpy(Dir, dir);
            return Dir;
        }      
    }  
}
/**
 * Método para hayar el path donde se clasificarán las imágenes
*/
char* findDirCla(){
    FILE *fp1;
    fp1 = fopen(configDirection, "r"); 
    if(NULL == fp1)
    {
        printf("Error opening file");
        exit(1);
    }
    char line[256];
    int linenum=0;
    while(fgets(line, 256, fp1) != NULL)
    {
        char LINE[256], dir[256];
        linenum++;
        if(sscanf(line, "%s %s", LINE, dir) != 2)
        {
            fprintf(stderr, "Syntax error, line %d\n", linenum);
            continue;
        }
        if(linenum==4){
            char *Dir =  malloc(sizeof(dir));
            strcpy(Dir, dir);
            return Dir;
        }      
    }  
}
/**
 * Método que encuentra el path para escribir el log del sistema
*/
char* findDirLogFile(){
    FILE *fp1;
    fp1 = fopen(configDirection, "r"); 
    if(NULL == fp1)
    {
        printf("Error opening file");
        exit(1);
    }
    char line[256];
    int linenum=0;
    while(fgets(line, 256, fp1) != NULL)
    {
        char LINE[256], dir[256];
        linenum++;
        if(sscanf(line, "%s %s", LINE, dir) != 2)
        {
            fprintf(stderr, "Syntax error, line %d\n", linenum);
            continue;
        }
        if(linenum==3){
            char *Dir =  malloc(sizeof(dir));
            strcpy(Dir, dir);
            return Dir;
        }      
    }  
}
/**
 * Concatena dos strings se utiliza para crear el path completo de direcciones
*/
char *concatenateString(const char *firstString, const char *secondString) {
    const size_t firstStringSize = strlen(firstString);
    const size_t secondStringSize = strlen(secondString);

    // Malloc with +1 for finish null character in string
    char *finalString = (char *) malloc(firstStringSize + secondStringSize + 1);

    if (finalString == NULL) {

        perror("Malloc Error : concatenateString()");
        return "";
    }

    memcpy(finalString, firstString, firstStringSize);

    // Malloc with +1 for finish null character in string
    memcpy(finalString + firstStringSize, secondString, secondStringSize + 1);

    return finalString;
}
/**
 * Se encarga de escribir la imagen recibida y de ejecutar los filtros y el clasificador
*/
void writefile(char buff[100],int sockfd, char* DirLog,char* DirHist,char* DirCla)
{
    char buff2[134];
    char buff3[100];
    FILE *fp;
    int length= 0;
    char *name;
    findClientName(buff,DirLog);
    length = findlenght(buff);
    read(sockfd, buff2, 134);
    //printf("buff2: %s",buff2);
    name = findFileName(buff2,DirLog);
    char *fullpath = concatenateString(DirHist,name);
    //printf("fuuulAPTH %s",fullpath);
    fp = fopen(fullpath, "ab"); 
        if(NULL == fp)
            {
            perror("Error opening file");
            }
    int total = length - 277; 
    long double sz=1;
    int bytesReceived = 0;
    char recvBuff[1];
    memset(recvBuff, '0', sizeof(recvBuff));
        while((bytesReceived = read(sockfd, recvBuff, 1)) > 0)
        { 
            sz++;
            if (sz == total){ 
                fclose(fp);
                break;
            }
            else{
                fwrite(recvBuff, 1,bytesReceived,fp);
            }
        }
        if(bytesReceived < 0)
        {
            printf("\n Read Error \n");
        }
        if (logger(DirLog, "-File OK....Tranfer Completed") == -1) {
                perror("Logger Error: Tranfer ");
            }
        sleep(2);
        filter_mediana(fullpath,DirCla,DirLog); 
	    filter_media(fullpath,DirCla,DirLog); 
	    clasificardor(fullpath,DirCla,DirLog);
        free(name);
        //printf("\nFile OK....Completed\n");
}
/**
 * Método principañ
*/
int main(int argc, char *argv[]) 
{
    system("clear");
    strcat(header, msg1);
    int numPort = port();
    char *DirHist = findDirHist();
    char *DirCla = findDirCla();
    char *DirLog = findDirLogFile();
    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd == -1) 
    {
        perror("Can't allocate sockfd");
        if (logger(DirLog, "Error creating socket") == -1) {
            perror("Logger Error: Error creating socket");
        }
        exit(1);
    }
    struct sockaddr_in clientaddr, serveraddr;
    memset(&serveraddr, 0, sizeof(serveraddr));
    serveraddr.sin_family = AF_INET;
    serveraddr.sin_addr.s_addr = htonl(INADDR_ANY);
    serveraddr.sin_port = htons(numPort);
    struct sockaddr_in serv_addr;
    if (bind(sockfd, (const struct sockaddr *) &serveraddr, sizeof(serveraddr)) == -1) 
    {
        perror("Bind Error");
        close(sockfd);
        if (logger(DirLog, "Bind Error") == -1) {
            perror("Logger Error: Bind Error");
        }
        exit(1);
    }
    if (listen(sockfd, 10) == -1) 
    {
        perror("Listen Error");
        close(sockfd);
        if (logger(DirLog, "Listen Error") == -1) {
            perror("Logger Error: Listen Error");
        }
        exit(1);
    }
    while(1)
    {
         printf("\n+++++++ Waiting for new connection ++++++++\n\n");
        socklen_t addrlen = sizeof(clientaddr);
        int connfd = accept(sockfd, (struct sockaddr *) &clientaddr, &addrlen);
        if (connfd == -1) 
        {
            perror("Accept Error");
            close(sockfd);
            if (logger(DirLog, "Accept Error") == -1) {
                perror("Logger Error: Accept Error");
            }
            exit(1);
        }
        if (logger(DirLog, "---New connection---") == -1) {
                perror("Logger Error: ---New connection---");
            }
        getTime(DirLog);
        char buff[520];
        read(connfd, buff, 520);
        //printf("buff: %s",buff);
        writefile(buff,connfd,DirLog,DirHist,DirCla); 
        send(connfd, header, strlen(header), 0);
        close(connfd);
        /*if(!strncmp(buff, "POST /upload", 12)){
            
            writefile(buff,connfd,DirLog,DirHist,DirCla); 
            send(connfd, header, strlen(header), 0);
            
            close(connfd);
        }*/
        
    }
    return 0;
    
}



