# Dokumentation af system til opdeling af store JSON filer

## Indledning
Dette dokument beskriver hvordan systemet til opdeling af JSON file i mindre filer. Filerne bliver dannet ved filudtræk og det er forudsat at det er de alle har den samme struktur. Resultatet af opdelingen bliver en samling JSON filer, som har samme struktur, som den oprindelige JSON fil og kan derfor bruges til kontrol af JSON syntaks og validerings op i mod JSON skamaer.

## JSON Input format
Det forudsættes at JSON filen har følgende struktur

    {
        "Name1List": [{},{},{},..{}],
        "Name2List": [{},{},{},..{}],
        "Name3List": [{},{},{},..{}],
        ...
        "NameNList": [{},{},{},..{}]
     }

## Program position.pl
Dette program skanner den JSON filen og finder start- og slutpositionerne for hvert object.
Resultatet skrives i csv fil: jsonobject.csv
Programmet danner også en fil listname.csv, som indeholder de lister, som der findes i filen.


Aktiveres med følgende kald

`position.pl --jsonfile=<filename> --jsonobject=<filename> --listname=<filename>`

## Program generate.pl
Dette program bruger to input filer fra position.pl til at danne folder med JSON filer

Aktiveres med følgende kald

`generate.pl --jsonfile=<filename>  -jsonobject=<filename> --listname=<filename> --filesize=<filesize(MB)> --prefix=<prefix> --directory=<directory name>`
