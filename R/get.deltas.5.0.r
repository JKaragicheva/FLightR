## the version is copied from
# ver.4.0.-4.4.estimating.error.fixed.sd.fast.1-10.minutes.r

# decided to add a function that will complete the task at different latitudes with the parallel package..
# the idea is very simple:
# we just make a general wrapper that runs the whole thing at each latitude and then combines results...


get.deltas.one.basic<-function(delta=0, start=c(0,0), Sigma=0.5, return.all.out=F, interval=600, short.run=T, Parameters=list(Intercept=c(3.71, 1.25), LogSlope=c(0.72, 0.4))) {
# so this function will have to return 1 0 or -1

Points.Land<-as.matrix(expand.grid(start[1], seq(start[2]-8, start[2]+8, 0.5)))
Points.Land<-cbind(Points.Land, 1)
Time.seq<-seq(from=as.numeric(as.POSIXct("2010-01-01 00:00:00", tz="UTC")), to=as.numeric(as.POSIXct("2010-03-31 23:59:59", tz="UTC")), by=interval)
Track<-cbind(start[1], start[2], Time.seq)

Parameters$LogSigma=c(log(Sigma), 0.0)
all.out<-get.shifts(Track=Track, Points.Land=Points.Land, start=start, Parameters=Parameters, log.irrad.borders=log.irrad.borders, slopes.only=F, delta=delta, short.run=short.run, saving.period=interval)
Real.Sigma<-mean(all.out$Slopes[,2], na.rm=T)
# and now we need to get resulting value

Diff<-try(all.out$Points.Land[which.max(apply(all.out$Phys.Mat[,1:(dim(all.out$Phys.Mat)[2])],1,  FUN=prod)),2]-start[2])
if (class(Diff)=="try-error") Diff=NA

Diff_1<-try(all.out$Points.Land[which.max(apply(all.out$Phys.Mat[,1:80],1,  FUN=prod)),2]-start[2])
if (class(Diff_1)=="try-error") Diff_1=NA

Diff_2<-try(all.out$Points.Land[which.max(apply(all.out$Phys.Mat[,80:(dim(all.out$Phys.Mat)[2])],1,  FUN=prod)),2]-start[2])
if (class(Diff_2)=="try-error") Diff_2=NA

Res<-c(Diff, Real.Sigma, delta, start[2], Diff_1=Diff_1, Diff_2=Diff_2)
if (return.all.out) {return(all.out)
} else {return(Res)}
}

get.deltas.intermediate<-function(deltalim=c(-0.2, 0.2), start=c(0,0), Sigma=0.5, interval=600, short.run=T, Parameters=list(Intercept=c(3.71, 1.25), LogSlope=c(0.72, 0.4)), repeats=3, random.delta=T) {
	if (random.delta) {
	Deltas<-rep(runif(ceiling((deltalim[2]-deltalim[1])/0.02), deltalim[1], deltalim[2]), repeats)
	} else {
	Deltas<-rep(seq(deltalim[1], deltalim[2], 0.01), repeats)
	}
Res<-c()
for (i in Deltas) {
Res<-rbind(Res, get.deltas.one.basic(delta=i, start=start, Sigma=Sigma, interval=interval,short.run=short.run, Parameters=Parameters))
try(print(tail(Res, 20)))
}
return(Res)
}

# and now the next on that will iterate Sigma
get.deltas.main<-function(deltalim=c(-0.2, 0.2), start=c(0,0), Sigmas=seq(0, 0.8, 0.1), interval=600, short.run=T, LogSlope=c(0.68, 0.4), Parameters=list(Intercept=c(3.71, 1.25), LogSlope=c(0.72, 0.4)), repeats=3, random.delta=T) {

Res<-c()
for (i in Sigmas) {
cat(Sigmas, "\n")
Res<-rbind(Res,cbind(get.deltas.intermediate(deltalim=deltalim, start=start, Sigma=i, interval=interval, short.run=short.run, Parameters=Parameters, repeats=repeats, random.delta=random.delta), i))
print(Res)
save(Res, file=paste("Res", start[2],"tmp.RData", sep="."))
}
return(Res)
}

get.deltas.parallel<-function(deltalim=c(-0.2, 0.2), limits=c(-65,65), points=20, Sigmas=seq(0, 0.8, 0.1), interval=600, short.run=T, LogSlope=c(0.68, 0.4), threads=2, log.irrad.borders=c(-50, 50), Parameters=list(Intercept=c(3.71, 1.25), LogSlope=c(0.72, 0.4)), repeats=1, random.delta=T, wd="D://Geologgers") {
get.deltas.parallel<-function(deltalim=c(-0.2, 0.2), limits=c(-65,65), points=20, Sigmas=seq(0, 0.8, 0.1), interval=600, short.run=T, LogSlope=c(0.68, 0.4), threads=2, log.irrad.borders=c(-50, 50), Parameters=list(Intercept=c(3.71, 1.25), LogSlope=c(0.72, 0.4)), repeats=1, random.delta=T, wd="D://Geologgers") {

# points means number of latitudes that should be used for the run..
require(parallel)
# the question is what we have to download before we can run this on cluster
mycl<-makeCluster(threads)
Lats<-runif(points, min(limits), max(limits))
Coords<-cbind(0, Lats)
    tmp<-parallel:::clusterSetRNGStream(mycl)
    ### we don' need to send all parameters to node. so keep it easy..
    tmp<-parallel:::clusterExport(mycl, c("Parameters", "log.irrad.borders", "log.light.borders"))
    tmp<-parallel:::clusterEvalQ(mycl, library("FLightR"))
    tmp<-parallel:::clusterEvalQ(mycl, library("GeoLight")) 
    #tmp<-parallel:::clusterEvalQ(mycl, source(file.path(wd, "FLightR_functions_source\\run.segmented.lnorm.loess.R")))
    #tmp<-parallel:::clusterEvalQ(mycl, source(file.path(wd, "FLightR_functions_source\\create.proposal.R")))
    #tmp<-parallel:::clusterEvalQ(mycl, source(file.path(wd, "\\LightR_development_code\\functions.Dusk.and.Dawn.5.1.r")))
    #tmp<-parallel:::clusterEvalQ(mycl, source(file.path(wd, "LightR_development_code\\get.shifts.5.0.r")))
    #tmp<-parallel:::clusterEvalQ(mycl, source(file.path(wd, "LightR_development_code\\get.slopes.5.0.r")))
    #tmp<-parallel:::clusterEvalQ(mycl, source(file.path(wd, "Geologgers\\LightR_development_code\\get.deltas.5.0.r")))
	#Coords<-as.data.frame(Coords)
	Res<-parApply(mycl, Coords, 1, FUN=function(x) as.data.frame(get.deltas.main(start=x,  deltalim=deltalim, Sigmas=Sigmas, interval=interval, short.run=short.run, LogSlope=LogSlope, Parameters=Parameters, repeats=1, random.delta=random.delta)))
	#Res1<-apply(Coords, 1, FUN=function(x) as.data.frame(get.deltas.main(start=x,  deltalim=deltalim, Sigmas=Sigmas, interval=interval, short.run=short.run, LogSlope=LogSlope, Parameters=Parameters, repeats=1, random.delta=random.delta)))
	stopCluster(cl = mycl)
	Res<-do.call(rbind.data.frame, Res)
	return(Res)
}