# PDF2HTMLEX-EPUB3FIXED
A couple of bash scripts for generating a fixed-page EPUB3 from PDF2HTMLEX output

## Install:

1. Download the two scripts for either OSX or Linux, put them in a folder in your PATH, chmod them  a+x
2. Sign up for API access at ISBNdb, generate a key, and edit the key variable in convertepub.sh
3. Install pdf2htmlEX and all of its dependencies
4. Install curl and all of its dependencies
5. Install imagemagick **v6.9 or higher** and all of its dependencies ***
6. Install ttfautohint and all of its dependencies

## Usage:

1. Run convertepub.sh from a folder with **ONE** pdf in it of at least two pages, enter data when prompted
2. Edit the chapter titles and page links in the 'nav' file for your table of contents desires
3. Run finishepub.sh

The OSX scripts should theoretically work on any flavor of BSD Unix, they are BSD sed and bash v3 friendly.  The Linux scripts were tested on Ubuntu 14.04.  

If your PDF is not an actual book with a valid ISBN, that's not a big deal, just tell the ISBN scraper 'no' when it asks if it matched your book.  The 'metadata' file will be populated with default values after convertepub.sh finishes, you can edit the placeholder values before running finishepub.sh

*** On Ubuntu 14.04, the included Imagemagick is too old and the version of poppler is borderline too old, if you need to update those and don't want to build them from source, run...

1. sudo add-apt-repository ppa:isage-dna/imagick
2. sudo add-apt-repository ppa:alexis-via/poppler-utils-backport
3. sudo apt-get update
4. sudo apt-get upgrade imagemagick
5. sudo apt-get upgrade libpoppler-glib8
6. sudo apt-get upgrade poppler-utils

Those repositories have the bare minimum versions for these scripts.


