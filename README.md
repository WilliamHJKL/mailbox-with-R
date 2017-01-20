# mailbox-with-R
Analyzing email boxes with R

Simple R script that could extract data from a directory containing emails.
For the moment this script reads the emails in the directory, parses Sender, receivers, subjects and timestamps.
It then creates a gexf files, allowing you to display a network in Gephi, for instance.

Tested on OSX.

# Planned features and roadmap

- Nodes cleansing and clusering
- Text-mining of the mail content
- IP parsing and analysis

# Knows issues

Due to some misinterpretation of the filepath by Win7, the script doesn't seem to work now on this configuration.

