#
# MIT License
#
# Copyright (c) 2011-2020 Pedro Henrique Penna <pedrohenriquepenna@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# R Libraries
library(ggplot2)
library(reshape2)
library(scales)
library(plyr)
library(tidyverse)

# My Utilities
source(file = "rscripts/rplots/lines.R")
source(file = "rscripts/rplots/bars.R")
source(file = "rscripts/rplots/theme.R")
source(file = "rscripts/rplots/utils.R")
source(file = "rscripts/consts.R")
source(file = "rscripts/power.R")

#===============================================================================
# Experiment Information
#===============================================================================

args = commandArgs(trailingOnly=TRUE)

if (length(args) >= 3) {
	experiment.infile <- args[1]
	experiment.outdir <- args[2]
	experiment.outfile <- args[3]
} else {
	experiment.infile <- "./results/cooked/capbench/fast.csv"
	experiment.outdir <- "./results/plots/capbench"
	experiment.outfile <- "fast"
}

if (length(args) >= 4) {
	experiment.power.it <- args[4]
} else {
	experiment.power.it <- 0
}

#===============================================================================
# Input Reading
#===============================================================================

experiment.df <- read_delim(
	file = experiment.infile,
	col_names = TRUE,
	delim = ";"
)

#===============================================================================
# Pre-changes
#===============================================================================

# Changes number procs to clusters used
experiment.df$nprocs <- (experiment.df$nprocs / 12)
experiment.df$time   <- (experiment.df$time / MPPA.FREQ)

#===============================================================================
# Pre-Processing
#===============================================================================

