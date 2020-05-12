

void filter_media(char* dir, char* spath,char*  WebServerpath) {
	char savepath[50];
	strcpy(savepath,spath);
	strcat(savepath,"/Output_MeanFilter");
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

	size_t img_size = width * height * channels;
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
	strcpy(msj1,"--Applying mean filter to ");
	strcpy(msj2,"--Logger Error: Applying mean filter to ");
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
	char ruta[50];
	strcat(savepath,"/");
	strcat(savepath,nombre);
	strcat(savepath,".jpg");

	

	pixeles vector[9]; //vector donde se almacenarán los vecinos
	int	rojo[9];
	int int_rojo; // donde se almacenará la media del rojo
	int verde [9];
	int int_verde; // donde se almacenará la media del verde
	int azul[9];
	int int_azul; // donde se almacenará la media del azul
	unsigned char  *po;
	po=output_img ;
	
	for (int fila=1; fila<height-1;fila++){
		for (int col=1;col<=width ;col++){
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
			//SE SUMAN LOS PIXELES VECINOS DE CADA COLOR
			int_rojo=rojo[0]+rojo[1]+rojo[2]+rojo[3]+rojo[4]+rojo[5]+rojo[6]+rojo[7]+rojo[8];
			int_verde=verde[0]+verde[1]+verde[2]+verde[3]+verde[4]+verde[5]+verde[6]+verde[7]+verde[8];
			int_azul=azul[0]+azul[1]+azul[2]+azul[3]+azul[4]+azul[5]+azul[6]+azul[7]+azul[8];

			//SE SACA LA MEDIA DE CADA COLOR y se escribe cada pixel
			*output_img=int_rojo / 9; //se saca la mediana del rojo;
			*(output_img+1)=int_verde / 9; //se saca la mediana del rojo;
			*(output_img+2)=int_azul / 9; //se saca la mediana del rojo;


			output_img+=channels;
			
		}
		

	}
	
	
	

	//printf ("RUTA: %s\n",savepath);
	stbi_write_jpg(savepath, width, height, channels, po, 100);  //se escribe una imagen
	



	//printf("Width %dpx, Height %dpx\n",width, height);
	
	stbi_image_free(img);
	//stbi_image_free(output_img);
 
 
}

