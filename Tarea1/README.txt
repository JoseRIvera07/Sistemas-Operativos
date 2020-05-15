compilar asi: gcc -o server server.c -lm

ejecutar asi: ./server


URL: http://localhost:1717

Sí el envío de la imagen es exitoso, el servidor responde un: "ok"

ssh -R 80:localhost:1717 serveo.net
