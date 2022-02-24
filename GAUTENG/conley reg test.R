library(conleyreg)
library(foreign)
mydata <- read.dta("/Users/williamviolette/southafrica/Generated/GAUTENG/reg_test.dta")
dim(mydata)
head(mydata)

testreg.lm -> lm(formula = for + post, data= mydata)
