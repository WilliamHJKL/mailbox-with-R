# mailbox-with-R
Analyzing email boxes with R

Simple R script that could extract data from a directory containing emails.
For the moment this script reads the emails in the directory, parses Sender, Receivers, Subjects and Timestamps.
It then creates a gexf files, allowing you to display a network in Gephi, for instance.

Tested on OSX.

# Example of a generated graph

![](https://framapic.org/1GuGVF6DD7Gw/3ObZ5oMeD2Eb)

# Planned features and roadmap

- Nodes cleansing and clustering of nodes (similar entities)
- Text-mining of the mail content
- IP parsing and analysis

# Known issues

Due to some misinterpretation of the filepath by Win7, the script doesn't seem to work for the moment on this configuration (see issues).



