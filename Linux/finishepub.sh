#!/bin/bash

isbn=$(sed -n 1p ./isbndata)
title=$(sed -n 1p ./metadata)
author=$(sed -n 2p ./metadata)
publisher=$(sed -n 's/.*; \(.*\),.*/\1/p' ./metadata)
lang=en
tags=$(sed -n 4p ./metadata)
date=$(date +%Y-%m-%dT%H:%M:%SZ)

echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<package xmlns=\"http://www.idpf.org/2007/opf\" prefix=\"rendition: http://www.idpf.org/vocab/rendition/#\" unique-identifier=\"pub-id\" version=\"3.0\">\n  <metadata xmlns:dc=\"http://purl.org/dc/elements/1.1/\">\n   <dc:identifier id=\"pub-id\">$isbn</dc:identifier>\n   <dc:title>$title</dc:title>\n   <dc:creator>$author</dc:creator>\n   <dc:publisher>$publisher</dc:publisher>\n   <dc:language>$lang</dc:language>\n   <dc:subject>$tags</dc:subject>\n   <dc:description>$tags</dc:description>\n   <meta content=\"cover_image\" name=\"cover\"/>\n   <meta property=\"dcterms:modified\">$date</meta>\n   <meta property=\"rendition:layout\">pre-paginated</meta>\n   <meta property=\"rendition:spread\">none</meta>\n </metadata>\n<manifest>" > ./bookroot/OEBPS/content.opf

cd ./bookroot/OEBPS/

for f in *.xhtml; do
filenum=$(echo "$f" | sed 's/[^0-9][^0-9]*\([0-9][0-9]*\).*/\1/g')
bgnum=$(cat "$f" | grep -o '\bbg\w*' | head -n1)
fontnum=$(cat "$f" | grep -o '\bff\w*' | head -n1)
fontfile=$(echo "$fontnum" | sed 's/^.//')
echo -e " <item id=\"page$filenum\" href=\"$f\" media-type=\"application/xhtml+xml\"/>" >> ./content.opf
echo -e " <item id=\"image-page$filenum\" href=\"$bgnum.svg\" media-type=\"image/svg+xml\"/>" >> ./content.opf
echo -e " <item id=\"$fontnum\" href=\"$fontfile.woff\" media-type=\"application/font-woff\"/>" >> ./content.opf
done

echo -e "<item id=\"base-min-css\" href=\"base.min.css\" media-type=\"text/css\"/>" >> ./content.opf
echo -e "<item id=\"mybook-css\" href=\"mybook.css\" media-type=\"text/css\"/>" >> ./content.opf
echo -e "<item id=\"cover_image\" href=\"cover.jpg\" media-type=\"image/jpeg\" properties=\"cover-image\"/>" >> ./content.opf
echo -e "<item id=\"nav\" href=\"nav.xhtml\" media-type=\"application/xhtml+xml\" properties=\"nav\"/>\n</manifest>\n<spine>" >> ./content.opf

for g in *.xhtml; do
pagenum=$(echo "$g" | sed 's/[^0-9][^0-9]*\([0-9][0-9]*\).*/\1/g')
pagedigit=$(echo "$g" | sed 's/[^0-9][^0-9]*\([0-9][0-9]*\).*/\1/g' | tail -c 2)
if [ "$pagedigit" == "0" ] || [ "$pagedigit" == "2" ] || [ "$pagedigit" == "4" ] || [ "$pagedigit" == "6" ] || [ "$pagedigit" == "8" ]; then
echo -e " <itemref idref=\"page$pagenum\"/>" >> ./content.opf
else
echo -e " <itemref idref=\"page$pagenum\"/>" >> ./content.opf
fi
done

echo -e "</spine>\n<guide>\n <reference type=\"cover\" title=\"Cover\" href=\"mybook0001.xhtml\"/>\n <reference type=\"text\" title=\"Text\" href=\"mybook0002.xhtml\"/>\n</guide>\n</package>" >> ./content.opf

cat ../../nav > ./nav.xhtml

sed -i 's/;unicode-bidi:bidi-override//g' base.min.css

echo -e "\nDone generating ebook files.\nCompiling your finished book...\n"

cd ../

zip -0Xq ./$isbn.epub mimetype && zip -Xr9Dq ./$isbn.epub * -x mimetype -x ./$isbn.epub && mv ./$isbn.epub ../$isbn.epub

echo -e "\nDone.\n"

cd ../

rm -f ./nav
rm -f ./isbndata
rm -f ./metadata
rm -f ./mybook.pdf
rm -rf ./bookroot

exit 0;
