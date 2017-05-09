#### Set R working directory
setwd("C:/Temp/R/")
#### Use install.packages("Hmisc"), install.packages("haven") if necessary
library(haven)
library(Hmisc)
#### Read all .sas7bdat files from working directory. Set factor, levels, label(s).
CARS_M <- read_sas("CARS_M.sas7bdat")
CLASS_M <- read_sas("CLASS_M.sas7bdat")
GNG_M <- read_sas("GNG_M.sas7bdat")
CARS_M$ORIGIN <- factor(CARS_M$ORIGIN, c("Asia", "Europe", "USA"), exclude = "")
levels(CARS_M$ORIGIN) <- c("ASIA", "EUROPE", "USA")
label(CARS_M$ORIGIN) <- "Origin"
CARS_M$CYLIND <- factor(CARS_M$CYLIND, c(3, 4, 5, 6, 8, 10, 12), exclude = "")
levels(CARS_M$CYLIND) <- c("3 cylinders", "4 cylinders", "5 cylinders", "6 cylinders", "8 cylinders", "10 cylinders", "12 cylinders")
label(CARS_M$CYLIND) <- "Cylinders"
CLASS_M$SEX <- factor(CLASS_M$SEX, c("M", "F"), exclude = "")
levels(CLASS_M$SEX) <- c("Male", "Female")
label(CLASS_M$SEX) <- "Sex"
