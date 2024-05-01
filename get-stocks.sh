#!/bin/bash
#
# Fetches all small cap stocks from best Small cap MFs and list then based on frequency
#
# Author : Kumar Gaurav
# Date : 26th Sep 2021

mfsListLink="https://www.moneycontrol.com/mutual-funds/performance-tracker/returns/small-cap-fund.html" 

#fetch list of links to MFs

wget wget  --header="Accept: text/html" --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0" $mfsListLink -O mfsListLink.html -o logfile

echo "Downloaded Mf List page"

echo "">links.lst 
grep "robo_medium" mfsListLink.html>mfsListLink.lst

while read line
do
    link=`echo $line|cut -d'"' -f2`
    isLink=`echo $link |grep http`
    if [ "x${isLink}" != x ]
    then
        echo $link>>links.lst        
    fi    
done<mfsListLink.lst

echo "Collected link to each MFs page"

# traverse each link and fetch list of Stocks
if [ -f stock-name.lst ]
then
    #echo file is there
    mv rankedList.csv last-rankedList.csv
    echo "">rankedList.csv
    echo "">stock-name.lst
    echo "backed up last stock list"
else 
    echo no current stock file
fi  

while read mfLine
do
    isLink=`echo $mfLine |grep http`
    if [ "x${isLink}" != x ]
    then
        wget --header="Accept: text/html" --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0"  $mfLine -O stockList -o logfile
        grep stockpricequote stockList | grep port_right> stocks.lst
        while read stockListLine
        do
            name=`echo $stockListLine |cut -d'>' -f3| cut -d'<' -f1`
            code=`echo $stockListLine|tr ' ' '\n'|grep 'http'|cut -d'/' -f8|cut -d'"' -f1`
            wget --header="Accept: text/html" --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0"  "https://api.moneycontrol.com/mcapi/v1/stock/get-stock-price?scId=${code}&scIdList=${code}" -O price.txt 
            price=`cat price.txt|sed -e $'s/\",/\\\n/g'|grep lastPrice|cut -d':' -f2|cut -d'"' -f2`
            price=`echo ${price//,}`
            echo "Price :" $price
            if [ "x${name}" != x ]
            then
                echo $name#$price>>stock-name.lst
            fi 
            
        done<stocks.lst
    fi  
    
done<links.lst

echo "New Stock list generated"

cp stock-name.lst tmp.lst
sort tmp.lst>sorted-tmp.lst

echo "sorted list"

echo "Ranking stock"

tmpStockName=`head -1 sorted-tmp.lst`;
count=0
echo "Repeatation, Stock Name">rankedList.csv
while read stock
do
    if [ "$tmpStockName" == "$stock" ]
    then
        count=`echo $count + 1|bc`
    else
       name=`echo $tmpStockName|cut -d'#' -f1`
       price=`echo $tmpStockName|cut -d'#' -f2`
       echo $count,\"$name\",$price>>rankedList.csv
       tmpStockName=`echo $stock`
       count=`echo 1`
    fi
done<sorted-tmp.lst

echo "cleaning up"
rm *html
rm *lst
rm logfile
rm logfile
echo "Done"

