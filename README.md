# `GTFM` - get the *fine* manual   

SYNOPSIS
--------

`GTFM` [`-v`|`-h`|`-l`]  
`GTFM` WIKI  

DESCRIPTION
-----------

Download documentation from git and the web for
offline reading.  

If `GTFM` is executed without any commandline options,
all wikis defined in `GTFM_CONFIG`, will get updated
or downloaded and copied to `GTFM_TARGET_DIR`.  

If a name of a WIKI is the last argument to `GTFM`,
only that WIKI will  get updated or downloaded and 
copied to `GTFM_TARGET_DIR`.  

See the default `GTFM_CONFIG` (*doclist.ini*) for
availbe configuration. 

OPTIONS
-------

`-v`  
Show version and exit.

`-h`  
Show help and exit.

`-l`  
Prints a list of all wikis defined in `GTFM_CONFIG`.

ENVIRONMENT
-----------
GTFM_CONFIG defaults to *$THIS_DIR/doclist.ini*  
configuration file always read by the script.

GTFM_TARGET_DIR defaults to *$PWD/trg*  
General target directory where to store documentation.
Can either be set with a ENVIRONMENT_VARIALBE or in
`GTFM_CONFIG`. It is possible to specify different 
target direcories for different wikis in `GTFM_CONFIG`.  

GTFM_SOURCE_DIR defaults to *$PWD/src*  
General directory where to download documentation
source. Can either be set with a ENVIRONMENT_VARIALBE 
or in `GTFM_CONFIG`.  

DEPENDENCIES
------------

html2text  
git  
