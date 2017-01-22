#Install libraries
install.packages("tm.plugin.mail")
install.packages("tm")
install.packages("sqldf")
install.packages("tidyr")
install.packages("dplyr")
install.packages("rgexf")
install.packages("igraph")
install.packages("ggplot2")
install.packages("lubridate")
library(sqldf)
library(tidyr)
library(dplyr)
library(rgexf)
library(igraph)
library(rgexf)
library(tm.plugin.mail)
library(ggplot2)
library(lubridate)
#Setup working directory
#With OSX, it does work but setting up a path under Win7 can be a pain in the a.s
setwd("/Users/maison/Documents/essai_mail")

#If you have a mailbox file instead of eml files
#Uncomment the following lines to convert the mb file to a list of eml files
# mbf <- "nom_du_fichier_mbox"
# convert_mbox_eml(mbf, "efichier_eml")

#read mails
library(tm)
maildir <- setwd("/Users/maison/Documents/essai_mail")
mailfiles <- dir(maildir, full.names=FALSE)
Encoding(mailfiles)  <- "UTF-8"
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
  # some lousy test to parse text in mail but iy doesn't work for the moment
  #text1 <- grep("^Content-Transfer-Encoding: quoted-printable", l, value=TRUE)
  #text1 <- gsub("Content-Transfer-Encoding: quoted-printable", "", text1)
  #text1 <- tail(l, 3)[1]
  #text2 <- tail(l, 3)[2]
  #return(c(subj, date, text1, text2))
  #return(c(origin, dest, date))
  return(c(origin, dest, date, subj))
}
#Creation of the dataframe
mdf <- do.call(rbind, lapply(mailfiles, readmsg))
tableau <- as.data.frame(mdf)
#Table is messy, so we collect only the useful columns
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



