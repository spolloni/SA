
# install.packages("matchingR")
# install.packages("reprow")
# install.packages("plm")
# install.packages("lmtest")
# install.packages("multiwayvcov")

library(lfe)
library(conleyreg)
library(foreign)
library(tidyverse)
library(plm)
library(lmtest)
library(multiwayvcov)


set.seed(12)

mydata <- read.dta("/Users/williamviolette/southafrica/Generated/GAUTENG/reg_test.dta")
names(mydata)[names(mydata) == "for"] <- "forout"

uniqueset<-unique(mydata["id"])
uniquedf <- data.frame(uniqueset)
id <-uniquedf[sample(nrow(uniquedf),2000), ]
id <-data.frame(id)
subset<-merge(x=mydata,y=id,by =c("id"))

id <-uniquedf[sample(nrow(uniquedf),4000), ]
id <-data.frame(id)
subset2<-merge(x=mydata,y=id,by=c("id"))

### FULL DATASET ( THESE RESULTS MATCH STATA )
testreg2 <- felm(forout ~ post + proj_C + proj_C_con + proj_C_post + proj_C_con_post + s1p_a_1_C + s1p_a_1_C_con +s1p_a_1_C_post +s1p_a_1_C_con_post +s1p_a_2_C +s1p_a_2_C_con+ s1p_a_2_C_post+ s1p_a_2_C_con_post +s1p_a_3_C +s1p_a_3_C_con +s1p_a_3_C_post+ s1p_a_3_C_con_post +s1p_a_4_C+ s1p_a_4_C_con +s1p_a_4_C_post+ s1p_a_4_C_con_post+ s1p_a_5_C +s1p_a_5_C_con +s1p_a_5_C_post +s1p_a_5_C_con_post+ s1p_a_6_C +s1p_a_6_C_con +s1p_a_6_C_post +s1p_a_6_C_con_post+ s1p_a_7_C +s1p_a_7_C_con +s1p_a_7_C_post +s1p_a_7_C_con_post +s1p_a_8_C +s1p_a_8_C_con +s1p_a_8_C_post +s1p_a_8_C_con_post
 | 0 | 0 | cluster_joined, data=mydata)
summary(testreg2)

testreg2 <- lm(forout ~ post + proj_C + proj_C_con + proj_C_post + proj_C_con_post + s1p_a_1_C + s1p_a_1_C_con +s1p_a_1_C_post +s1p_a_1_C_con_post +s1p_a_2_C +s1p_a_2_C_con+ s1p_a_2_C_post+ s1p_a_2_C_con_post +s1p_a_3_C +s1p_a_3_C_con +s1p_a_3_C_post+ s1p_a_3_C_con_post +s1p_a_4_C+ s1p_a_4_C_con +s1p_a_4_C_post+ s1p_a_4_C_con_post+ s1p_a_5_C +s1p_a_5_C_con +s1p_a_5_C_post +s1p_a_5_C_con_post+ s1p_a_6_C +s1p_a_6_C_con +s1p_a_6_C_post +s1p_a_6_C_con_post+ s1p_a_7_C +s1p_a_7_C_con +s1p_a_7_C_post +s1p_a_7_C_con_post +s1p_a_8_C +s1p_a_8_C_con +s1p_a_8_C_post +s1p_a_8_C_con_post
, data=mydata)
summary(testreg2)


### SUBSET: Similar coefficients 

testreg1 <- lm(forout ~ post + proj_C + proj_C_con + proj_C_post + proj_C_con_post  + s1p_a_1_C + s1p_a_1_C_con +s1p_a_1_C_post +s1p_a_1_C_con_post +s1p_a_2_C +s1p_a_2_C_con+ s1p_a_2_C_post+ s1p_a_2_C_con_post +s1p_a_3_C +s1p_a_3_C_con +s1p_a_3_C_post+ s1p_a_3_C_con_post +s1p_a_4_C+ s1p_a_4_C_con +s1p_a_4_C_post+ s1p_a_4_C_con_post+ s1p_a_5_C +s1p_a_5_C_con +s1p_a_5_C_post +s1p_a_5_C_con_post+ s1p_a_6_C +s1p_a_6_C_con +s1p_a_6_C_post +s1p_a_6_C_con_post+ s1p_a_7_C +s1p_a_7_C_con +s1p_a_7_C_post +s1p_a_7_C_con_post +s1p_a_8_C +s1p_a_8_C_con +s1p_a_8_C_post +s1p_a_8_C_con_post
, data=subset)
summary(testreg1)

testreg1 <- felm(forout ~ post + proj_C + proj_C_con + proj_C_post + proj_C_con_post + s1p_a_1_C + s1p_a_1_C_con +s1p_a_1_C_post +s1p_a_1_C_con_post +s1p_a_2_C +s1p_a_2_C_con+ s1p_a_2_C_post+ s1p_a_2_C_con_post +s1p_a_3_C +s1p_a_3_C_con +s1p_a_3_C_post+ s1p_a_3_C_con_post +s1p_a_4_C+ s1p_a_4_C_con +s1p_a_4_C_post+ s1p_a_4_C_con_post+ s1p_a_5_C +s1p_a_5_C_con +s1p_a_5_C_post +s1p_a_5_C_con_post+ s1p_a_6_C +s1p_a_6_C_con +s1p_a_6_C_post +s1p_a_6_C_con_post+ s1p_a_7_C +s1p_a_7_C_con +s1p_a_7_C_post +s1p_a_7_C_con_post +s1p_a_8_C +s1p_a_8_C_con +s1p_a_8_C_post +s1p_a_8_C_con_post
 | 0 | 0 | cluster_joined, data=subset)
