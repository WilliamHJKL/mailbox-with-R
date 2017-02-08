# mailbox-with-R
Analyzing email boxes with R and Rstudio

Simple R script that could extract data from a directory containing emails.
For the moment this script reads the emails in the directory, parses Sender, Receivers, Subjects and Timestamps.
It then creates a gexf files, allowing you to display a network in Gephi, for instance.

IP parsing and analysis, with filtering of local adresses.

Export to html.

Tested on OSX an Ubuntu.

# Example of generated graphs

Graph exported to Gephi
![](https://framapic.org/1GuGVF6DD7Gw/3ObZ5oMeD2Eb)

Stats on From: field
![](https://framapic.org/3xlIo9Faqpgz/Vl7xc3pidkpF)
![](https://framapic.org/xhb7PFWlwDXQ/Vlb0cOB7HhmY)



# Planned features and roadmap

- Nodes cleansing and clustering of nodes (similar entities)
- Text-mining of the mail content

# Known issues

Due to some misinterpretation of the filepath by Win7, the script doesn't seem to work for the moment on this configuration (see issues).