baseline.df <- subset(
	x = experiment.df,
	subset = (api == "baseline")
)
baseline.df.melted <- melt(
	data = baseline.df,
	id.vars = c("api",  "nprocs"),
	measure.vars = c("time"),
)
baseline.df.cooked <- ddply(
	baseline.df.melted,
	c("api",  "nprocs", "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)
baseline.df.cooked$speedup <- baseline.df.cooked$mean[1]/baseline.df.cooked$mean

comm.df <- subset(
	x = experiment.df,
	subset = (api == "comm")
)
comm.df.melted <- melt(
	data = comm.df,
	id.vars = c("api",  "nprocs"),
	measure.vars = c("time"),
)
comm.df.cooked <- ddply(
	comm.df.melted,
	c("api",  "nprocs", "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)
comm.df.cooked$speedup <- comm.df.cooked$mean[1]/comm.df.cooked$mean

daemons.df <- subset(
	x = experiment.df,
	subset = (api == "daemons")
)
daemons.df.melted <- melt(
	data = daemons.df,
	id.vars = c("api",  "nprocs"),
	measure.vars = c("time"),
)
daemons.df.cooked <- ddply(
	daemons.df.melted,
	c("api",  "nprocs", "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)
daemons.df.cooked$speedup <- daemons.df.cooked$mean[1]/daemons.df.cooked$mean

# Defines a column to represent the current experiment
baseline.df.cooked$exp <- toupper(experiment.outfile)
comm.df.cooked$exp     <- toupper(experiment.outfile)
daemons.df.cooked$exp  <- toupper(experiment.outfile)

time.df <- rbind(baseline.df.cooked, comm.df.cooked, daemons.df.cooked)

print(time.df)

comp.df <- data.frame(
	nprocs = baseline.df.cooked$nprocs,
	pb = comm.df.cooked$mean/baseline.df.cooked$mean,
	fb = daemons.df.cooked$mean/baseline.df.cooked$mean,
	bf = baseline.df.cooked$mean/daemons.df.cooked$mean,
	pf = comm.df.cooked$mean/daemons.df.cooked$mean
)
comp.df$dummy <- "dummy"
comp.df.melted <- melt(
	data = comp.df,
	id.vars = c("dummy"),
	measure.vars = c("pb", "fb", "bf", "pf"),
)
comp.df.cooked <- ddply(
	comp.df.melted,
	c("dummy", "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)
print(comp.df.cooked)

#===============================================================================
# Weak Scaling
#===============================================================================

print("Weak Scaling")

plot.df <- time.df

plot.var.x  <- "nprocs"
plot.var.y  <- "speedup"
plot.factor <- "api"
plot.facet  <- "exp"

# Titles
plot.title    <- NULL
plot.subtitle <- NULL

# Legend
plot.legend.title  <- "Nanvix Variant"
plot.legend.labels <- c("Baseline", "Partial", "Full")
plot.df$api <- factor(plot.df$api, levels=c("baseline", "comm", "daemons"))
levels(plot.df$api) <- c("Baseline", "Parital", "Full")

# X Axis
if (experiment.outfile == "is") {
	plot.axis.x.title <- "Number of Clusters (MPI Processes)"
} else {
	plot.axis.x.title <- ""
}
plot.axis.x.breaks <- 2^c(0:4)
plot.axis.x.labels <- c("1 (12)", "2 (24)", "4 (48)", "8 (96)", "16 (192)")

# Y Axis
if (experiment.outfile == "fn") {
	plot.axis.y.title <- "Weak Scaling Efficiency"
} else if (experiment.outfile == "fast") {
	plot.axis.y.title <- "Weak Scaling Efficiency"
} else {
	plot.axis.y.title <- ""
}
plot.axis.ymin  <- 0.0
plot.axis.ymax  <- 1.1
plot.axis.ystep <- 0.1

plot.axis.y.limits <- c(plot.axis.ymin, plot.axis.ymax)
plot.axis.y.breaks <- seq(from = plot.axis.ymin, to = plot.axis.ymax, by = plot.axis.ystep)

plot <- plot.linespoint.facet.colour(
	df = plot.df,
	factor = plot.var.x,
	respvar = plot.var.y,
	param = plot.factor,
	facet = plot.facet,
	title = plot.title,
	subtitle = plot.subtitle,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.x.labels = plot.axis.x.labels,
	axis.x.trans = "log2",
	axis.y.title = plot.axis.y.title,
	axis.y.limits = plot.axis.y.limits,
	axis.y.breaks = plot.axis.y.breaks,
	colour = c("#ca0020", "#92c5de", "#0571b0")
) + plot.theme.title +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.facet.x

if (experiment.outfile == "fn") {
	plot <- plot + plot.theme.legend.bottom.left
} else {
	plot <- plot + plot.theme.legend.none
}

if (length(args) >= 1) {
	plot.save(
		plot,
		height = 4,
		width = 4.7,
		directory = experiment.outdir,
		filename = paste(experiment.outfile, "speedup", sep = "-")
	)
} else {
	plot
}

#===============================================================================
# Time Plot
#===============================================================================

print("Time Plot")

plot.df <- rbind(baseline.df.cooked, comm.df.cooked, daemons.df.cooked)

plot.x <- "nprocs"
plot.y <- "mean"
plot.factor <- "api"
plot.facet <- "exp"

# Titles
plot.title <- NULL
plot.subtitle <- NULL

# Legend
plot.legend.title <- "Nanvix Variant"
plot.legend.labels <- c("Baseline", "Partial", "Full")
plot.df$api <- factor(plot.df$api, levels=c("baseline", "comm", "daemons"))
levels(plot.df$api) <- c("Baseline", "Partial", "Full")

# X Axis (Look the paper, we reuse the x title from weak scaling)
if (experiment.outfile == "is") {
	plot.axis.x.title <- "Number of Clusters (MPI Processes)"
} else {
	plot.axis.x.title <- ""
}
plot.df$nprocs <- as.factor(plot.df$nprocs)
plot.axis.x.breaks <- c("1 (12)", "2 (24)", "4 (48)", "8 (96)", "16 (192)")

# Y Axis
if (experiment.outfile == "fn") {
	plot.axis.y.title <- "Time (s)"
} else if (experiment.outfile == "fast") {
	plot.axis.y.title <- "Time (s)"
} else {
	plot.axis.y.title <- ""
}

# Internal label offset
plot.labels.hjust <- -0.22
plot.labels.vjust <- 0.5

if (experiment.outfile == "km") {
	plot.axis.ystep <- 300
	plot.axis.ymax  <- 10*plot.axis.ystep
} else if (experiment.outfile == "gf") {
	plot.axis.ystep <- 500
	plot.axis.ymax  <- 9*plot.axis.ystep
} else if (experiment.outfile == "fn") {
	plot.axis.ystep <- 25
	plot.axis.ymax  <- 6*plot.axis.ystep
} else if (experiment.outfile == "fast") {
	plot.axis.ystep <- 1050
	plot.axis.ymax  <- 6*plot.axis.ystep
} else if (experiment.outfile == "is") {
	plot.axis.ystep <- 250
	plot.axis.ymax  <- 6*plot.axis.ystep
} else { # lu
	plot.axis.ystep <- 400
	plot.axis.ymax  <- 6*plot.axis.ystep
}

plot.axis.ymin <- 0

plot.axis.y.limits <- c(plot.axis.ymin, plot.axis.ymax)
plot.axis.y.breaks <- seq(from = plot.axis.ymin, to = plot.axis.ymax, by = plot.axis.ystep)

# Data Labels
plot.data.labels.digits <- 0

plot <- plot.bars.facet.colour(
	df = plot.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	facet = plot.facet,
	title = plot.title,
	subtitle = plot.subtitle,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	data.labels.hjust = plot.labels.hjust,
	data.labels.vjust = plot.labels.vjust,
	data.labels.angle = 90,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.y.title = plot.axis.y.title,
	axis.y.limits = plot.axis.y.limits,
	axis.y.breaks = plot.axis.y.breaks,
	data.labels.digits = plot.data.labels.digits,
	colour = c("#ca0020", "#92c5de", "#0571b0")
) + plot.theme.title +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x

if (experiment.outfile == "fn") {
	plot <- plot + plot.theme.legend.bottom.left
} else {
	plot <- plot + plot.theme.legend.none
}

if (length(args) >= 1) {
	plot.save(
		plot,
		width = 5,
		height = 4,
		directory = experiment.outdir,
		filename = paste(experiment.outfile, "time", sep = "-")
	)
} else {
	plot
}

#===============================================================================
# Statistics
#===============================================================================

# Max CoVs
print(max(baseline.df.cooked$cv))
print(max(comm.df.cooked$cv))
print(max(daemons.df.cooked$cv))

#===============================================================================
# Power
#===============================================================================

#===============================================================================
# Input Reading
#===============================================================================

print("Do power")

# Experiment File
power.infile <-	paste(
	"./results",
	"cooked/capbench",
	paste(experiment.outfile, "profile.csv", sep = "-"),
	sep = "/"
)

# Experiment File
power.outfile.total <- paste(
	"./results",
	"cooked/capbench",
	paste(experiment.outfile, "power-total.csv", sep = "-"),
	sep = "/"
)

# Experiment File
power.outfile.predict <- paste(
	"./results",
	"cooked/capbench",
	paste(experiment.outfile, "power-predict.csv", sep = "-"),
	sep = "/"
)

# Experiment File
power.outfile.means <- paste(
	"./results",
	"cooked/capbench",
	paste(experiment.outfile, "power-means.csv", sep = "-"),
	sep = "/"
)

# Generate power table
power.df <- experiment.generate.power(
	experiment.df = read.delim(file = power.infile, sep = ";", header = TRUE),
	experiment.name = experiment.outfile,
	experiment.outfile.total = power.outfile.total,
	experiment.outfile.predict = power.outfile.predict,
	experiment.outfile.means = power.outfile.means,
	experiment.versions = c("baseline", "comm", "daemons"),
	experiment.apps.time = rbind(baseline.df.cooked, comm.df.cooked, daemons.df.cooked),
	experiment.return = "total",
	experiment.force.generation = FALSE
)

print("Done generate power")

print(head(power.df))

#===============================================================================
# Total Stats
#===============================================================================

variables.id <- c("version", "nprocs")
variables <- c("total")

power.df.melted <- melt(
	data = power.df,
	id.vars = variables.id,
	measure.vars = variables
)

power.df.cooked <- ddply(
	power.df.melted,
	c(variables.id, "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)

print("Energy Mean and SD")
print(power.df.cooked)

#===============================================================================
# Total
#===============================================================================

print(paste("Ploting Total Consumption", sep = " "))

power.df.cooked$exp <- toupper(experiment.outfile)

plot.df <- power.df.cooked

plot.x      <- "nprocs"
plot.y      <- "mean"
plot.factor <- "version"
plot.facet  <- "exp"

# Titles
plot.title    <- NULL
plot.subtitle <- NULL

# Legend
plot.legend.title  <- "Nanvix Variant"
plot.legend.labels <- c("Baseline", "Partial", "Full")
plot.df$version <- factor(plot.df$version, levels=c("baseline", "comm", "daemons"))
levels(plot.df$version) <- c("Baseline", "Partial", "Full")

# X Axis
if (experiment.outfile == "is") {
	plot.axis.x.title <- "Number of Clusters (MPI Processes)"
} else {
	plot.axis.x.title <- ""
}
plot.df$nprocs <- as.factor(plot.df$nprocs)
plot.axis.x.breaks <- c("1 (12)", "2 (24)", "4 (48)", "8 (96)", "16 (192)")

# Y Axis
if (experiment.outfile == "fn") {
	plot.axis.y.title <- "Energy (J)"
} else if (experiment.outfile == "fast") {
	plot.axis.y.title <- "Energy (J)"
} else {
	plot.axis.y.title <- ""
}

# Internal label offset
plot.labels.hjust <- -0.22
plot.labels.vjust <- 0.5

plot.axis.y.min <- 0

if (experiment.outfile == "km") {
	plot.axis.y.max <- 22000
} else if (experiment.outfile == "gf") {
	plot.axis.y.max <- 35000
} else if (experiment.outfile == "fn") {
	plot.axis.y.max <- 1500
} else if (experiment.outfile == "fast") {
	plot.axis.y.max <- 45000
} else if (experiment.outfile == "is") {
	plot.axis.y.max <- 10000
} else {
	plot.axis.y.max <- 17500
}
plot.axis.y.intervals <- 6

plot.axis.y.limits <- c(plot.axis.y.min, plot.axis.y.max)
plot.axis.y.breaks <- seq(from = plot.axis.y.min, to = plot.axis.y.max, length.out = plot.axis.y.intervals)

# Data Labels
plot.data.labels.digits <- 0

plot <- plot.bars.facet.colour(
	df = plot.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	facet = plot.facet,
	title = plot.title,
	subtitle = plot.subtitle,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	data.labels.hjust = plot.labels.hjust,
	data.labels.vjust = plot.labels.vjust,
	data.labels.angle = 90,
	data.labels.dodge = 1,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.y.title = plot.axis.y.title,
	axis.y.breaks = plot.axis.y.breaks,
	axis.y.limits = plot.axis.y.limits,
	data.labels.digits = plot.data.labels.digits,
	colour = c("#ca0020", "#92c5de", "#0571b0")
) + plot.theme.title +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x

if (experiment.outfile == "fn") {
	plot <- plot + plot.theme.legend.top.left
} else {
	plot <- plot + plot.theme.legend.none
}

if (length(args) >= 1) {
	plot.save(
		plot,
		width = 5,
		height = 4,
		directory = experiment.outdir,
		filename = paste(experiment.outfile, "energy-total", sep = "-")
	)
} else {
	plot
}

if (experiment.outfile == "km")
{
	for (it in 0:9)
	{
		#if (experiment.outfile == "km")
		#{
			#===============================================================================
			# Predict
			#===============================================================================

			print(paste("Ploting Predict Consumption", it, sep = " "))

			predict.df <- experiment.generate.power(
				experiment.outfile.predict = power.outfile.predict,
				experiment.iteration = it,
				experiment.return = "predict",
				experiment.force.generation = FALSE
			)

			plot.df    <- predict.df

			plot.var.x  <- "time"
			plot.var.y  <- "power"
			plot.factor <- "version"
			plot.facet  <- "nprocs"

			# Titles
			plot.title    <- NULL
			plot.subtitle <- NULL

			# Legend
			plot.legend.title  <- "Nanvix Variant"
			plot.legend.labels <- c("Baseline", "Partial", "Full")
			plot.df$version <- factor(plot.df$version, levels=c("baseline", "comm", "daemons"))
			levels(plot.df$version) <- c("Baseline", "Partial", "Full")

			if (experiment.outfile == "km") {
				plot.axis.x.max <- 2100
				plot.axis.x.intervals <- 8
				plot.axis.y.min <- 7
				plot.axis.y.max <- 8.5
				plot.axis.y.intervals <- 7
			} else if (experiment.outfile == "gf") {
				plot.axis.x.max <- 3600
				plot.axis.x.intervals <- 9
				plot.axis.y.min <- 6
				plot.axis.y.max <- 8.5
				plot.axis.y.intervals <- 7
			} else {
				plot.axis.x.max <- 150
				plot.axis.x.intervals <- 9
				plot.axis.y.min <- 6
				plot.axis.y.max <- 12
				plot.axis.y.intervals <- 7
			}

			plot.axis.x.interval.size <- plot.axis.x.max / (plot.axis.x.intervals - 1)

			# X Axis
			plot.axis.x.title  <- "Time (s)"
			plot.axis.x.breaks <- seq(from = 0, to = plot.axis.x.max, length.out = plot.axis.x.intervals)

			# Y Axis
			plot.axis.y.title <- "Power (W)"
			plot.axis.y.limits <- c(plot.axis.y.min, plot.axis.y.max)
			plot.axis.y.breaks <- seq(from = plot.axis.y.min, to = plot.axis.y.max, length.out = plot.axis.y.intervals)

			# Facets
			plot.df$nprocs <- factor(plot.df$nprocs, levels=c(12, 48, 192))
			levels(plot.df$nprocs) <- c("1 Cluster (12 MPI Processes)", "4 Clusters (48 MPI Processes)", "16 Clusters (192 MPI Processes)")

			plot <- plot.lines.facet2(
				df = plot.df,
				factor = plot.var.x,
				respvar = plot.var.y,
				param = plot.factor,
				facet = plot.facet,
				interval.size = plot.axis.x.interval.size,
				title = plot.title,
				legend.title = plot.legend.title,
				legend.labels = plot.legend.labels,
				axis.x.title = plot.axis.x.title,
				axis.x.breaks = plot.axis.x.breaks,
				axis.y.title = plot.axis.y.title,
				axis.y.breaks = plot.axis.y.breaks,
				axis.y.limits = plot.axis.y.limits,
				colour = c("#ca0020", "#92c5de", "#0571b0")
			) + plot.theme.title +
				plot.theme.legend.bottom.right +
				plot.theme.axis.x +
				plot.theme.axis.y +
				plot.theme.grid.wall +
				plot.theme.grid.major +
				plot.theme.facet.x

			plot.save(
				plot = plot,
				height = 5,
				width = 13,
				directory = experiment.outdir,
				filename  = paste(
					experiment.outfile,
					"energy-predict",
					it,
					sep = "-"
				)
			)

		if (FALSE) {
			#===============================================================================
			# Predict
			#===============================================================================

			print(paste("Ploting Mean Consumption", it, sep = " "))

			means.df <- experiment.generate.power(
				experiment.outfile.means = power.outfile.means,
				experiment.iteration = it,
				experiment.return = "means",
				experiment.force.generation = FALSE
			)

			plot.df <- means.df

			plot.var.x  <- "time"
			plot.var.y  <- "power"
			plot.factor <- "version"
			plot.facet  <- "nprocs"

			# Titles
			plot.title    <- NULL
			plot.subtitle <- NULL

			# Legend
			plot.legend.title  <- "Nanvix Variant"
			plot.legend.labels <- c("Baseline", "Partial", "Full")
			plot.df$version <- factor(plot.df$version, levels=c("baseline", "comm", "daemons"))
			levels(plot.df$version) <- c("Baseline", "Partial", "Full")

			# X Axis
			plot.axis.x.title  <- "Interval (200 dots per mean)"
			plot.axis.x.breaks <- seq(from = 0, to = max(means.df$group), length.out = 10)

			plot.axis.y.title <- "Power (W)"

			plot <- plot.lines.facet2(
				df = plot.df,
				factor = plot.var.x,
				respvar = plot.var.y,
				param = plot.factor,
				facet = plot.facet,
				title = plot.title,
				legend.title = plot.legend.title,
				legend.labels = plot.legend.labels,
				axis.x.title = plot.axis.x.title,
				axis.x.breaks = plot.axis.x.breaks,
				axis.y.title = plot.axis.y.title,
				colour = c("#ca0020", "#92c5de", "#0571b0")
			) + plot.theme.title +
				plot.theme.legend.top.left +
				plot.theme.axis.x +
				plot.theme.axis.y +
				plot.theme.grid.wall +
				plot.theme.grid.major

			plot.save(
				plot = plot,
				width = 15,
				height = 5,
				directory = experiment.outdir,
				filename  = paste(
					experiment.outfile,
					"energy-means",
					it,
					sep = "-"
				)
			)
		}
	}
}

