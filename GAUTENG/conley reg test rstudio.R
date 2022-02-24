
# install.packages("matchingR")
# install.packages("reprow")

library(matchingR)
library(doBy)
library(conleyreg)
library(foreign)
library(tidyverse)
mydata <- read.dta("/Users/williamviolette/southafrica/Generated/GAUTENG/reg_test.dta")

idxy <- summaryBy(x + y ~ cluster_joined + post,  FUN=c(mean,length),data=mydata)
names(idxy)[names(idxy) == "post"] <- "time"

# dm <- dist_mat(idxy,unit="cluster_joined",time="time",lat="x.mean",lon="y.mean",dist_cutoff=10,sparse=TRUE,st_distance=FALSE)

dm <- dist_mat(idxy,unit="cluster_joined",time="time",lat="x.mean",lon="y.mean",dist_cutoff=10)

dm1 <- dm[[1]]

idsubset<-subset(idxy,time==0)
indvar=idsubset[,"x.length"]

length(dm1[,1])

for (i in 1:2) {
  print(i)
  print(indvar[i])
  for (j in 1:indvar[i]) {
    if(i<=1 & j<=1) {
      dd = rep(dm1[,i],indvar)
    } else {
      dd = cbind(dd,rep(dm1[,i],indvar))
    }
  }
}


for (i in 1:10) {
  print(i)
  if(i<=1) {
    dd = rep(dm1[,i],indvar)
  } else {
    dd = cbind(dd,rep(dm1[,i],indvar))
  }
}

dm1s <-dm1[,1]
dm1r <- rep(dm1s,idxy[,"x.length"])



reprow(dm1,idxy[,"x.length"])

data_new_1 <- dm1[rep(seq_len(nrow(dm1)), each = 3), ]

tt<-idxy[,"x.length"]

dm1r <- rep(dm1s,tt)

ttest=matrix(rep(t(dm1),tt),ncol=ncol(dm1),byrow=TRUE)



t(dm1)

dm1a<-rep(dm1,tt)


dm1r

dim(mydata)
head(mydata)
names(mydata)[names(mydata) == "for"] <- "forout"
head(mydata)

testreg <- lm(forout ~ post, data=mydata)
summary(testreg)

testreg2 <- lm(forout ~ post + proj_C + proj_C_con + proj_C_post + proj_C_con_post, data=mydata)
summary(testreg2)

testreg2 <- lm(forout ~ post + proj_C + proj_C_con + proj_C_post + proj_C_con_post, data=mydata[1:2000, ])
summary(testreg2)

ptm <- proc.time()
cr1 <- conleyreg(forout ~ post + proj_C + proj_C_con + proj_C_post + proj_C_con_post, data=mydata[1:2000, ], dist_cutoff=500, lat="x", lon="y", sparse=TRUE)
summary(cr1)
proc.time() - ptm

ptm <- proc.time()
cr1 <- conleyreg(forout ~ proj_C + proj_C_con + proj_C_post + proj_C_con_post, data=mydata[1:2000, ], dist_cutoff=500, lat="x", lon="y", unit="id", time="post", sparse=TRUE)
summary(cr1)
proc.time() - ptm

# 8 sec for 2000; only 5 sec with panel structure


ptm <- proc.time()
cr1 <- conleyreg(forout ~ proj_C + proj_C_con + proj_C_post + proj_C_con_post, data=mydata[1:20000, ], dist_cutoff=10, lat="x", lon="y", unit="id", time="post", sparse=TRUE)
summary(cr1)
proc.time() - ptm




