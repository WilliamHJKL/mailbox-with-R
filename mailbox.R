#Install libraries
source("install_packages.R")
#load libraries
library("NLP")
library("tm")
library("tm.plugin.mail")
library("proto")
library("gsubfn")
library("DBI")
library("RSQLite")
library("sqldf")
library("tcltk")
library("RColorBrewer")
library("wordcloud")
library("stringi")
library("xtable")
library("htmlTable")
library("R2HTML")
library("date")
library("lubridate")
library("ggplot2")
library("openssl")
library("httr")
library("rgeolocate")
library("gpclib")
library("sp")
library("maptools")
library("rgdal")
library("gridExtra")
library("EML")
library("SnowballC")
library("rgexf")
library("igraph")
library("tidyr")
#Setup working directory
#With OSX, it does work but setting up a path under Win7 can be a pain in the a.s
maildir <- setwd("YOUR_PATH_TO_THE_MAILFILES")

#If you have a mailbox file instead of eml files
#Uncomment the following lines to convert the mb file to a list of eml files
# mbf <- "mailbox_filename"
# convert_mbox_eml(mbf, "efichier_eml")

#prepare mail reading
library(tm)
mailfiles <- dir(maildir, full.names=TRUE)
Encoding(mailfiles)  <- "UTF-8"
mailfiles2 <- mailfiles

#Read mails one by one via a function "readmsg" that parses senders, subjects, timestamps and receivers

readmsg <- function(fname) {
  l <- readLines(fname) 
  origin <- grep('^From:', l, value=TRUE)
  origin < gsub("From:", "", origin)
  dest <- grep("^To:", l, value=TRUE)
  dest <- gsub("To:", "", dest)
  date <- grep("^Date:", l, value=TRUE)
  date <- gsub("Date:", "", date)
  subj <- grep("^Subject:", l, value=TRUE)
  subj <- gsub("Subject:", "", subj)
  return(c(origin, dest, date, subj))
}
#Creation of the dataframe
mdf <- do.call(rbind, lapply(mailfiles, readmsg))
tableau <- as.data.frame(mdf)
#Table is messy, so we only collect the useful columns
tableau <- tableau[1:4]
colnames(tableau) <- c("Source", "Target", "Date", "Sujet")
#Some cleansing on the table
tableau_temp <- tableau
tableau_temp$Target <- gsub('.*\\"',"", tableau_temp$Target)
tableau_temp$Target <- gsub("*>.*", "", tableau_temp$Target)
tableau_temp$Target <- gsub(".*<","", tableau_temp$Target)
tableau_temp$Target <- casefold(tableau_temp$Target, upper = FALSE)
tableau_temp$Source <- gsub("*>.*", "", tableau_temp$Source)
tableau_temp$Source <- gsub(".*<","", tableau_temp$Source)
tableau_temp$Source <- gsub("\"","", tableau_temp$Source)
tableau_temp$Target <- gsub("\"","", tableau_temp$Target)
tableau_temp$Source <- gsub("From: ","", tableau_temp$Source)
tableau_temp$Source <- trimws(tableau_temp$Source)
tableau_temp$Target <- trimws(tableau_temp$Target)
#temporary table becomes the main one
tableau<-tableau_temp
#Split multivalued cells with tidyr 
tableau<-tableau %>% unnest(Target=strsplit(Target, ","))
#reorder columns
tableau <- tableau[c("Source", "Target", "Date", "Sujet")]
#delete empty rows
tableau <- tableau[!apply(tableau, 1, function(x) any(x=="")),]
#creation of the gexf file
#simplification of the table
reseau<-simplify(graph.data.frame(tableau, directed =TRUE))
#creation of nodes
nodes_reseau <- data.frame(ID=c(1:vcount(reseau)), NAME=V(reseau)$name)
#creation of edges
edges_reseau <- as.data.frame(get.edges(reseau, c(1:ecount(reseau))))
#énow comes the gexf file
write.gexf(nodes = nodes_reseau, edges = edges_reseau, defaultedgetype = "directed", output ="reseau.gexf")

# A few stats using ggplot and sqldf
comptage_exp <- sqldf('select Source, count(*) from tableau where Source is not null group by Source ORDER BY count(*) DESC')
names(comptage_exp)[names(comptage_exp)=="count(*)"] <- "Nombre"
comptage_dest <- sqldf('select Target, count(*) from tableau where Target is not null group by Target ORDER BY count(*) DESC')
names(comptage_dest)[names(comptage_dest)=="count(*)"] <- "Nombre"

# Graph based on From field
g_compt_exp <- ggplot(comptage_exp, aes(x = reorder(Source, Nombre), y= Nombre, fill = Nombre))
g_compt_exp + geom_bar(stat = "identity") + coord_flip() + ggtitle("Exp/nombre d'envois") + xlab("Expéditeurs") + ylab("Envois") + theme(plot.title = element_text(size = 16, face = "bold", family = "Calibri"), axis.title=element_text(face="bold", size=8, color="black"))

