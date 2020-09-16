### Assembles PPP data for further analysis
### kbmorales@protonmail.com

# For R users
# Note: devtools throw a warning for you to install Rtools if you don't have it
# already, but Rtools is not required to install or run this package. The
# warning can safely be ignored.

if (!require(devtools)) install.packages('devtools')
devtools::install_github("kbmorales/PPP")

# Note: this script will download over 600MB of data into a 'data-raw'
# folder in your home directory.

# It will prompt you which version of the data you'd like to use, or you can
# specify the version parameter as one of the following:
# 1 is the latest data release: 2020-08-08
# 2 is the first data release: 2020-07-06

ppp_df = PPP::ppp_assemble()
