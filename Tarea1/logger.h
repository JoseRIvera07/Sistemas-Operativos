int logger(char *fileName, char *message) {
    FILE *filep = fopen(fileName, "a");
    if (filep != NULL) {
        fprintf(filep, "%s\n", message);
        fclose(filep);
        return 0;
    } else {
        return -1;
    } 
}