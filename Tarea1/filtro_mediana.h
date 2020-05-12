
typedef struct{ //estructura que permitirá almacenar los colores de cada pixel
	int rojo;
	int  verde;
	int azul;
} pixeles;



pixeles RGB(unsigned char *img, int x, int y, size_t img_size, int  width, int height , int channels); //función para acceder al pixel necesitado según X y Y

int cmpfunc (const void * a, const void * b) { //funcion para comparar
   return ( *(int*)a - *(int*)b );
}


void filter_mediana(char* dir, char*  spath, char*  WebServerpath) {
	char savepath[50];
	strcpy(savepath,spath);
	strcat(savepath,"/Output_MedianFilter");
	struct stat st = {0};

	if (stat(savepath, &st) == -1) {
	    mkdir(savepath, 0777);
	}

	int width, height, channels; // detalles de la imagen
	pixeles pix; //pixel
	unsigned char *img = stbi_load(dir, &width, &height, &channels, 0); // imagen leída
	if (img == NULL) { //verifica si se cargó correctamente
		printf("Error in loading the image\n");
		exit(1);
	}

	size_t img_size = width * height * channels; //tamaño de la imagen
	unsigned char *output_img = malloc(img_size*(sizeof(int))); //se toma una porción de memoria
	if(output_img == NULL) {
        	printf("Unable to allocate memory for the new image.\n");
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
	strcpy(msj1,"--Applying median filter to ");
	strcpy(msj2,"--Logger Error: Applying median filter to ");
	strcat(msj1,pch2);
	strcat(msj2,pch2);
	strcat(msj1,"--");
	strcat(msj2,"--");
	
	if (logger(WebServerpath, msj1) == -1) {
                perror(msj2);
            }


	//SE ESTABLECE EL NOMBRE FORMATO JPG Y LA RUTA FINAL
	char* nombre;
	nombre= strtok (pch2,".");
	strcat(savepath,"/");
	strcat(savepath,nombre);
	strcat(savepath,".jpg");

	pixeles vector[9]; //vector donde se almacenarán los vecinos
	int	rojo[9]; // vector de pixeles rojos
	int verde [9]; // vector de pixeles verdes
	int azul[9]; // vector de pixeles azules
	unsigned char  *po; //puntero a la dirección de memoria donde está la imagen
	po=output_img ; // 
	
	for (int fila=1; fila<height-1;fila++){
		for (int col=1;col<=width ;col++){
			//SE TOMAN LOS  PIXELES VECINOS
			vector[0]=RGB(img,col-1,fila-1,img_size,width,height ,channels);
			vector[1]=RGB(img,col,fila-1,img_size,width,height ,channels);
			vector[2]=RGB(img,col+1,fila-1,img_size,width,height ,channels);
			vector[3]=RGB(img,col-1,fila,img_size,width,height ,channels);
			vector[4]=RGB(img,col,fila,img_size,width,height ,channels);
			vector[5]=RGB(img,col+1,fila,img_size,width,height ,channels);
			vector[6]=RGB(img,col-1,fila+1,img_size,width,height ,channels);
			vector[7]=RGB(img,col,fila+1,img_size,width,height ,channels);
			vector[8]=RGB(img,col+1,fila+1,img_size,width,height ,channels);


			//SIGUE TOMAR VECTOR Y HACER UNA LISTA DE CADA COLOR
			//ROJO
			rojo[0]=vector[0].rojo;
			rojo[1]=vector[1].rojo;
			rojo[2]=vector[2].rojo;
			rojo[3]=vector[3].rojo;
			rojo[4]=vector[4].rojo;
			rojo[5]=vector[5].rojo;
			rojo[6]=vector[6].rojo;
			rojo[7]=vector[7].rojo;
			rojo[8]=vector[8].rojo;

			//VERDE
			verde[0]=vector[0].verde;
			verde[1]=vector[1].verde;
			verde[2]=vector[2].verde;
			verde[3]=vector[3].verde;
			verde[4]=vector[4].verde;
			verde[5]=vector[5].verde;
			verde[6]=vector[6].verde;
			verde[7]=vector[7].verde;
			verde[8]=vector[8].verde;

			//AZUL
			azul[0]=vector[0].azul;
			azul[1]=vector[1].azul;
			azul[2]=vector[2].azul;
			azul[3]=vector[3].azul;
			azul[4]=vector[4].azul;
			azul[5]=vector[5].azul;
			azul[6]=vector[6].azul;
			azul[7]=vector[7].azul;
			azul[8]=vector[8].azul;

			//SE ORDENA CADA LISTA
			qsort(rojo, 9, sizeof(int), cmpfunc);
			qsort(verde, 9, sizeof(int), cmpfunc);
			qsort(azul, 9, sizeof(int), cmpfunc);

			//SE SACA LAS MEDIANAS DE CADA COLOR y se escribe cada pixel
			*output_img=rojo[4]; //se saca la mediana del rojo;
			*(output_img+1)=verde[4]; //se saca la mediana del rojo;
			*(output_img+2)=azul[4]; //se saca la mediana del rojo;

			output_img+=channels; //se avanza a la siguiente posición
		}

	}
	//printf ("RUTA: %s\n",savepath);
	stbi_write_jpg(savepath, width, height, channels, po, 100);  //se escribe una imagen
	
	stbi_image_free(img); //se libera la imagen
 
}


 pixeles RGB(unsigned char *img, int x, int y, size_t img_size, int  width, int height , int channels){
	pixeles rgb;  //los colores del pixel se almacenarán en esa estructura
	unsigned char  *p = img+(y*width+x)*channels; //fórmula para calcular el pixel correspondiente
	rgb.rojo=*p; //se toma el color rojo del pixel 
	rgb.verde=*(p+1); //se toma el color ver del pixel
	rgb.azul=*(p+2);  //se toma el color azul del pixel
	
	return rgb;
} 


