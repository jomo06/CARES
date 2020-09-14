### Assembles PPP data for further analysis
### kbmorales@protonmail.com

# For R users

if (!require(devtools)) install.packages('devtools')
devtools::install_github("kbmorales/PPP")

# Note: this script will download over 600MB of data into a 'data-raw'
# folder in your home directory.

# It will prompt you which version of the data you'd like to use:
# 1 is the latest data release: 2020-08-08
# 2 is the first data release: 2020-07-06

ppp_df = PPP::ppp_assemble()
