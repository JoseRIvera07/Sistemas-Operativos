#include <string.h> 


void clasificardor(char*  dir,  char* spath,char*  WebServerpath){

	//SE CREAN LAS CARPETAS, SI YA EXISTEN NO LAS CREA NI LAS MODIFICA
	char savepathR[50]; //ruta verde
	char savepathV[50]; //rutav
	char savepathA[50]; //ruta azul
	strcpy(savepathR,spath);
	strcpy(savepathV,spath);
	strcpy(savepathA,spath);
	strcat(savepathR,"/Rojas");
	strcat(savepathV,"/Verdes");
	strcat(savepathA,"/Azules");
	struct stat st = {0};

	if (stat(savepathR, &st) == -1) {
	    mkdir(savepathR, 0777);
	}

	if (stat(savepathV, &st) == -1) {
	    mkdir(savepathV, 0777);
	}

	if (stat(savepathA, &st) == -1) {
	    mkdir(savepathA, 0777);
	}

	//SE ABRE LA IMAGEN
	int width, height, channels; // detalles de la imagen

	unsigned char *img = stbi_load(dir, &width, &height, &channels, 0); // imagen leída
	if (img == NULL) { //verifica si se cargó correctamente
		//printf("Error in loading the image\n");
		exit(1);
	}



	//SE OBTIENE EL NOMBRE DEL ARCHIVO
	char buf[512]; 
  	strcpy(buf, dir); //se copia la dirección para poderla trabajar
 	char * pch;
	char* pch2; //acá se almacenará el nombre de la imagen
 	pch = strtok (buf,"/");

	  while (pch != NULL) //se fragmenta el string, se obtiene el nombre de la imagen con el último fragmento de la cadena
	  {

		pch2=pch; 
	    	pch = strtok (NULL, "/");

	  }

	//SE REGISTRA QUE SE ESTÁ FILTRANDO LA IMAGEN
	char msj1[50];
	char msj2[50];
	strcpy(msj1,"--Classifying image: ");
	strcpy(msj2,"--Logger Error: Classifying image:  ");
	strcat(msj1,pch2);
	strcat(msj2,pch2);
	strcat(msj1,"--");
	strcat(msj2,"--");
	
	if (logger(WebServerpath, msj1) == -1) {
                perror(msj2);
            }

	//SE LE QUITA EL FORMATO
	char* nombre;
	nombre= strtok (pch2,".");

	


	//SE TOMAN LOS COLORES DE LOS PIXELES
	int rojo=0; // donde se almacenará el valor del rojo
	int verde=0; // donde se almacenará el valor del verde
	int azul=0; // donde se almacenará el valor del azul
	size_t img_size = width * height * channels;
	
for(unsigned char *p = img; p != img + img_size; p += channels) {  //Se recorre la imagen sumando cada color
	rojo+=*p;
	verde+=*(p + 1);
	azul+=*(p + 2);
}


char ruta[50];
if (verde<rojo && azul<rojo){
	strcpy(ruta,savepathR);
	strcat(ruta,"/");
}

else if (rojo<verde && azul<verde){
	strcpy(ruta,savepathV);
	strcat(ruta,"/");
}

else if(verde<azul && rojo<azul){
	strcpy(ruta,savepathA);
	strcat(ruta,"/");

}
else {
	strcpy(ruta,"");
}

//SE ARMA LA RUTA
strcat(ruta,nombre);
strcat(ruta,".jpg");

	
	//SE ALMACENA LA IMAGEN EN EL FOLDER CORRESPONDIENTE

	//printf ("RUTA: %s\n",ruta);
	stbi_write_jpg(ruta, width, height, channels, img, 100);  //se escribe una imagen
	stbi_image_free(img);

 
}