# Graph based on To field
g_compt_dest <- ggplot(comptage_dest, aes(x = reorder(Target, Nombre), y= Nombre, fill = Nombre))
g_compt_dest + geom_bar(stat = "identity") + coord_flip() + ggtitle("Dest/nombre d'envois") + xlab("Expéditeurs") + ylab("Envois") + theme(plot.title = element_text(size = 16, face = "bold", family = "Calibri"), axis.title=element_text(face="bold", size=8, color="black"))

# Graph based on Domain
domain_exp <- separate(data = comptage_exp, col = Source, into = c("ID_exp", "Domain"), sep = "@")
domain_exp<- sqldf('select Domain, count(*) from domain_exp where Domain is not null group by Domain ORDER BY count(*) DESC')
names(domain_exp)[names(domain_exp)=="count(*)"] <- "Nombre"
g_domain_exp <- ggplot(domain_exp, aes(x = reorder(Domain, Nombre), y= Nombre, fill = Nombre))
g_domain_exp + geom_bar(stat = "identity") + coord_flip() + ggtitle("Domain/nombre d'envois") + xlab("Domaine") + ylab("Envois") + theme(plot.title = element_text(size = 16, face = "bold", family = "Calibri"), axis.title=element_text(face="bold", size=8, color="black"))

#Playing with dates - add some stats on them. Contribution of @arkel_

readmsg <- function(fname){
  l <- readLines(fname)
  date <- unlist(l)
  #date <- grep("Date", l, value=TRUE)
  #date <- stri_extract_all_regex(date, "[0-9]{1,2}\\s[A-Za-z]{3}\\s[0-9]{4}")
  #date <- grep("[0-9]{1,2}\\s[A-Za-z]{3}\\s[0-9]{4}", date, value=TRUE)
  return(c(date))
}
mdf2 <- do.call(rbind, lapply(mailfiles2, readmsg))
tableau_date1 <- as.data.frame(mdf2)
Sys.setlocale("LC_ALL", "en_US.UTF-8")
tableau_date1$V1 <- as.Date(tableau_date1$V1, format="%d %B %Y")
tableau_date1$V1 <- format(tableau_date1$V1, "%Y/%m")
tableau_date2 <- sqldf("select count(V1) as nb, V1 as date from tableau_date1 group by date order by nb desc")

#Playing on stats with IP adresses when available. Elimination of local and subnet IPs
#We only want to keep an eye on Internet IP
#Contribution of @Arkel_

readmsg <- function(fname){
  l <- readLines(fname)
  ip <- grep("[0-9]", l, value=TRUE)
  ip <- stri_extract_all_regex(ip, "[0-9]{1,3}([.][0-9]{1,3}){3}")
  ip <- grep("[0-9]{1,3}([.][0-9]{1,3}){3}", ip, value=TRUE)
  ip <- gsub("127.0.0.1", "", ip)
  ip <- gsub("172\\.(1[6-9]|2[0-9]|3[0-1])([.][0-9]{1,3}){2}", "", ip)
  ip <- gsub("^192.168", "", ip)
  ip <- gsub("^10([.][0-9]{1,3}){3}", "", ip)
  return(c(ip))
}
mdf3 <- do.call(rbind, lapply(mailfiles2, readmsg))
tableau_ip1 <- as.data.frame(mdf3)
tableau_ip2 <- data.frame(ip=character(), stringsAsFactors=FALSE)
tableau_ip2 <- sqldf("select count(V3) as nb, V3 as ip from tableau_ip1 group by ip order by nb desc")

#Let's plot IP adresses on a map!
#Contrib by @Arkel_

y = 0
file <- system.file("extdata", "GeoLite2-Country.mmdb", package="rgeolocate")
country_ip1 <- data.frame(mynames=character(), stringsAsFactors=FALSE)
while(y < nrow(tableau_ip2)){
  y = y+1
  print(maxmind(tableau_ip2[y,2], file, c("country_name")))
  country_ip1[y,1] <- (maxmind(tableau_ip2[y,2], file, c("country_name")))
}
country_ip2 <- sqldf("select count(mynames) as nb, mynames as pays from country_ip1 group by pays order by nb desc")

worldmap <- readShapeSpatial(file.choose(),proj4string=CRS("+proj=longlat"))
plot(worldmap)

#We generate a HTML report for all the stats
#Contrib by @Arkel_

HTMLStart(outdir = maildir, file="tableau", extension="html",echo=FALSE, HTMLframe = TRUE)
HTML.title(sprintf('Analysis of %s mails', length(mailfiles2)), HR=1)
HTML.title(sprintf("Count per date of %s mails", nrow(tableau_date1)), HR=3)
p <- ggplot(data=tableau_date2, aes(x=date, y=nb)) + geom_bar(stat="identity", fill="steelblue") + geom_text(aes(label=nb), color="white", size=3, vjust=2) + theme(axis.text.x=element_text(angle=90,hjust=1,vjust=0.5))


HTMLplot(Width=1000)
HTML.title(sprintf("Count per IP on %s mails", nrow(tableau_ip1)), HR=3)
data.frame(country_ip2)

HTMLStop()
