#Installation des bibliothèques nécessaires
install.packages("tm.plugin.mail")
install.packages("tm")
install.packages("sqldf")
install.packages("tidyr")
install.packages("dplyr")
install.packages("rgexf")
install.packages("igraph")
library(sqldf)
library(tidyr)
library(dplyr)
library(rgexf)
library(igraph)
library(rgexf)
library(tm.plugin.mail)
#definition du répertoire de travail
#Sous OSX, cela marche bien mais sous Win7, le path est problématique à régler
setwd("/Users/maison/Documents/essai_mail")

#Si votre boite mail est un fichier mbox, il est nécessaire de transformer cette boite en liste de fichiers eml
#Décommenter les lignes ci-après et utiliser la fonction convert_mbox_eml
# mbf <- "nom_du_fichier_mbox"
# convert_mbox_eml(mbf, "efichier_eml")

#lecture des mail
library(tm)
maildir <- setwd("/Users/maison/Documents/essai_mail")
mailfiles <- dir(maildir, full.names=FALSE)
Encoding(mailfiles)  <- "UTF-8"
#On lit les mails un par un et on extrait les informations dont on a besoin
#Pour cela on créé la fonction readmsg qui extrait à la volée les expéditeurs, destinataires, sujets et horodatage

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
  # ci-dessous des essais infructueux de parser le texte du message
  #text1 <- grep("^Content-Transfer-Encoding: quoted-printable", l, value=TRUE)
  #text1 <- gsub("Content-Transfer-Encoding: quoted-printable", "", text1)
  #text1 <- tail(l, 3)[1]
  #text2 <- tail(l, 3)[2]
  #return(c(subj, date, text1, text2))
  #return(c(origin, dest, date))
  return(c(origin, dest, date, subj))
}
#Création du dataframe
mdf <- do.call(rbind, lapply(mailfiles, readmsg))
tableau <- as.data.frame(mdf)
#Le tableau est sale alors on ne récupère que les colonnes qui nous intéressent et on expurge les infos inutiles avec sqldf
library(sqldf)
tableau2 <- sqldf("select V1, V2, V3, V4 from tableau")
colnames(tableau2) <- c("Source", "Target", "Date", "Sujet")
#Quelques étapes de nettoyage des colonnes du tableau. Pour ce faire on passe par un tableau secondaire identique
tableau_temp <- tableau2
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
#Le tableau secondaire bien nettoyé devient le tableau pricipal
tableau<-tableau_temp
#Split des cellules à multiples valeurs avec tidyr : les destinataires multiples
#Contrairement à OpenRefine, tidyr complète automatiquement les cellules manquantes
tableau<-tableau %>% unnest(Target=strsplit(Target, ","))
#Là je remets les colonnes noeuds en premier pour que ce soit plus simple
tableau<-sqldf("select Source, Target, Date, Sujet from tableau")
#crée le fichier gexf
#simplification du tableau
#tableau$Source <- trimws(tableau$Source)
#tableau$Target <- trimws(tableau$Target)
reseau<-simplify(graph.data.frame(tableau, directed =TRUE))
#Création des noeuds du réseau
nodes_reseau <- data.frame(ID=c(1:vcount(reseau)), NAME=V(reseau)$name)
#Création des liens entre les noeuds
edges_reseau <- as.data.frame(get.edges(reseau, c(1:ecount(reseau))))
#écriture du réseau au format gexf, lisible dans Gephi
write.gexf(nodes = nodes_reseau, edges = edges_reseau, defaultedgetype = "directed", output ="reseau.gexf")