summary(testreg1)

ptm <- proc.time()
cr1 <- conleyreg(forout ~ post +  proj_C + proj_C_con + proj_C_post + proj_C_con_post + s1p_a_1_C + s1p_a_1_C_con +s1p_a_1_C_post +s1p_a_1_C_con_post +s1p_a_2_C +s1p_a_2_C_con+ s1p_a_2_C_post+ s1p_a_2_C_con_post +s1p_a_3_C +s1p_a_3_C_con +s1p_a_3_C_post+ s1p_a_3_C_con_post +s1p_a_4_C+ s1p_a_4_C_con +s1p_a_4_C_post+ s1p_a_4_C_con_post+ s1p_a_5_C +s1p_a_5_C_con +s1p_a_5_C_post +s1p_a_5_C_con_post+ s1p_a_6_C +s1p_a_6_C_con +s1p_a_6_C_post +s1p_a_6_C_con_post+ s1p_a_7_C +s1p_a_7_C_con +s1p_a_7_C_post +s1p_a_7_C_con_post +s1p_a_8_C +s1p_a_8_C_con +s1p_a_8_C_post +s1p_a_8_C_con_post
, data=subset, dist_cutoff=500, lat="x", lon="y", unit="id", time="post", sparse=TRUE)
cr1
proc.time() - ptm
# 2k - 17sec



testreg2 <- lm(forout ~ post + proj_C + proj_C_con + proj_C_post + proj_C_con_post + s1p_a_1_C + s1p_a_1_C_con +s1p_a_1_C_post +s1p_a_1_C_con_post +s1p_a_2_C +s1p_a_2_C_con+ s1p_a_2_C_post+ s1p_a_2_C_con_post +s1p_a_3_C +s1p_a_3_C_con +s1p_a_3_C_post+ s1p_a_3_C_con_post +s1p_a_4_C+ s1p_a_4_C_con +s1p_a_4_C_post+ s1p_a_4_C_con_post+ s1p_a_5_C +s1p_a_5_C_con +s1p_a_5_C_post +s1p_a_5_C_con_post+ s1p_a_6_C +s1p_a_6_C_con +s1p_a_6_C_post +s1p_a_6_C_con_post+ s1p_a_7_C +s1p_a_7_C_con +s1p_a_7_C_post +s1p_a_7_C_con_post +s1p_a_8_C +s1p_a_8_C_con +s1p_a_8_C_post +s1p_a_8_C_con_post
, data=subset2)
summary(testreg2)
testreg2 <- felm(forout ~ post + proj_C + proj_C_con + proj_C_post + proj_C_con_post + s1p_a_1_C + s1p_a_1_C_con +s1p_a_1_C_post +s1p_a_1_C_con_post +s1p_a_2_C +s1p_a_2_C_con+ s1p_a_2_C_post+ s1p_a_2_C_con_post +s1p_a_3_C +s1p_a_3_C_con +s1p_a_3_C_post+ s1p_a_3_C_con_post +s1p_a_4_C+ s1p_a_4_C_con +s1p_a_4_C_post+ s1p_a_4_C_con_post+ s1p_a_5_C +s1p_a_5_C_con +s1p_a_5_C_post +s1p_a_5_C_con_post+ s1p_a_6_C +s1p_a_6_C_con +s1p_a_6_C_post +s1p_a_6_C_con_post+ s1p_a_7_C +s1p_a_7_C_con +s1p_a_7_C_post +s1p_a_7_C_con_post +s1p_a_8_C +s1p_a_8_C_con +s1p_a_8_C_post +s1p_a_8_C_con_post
 | 0 | 0 | cluster_joined, data=subset2)
summary(testreg2)

ptm <- proc.time()
cr2 <- conleyreg(forout ~ proj_C + proj_C_con + proj_C_post + proj_C_con_post + s1p_a_1_C + s1p_a_1_C_con +s1p_a_1_C_post +s1p_a_1_C_con_post +s1p_a_2_C +s1p_a_2_C_con+ s1p_a_2_C_post+ s1p_a_2_C_con_post +s1p_a_3_C +s1p_a_3_C_con +s1p_a_3_C_post+ s1p_a_3_C_con_post +s1p_a_4_C+ s1p_a_4_C_con +s1p_a_4_C_post+ s1p_a_4_C_con_post+ s1p_a_5_C +s1p_a_5_C_con +s1p_a_5_C_post +s1p_a_5_C_con_post+ s1p_a_6_C +s1p_a_6_C_con +s1p_a_6_C_post +s1p_a_6_C_con_post+ s1p_a_7_C +s1p_a_7_C_con +s1p_a_7_C_post +s1p_a_7_C_con_post +s1p_a_8_C +s1p_a_8_C_con +s1p_a_8_C_post +s1p_a_8_C_con_post
, data=subset2, dist_cutoff=500, lat="x", lon="y", unit="id", time="post", sparse=TRUE)
cr2
proc.time() - ptm
# 4k - 140sec







