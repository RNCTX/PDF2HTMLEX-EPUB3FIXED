#!/bin/bash

isbn_key=replaceme

echo -e "Put a PDF with at least two pages in the folder\nyou ran this file from, by itself, then\ntype 'go' to continue... \n\n"
read go

echo -e "\n"

cp ./*.pdf ./mybook.pdf
pdfimages -l 2 -f 2 mybook.pdf ./
hres=$(identify -format "%[fx:h]" ./-000.pbm)
vres=$(identify -format "%[fx:w]" ./-000.pbm)
acw=$(identify -format "%[fx:w/72]" -precision 3 mybook.pdf[2])
ach=$(identify -format "%[fx:h/72]" -precision 3 mybook.pdf[2])
width=$(echo "scale=2; ($acw * 100)/100" | bc)
height=$(echo "scale=2; ($ach * 100)/100" | bc)
dpi=$(echo "scale=0; $hres/$height" | bc)

echo -e "Google your device make/model specs (ex: "iPad Air2 resolution").\nAt this point you need to input the desired output\nsize of your ebook based on your device screen size.\n"

echo -e "\nNow enter your device's VERTICAL resolution: (the larger number)\n"
read vdpi
echo -e "\nNow enter your device's HORIZONTAL resolution: (the smaller number)\n"
read hdpi

echo -e "\nYour input file has the following dimensions:\n"
echo -e "Page width: $width inches\nPage height: $height inches\nScanned resolution: $dpi dpi\n\n"

rm -f ./-000.pbm

sleep 2

echo -e "Here we go, this may take awhile depending on your file's size.\nNo further input will be required until the conversion is\nfinished. Minor errors about fonts can be safely ignored...\n"

sleep 2

pdf2htmlEX --embed-css 0 --embed-font 0 --embed-image 0 --embed-javascript 0 --external-hint-tool=ttfautohint --embed-outline 0 --split-pages 1 --bg-format svg --hdpi $dpi --vdpi $dpi --fit-width $hdpi --fit-height $vdpi --page-filename mybook%04d.page --css-filename mybook.css mybook.pdf

for f in *.page; do
echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<html xmlns:epub=\"http://www.idpf.org/2007/ops\"\n    xmlns=\"http://www.w3.org/1999/xhtml\">\n<head>\n    <meta charset=\"UTF-8\"/>\n    <meta name=\"generator\" content=\"pdf2htmlEX\"/>\n    <link rel=\"stylesheet\" type=\"text/css\" href=\"base.min.css\"/>\n    <link rel=\"stylesheet\" type=\"text/css\" href=\"mybook.css\"/>\n    <meta name=\"viewport\" content=\"width=$hdpi, height=$vdpi\"/>\n    <title></title>\n</head>\n<body>\n    <div id=\"page-container\">\n" >> tmpfile
cat "$f" >> tmpfile
echo -e "    </div>\n  </body>\n</html>" >> tmpfile
mv tmpfile "$f"
done

for g in *.page; do
mv "$g" "`basename "$g" .page`.xhtml"
done

for h in *.svg; do
sed -i 's/version="1.2"/version="1.1"/g' "$h"
done

rm -f *.outline
rm -f pdf2htmlEX-64x64.png
rm -f fancy.min.css
rm -f pdf2htmlEX.min.js
rm -f compatibility.min.js
rm -f mybook.html

mkdir ./bookroot/
mkdir ./bookroot/META-INF/
mkdir ./bookroot/OEBPS/

mv *.css ./bookroot/OEBPS/
mv *.woff ./bookroot/OEBPS/
mv *.xhtml ./bookroot/OEBPS/
mv *.svg ./bookroot/OEBPS/

echo -n "application/epub+zip" > ./bookroot/mimetype

echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<container version=\"1.0\" xmlns=\"urn:oasis:names:tc:opendocument:xmlns:container\">\n  <rootfiles>\n    <rootfile full-path=\"OEBPS/content.opf\"\n    media-type=\"application/oebps-package+xml\"/>\n  </rootfiles>\n</container>" > bookroot/META-INF/container.xml

echo -e "\nHome stretch... Now I need input\nto generate the book metadata.\n"
echo -e "Give me the book's title:\n"
read title
echo -e "\nGive me the year it was published:\n"
read year
echo -e "\nSearching ISBNdb for book info...\n"

lower=$(echo "$title" | tr "[:upper:]" "[:lower:]")
search_title=$(echo "$lower" | tr -s " " | tr " " "_")

curl -H "Accept: application/xml" -H "Content-Type: application/xml" -X GET "http://isbndb.com/api/books.xml?access_key=$isbn_key&index1=title&results=subjects&value1=$search_title" > search.xml

xmllint --noent --xpath '//*[contains(text(),'$year')]/..' search.xml > results.xml 2>&1

isbnnum=$(cat ./results.xml | sed -n 's/.*isbn13="\(.*\)">.*/\1/p')
if [ -n "$isbnnum" ]; then
    echo -e "$isbnnum" > isbndata
else
    rand=$(openssl rand -hex 5)
    echo -e "987$rand" > isbndata
fi

rm -f ./search.xml

echo -e "\nI found the following based on your input...\n\n"

sed -i -e 's/<[^>]*>//g' -e '/^$/d' results.xml

opfdata=$(awk '{ for ( i=1; i <= NF; i++) {   sub(".", substr(toupper($i),1,1) , $i)  }  print }' results.xml)

sed -i -e 's/<[^>]*>//g' -e '/^$/d' results.xml
echo -e "$opfdata" > ./metadata

isbndbresult=$(awk '{print $1}' metadata)
 if [ "$isbndbresult" == "XPath" ]; then
    echo -e "\nI did not find any title data, 'metadata' is populated\nwith defaults that must be fixed in your text editor." && sed -i '' '1d' metadata && echo -e "Title Goes Here\nAuthor Here\nCity of Publication Here ; Publisher Name Here, YEAR.\nCategory Tag Here" > metadata
 else
    cat metadata && echo -e "\n" && sleep 2 && read -p "Does this look okay? [y/n]" match
    if [ "$match" = "y" ]; then
     echo -e "\nOkay then, edit your TOC in the file 'nav'\nand then go ahead and run the next script,\nfinishepub.sh.\n"
    else
     echo -e "\nIf I did not find the right match for your book data, you need\nto fix the file 'opfdata' in this folder. Open it in\nyour text editor and replace the wrong data with\ncorrect data before running finishepub.sh.\n"
   fi
  fi

pdfimages -f 1 -l 1 mybook.pdf ./ && convert ./-000.ppm ./cover.jpg && mv cover.jpg ./bookroot/OEBPS && rm -f ./-000.ppm

booktitle=$(sed -n 1p ./metadata)
echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<html xmlns:epub=\"http://www.idpf.org/2007/ops\"\n   xmlns=\"http://www.w3.org/1999/xhtml\">\n<head>\n <title>$booktitle</title>\n</head>\n<body>\n <nav epub:type=\"toc\" id=\"toc\">\n  <ol>\n    <li>\n     <a href=\"mybook0001.xhtml\">Chapter 1 Like This</a>\n    </li>\n    <li>\n     <a href=\"mybook0002.xhtml\">Chapter 2 Like This</a>\n    </li>\n  </ol>\n</nav>\n <nav epub:type=\"landmarks\">\n  <ol>\n   <li>\n     <a epub:type=\"cover\" href=\"mybook0001.xhtml\">Cover</a>\n   </li>\n   <li>\n    <a epub:type=\"bodymatter\" href=\"mybook0002.xhtml\">Bodymatter</a>\n   </li>\n  </ol>\n </nav>\n <nav epub:type=\"page-list\" hidden=\"\">\n  <ol>" > ./nav

cd ./bookroot/OEBPS/

for j in *.xhtml; do
filenumber=$(echo "$j" | sed 's/[^0-9][^0-9]*\([0-9][0-9]*\).*/\1/g')
echo -e "   <li>\n    <a href=\"$j\">$filenumber</a>\n   </li>" >> ../../nav
done

echo -e "  </ol>\n </nav>\n</body>\n</html>" >> ../../nav

cd ../../

rm -f ./results.xml

exit 0;
