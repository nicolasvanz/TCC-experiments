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
library(grid, warn.conflicts = FALSE)
library(gridExtra, warn.conflicts = FALSE)

# My Utilities
source(file = "rscripts/rplots/lines.R")
source(file = "rscripts/rplots/bars.R")
source(file = "rscripts/rplots/theme.R")
source(file = "rscripts/rplots/utils.R")
source(file = "rscripts/consts.R")
source(file = "rscripts/power.R")

#===============================================================================
# Input Reading
#===============================================================================

args = commandArgs(trailingOnly=TRUE)

if (length(args) >= 3) {
	experiment.infile <- args[1]
	experiment.outdir <- args[2]
	experiment.outfile <- args[3]
} else {
	experiment.infile <- "./results/cooked/services/services.csv"
	experiment.outdir <- "./results/plots/services"
	experiment.outfile <- "services"
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
# Filter
#===============================================================================

# Convert cycles to ms
experiment.df <- experiment.df %>% filter(service != "rstream")
experiment.df <- experiment.df %>%
	mutate(time = ifelse(service == "pgfetch", time/MPPA.FREQ/KILO , time/MPPA.FREQ/MILLI))

#===============================================================================
# Pre-Processing
#===============================================================================

# Header
# service;version;nprocs;size;time

print("Pre-processing")

variables.id <- c("service", "version", "nprocs")
variables <- c("time")

experiment.df.melted <- melt(
	data = experiment.df,
	id.vars = variables.id,
	measure.vars = variables
)

experiment.df.cooked <- ddply(
	experiment.df.melted,
	c(variables.id, "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)

#==============================================================================
# Plot Configuration
#==============================================================================

baseline.df <- filter(experiment.df.cooked, version == "baseline")
partial.df  <- filter(experiment.df.cooked, version == "comm")
full.df     <- filter(experiment.df.cooked, version == "daemons")

speedups.df <- data.frame(
	service = baseline.df$service,
	nprocs  = baseline.df$nprocs,
	partial_per_baseline = partial.df$mean  / baseline.df$mean,
	full_per_baseline    = full.df$mean     / baseline.df$mean,
	baseline_per_partial = baseline.df$mean / partial.df$mean,
	baseline_per_full    = baseline.df$mean / full.df$mean,
	partial_per_full     = partial.df$mean  / full.df$mean
)

variables.id <- c("service")
variables    <- c("baseline_per_partial", "baseline_per_full", "partial_per_full", "partial_per_baseline", "full_per_baseline")

speedups.df.melted <- melt(
	data = speedups.df,
	id.vars = variables.id,
	measure.vars = variables
)

speedups.df.cooked <- ddply(
	speedups.df.melted,
	c(variables.id, "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)

print("Speedups")
print(speedups.df.cooked)

pgfetch.sd.max <- max(filter(experiment.df.cooked, service == "pgfetch")$sd)
pginval.sd.max <- max(filter(experiment.df.cooked, service == "pginval")$sd)
print("Execution time SD")
print(filter(experiment.df.cooked, (service == "pgfetch" & sd == pgfetch.sd.max) | (service == "pginval" & sd == pginval.sd.max)))

print("Plot configuration")

plot.df <- experiment.df.cooked

plot.x      <- "nprocs"
plot.y      <- "mean"
plot.factor <- "version"
plot.facet  <- "service"

# Titles
plot.title <- NULL#"Response Time of User/Dispatcher Kernel Calls"
plot.subtitle <- NULL#paste("Nanvix Version", experiment.nanvix.version, sep = " ")

plot.df$service <- factor(plot.df$service, levels=c("pgfetch", "pginval"))
levels(plot.df$service) <- c("Pgfetch", "Pginval")

# Legend
plot.legend.title <- "Nanvix Variant"
plot.legend.labels <- c("Baseline", "Partial", "Full")
plot.df$version <- factor(plot.df$version, levels=c("baseline", "comm", "daemons"))

# X Axis
plot.axis.x.title <- "Number of Processes"
plot.axis.x.breaks <- seq(from = 1, to = max(plot.df$nprocs), by = 1)
plot.axis.x.labels <- seq(from = 1, to = max(plot.df$nprocs), by = 1)

# Y Axis
plot.axis.y.pgfetch.title <- "Time (s)"
plot.axis.y.pgfetch.limits = c(0, 1.3)
plot.axis.y.pgfetch.breaks = seq(from = 0, to = 1.3, by = 0.13)
plot.axis.y.pginval.title <- "Time (ms)"
plot.axis.y.pginval.limits = c(0, 27)
plot.axis.y.pginval.breaks = seq(from = 0, to = 27, by = 2.5)

#===============================================================================
# Plot
#===============================================================================

print("Ploting")

plot.pgfetch.df = filter(plot.df, service == "Pgfetch")
plot.pginval.df = filter(plot.df, service == "Pginval")

plot.pgfetch <- plot.linespoint.facet.colour(
	df = plot.pgfetch.df,
	factor = plot.x,
	respvar = plot.y,
	param = plot.factor,
	facet = plot.facet,
	title = plot.title,
	subtitle = plot.subtitle,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.x.labels = plot.axis.x.labels,
	axis.y.title = plot.axis.y.pgfetch.title,
	axis.y.breaks = plot.axis.y.pgfetch.breaks,
	axis.y.limits = plot.axis.y.pgfetch.limits,
	colour = c("#ca0020", "#92c5de", "#0571b0")
) + plot.theme.title +
	plot.theme.legend.top.left +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x

plot.pginval <- plot.linespoint.facet.colour(
	df = plot.pginval.df,
	factor = plot.x,
	respvar = plot.y,
	param = plot.factor,
	facet = plot.facet,
	title = plot.title,
	subtitle = plot.subtitle,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.x.labels = plot.axis.x.labels,
	axis.y.title = plot.axis.y.pginval.title,
	axis.y.breaks = plot.axis.y.pginval.breaks,
	axis.y.limits = plot.axis.y.pginval.limits,
	colour = c("#ca0020", "#92c5de", "#0571b0")
) + plot.theme.title +
	plot.theme.legend.top.left +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x

plot.save(
	plot = plot.pgfetch,
	height = 4,
	width = 8,
	directory = experiment.outdir,
	filename  = paste(experiment.outfile, "time-pgfetch", sep = "-")
)

plot.save(
	plot = plot.pginval,
	height = 4,
	width = 8,
	directory = experiment.outdir,
	filename  = paste(experiment.outfile, "time-pginval", sep = "-")
)

plot.y.pginval <- plot.linespoint.facet.colour2(
	df = plot.pginval.df,
	factor = plot.x,
	respvar = plot.y,
	param = plot.factor,
	facet = plot.facet,
	title = plot.title,
	subtitle = plot.subtitle,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.x.labels = plot.axis.x.labels,
	axis.y.title = plot.axis.y.pginval.title,
	axis.y.breaks = plot.axis.y.pginval.breaks,
	axis.y.limits = plot.axis.y.pginval.limits,
	colour = c("#ca0020", "#92c5de", "#0571b0")
) + plot.theme.title +
	plot.theme.legend.top.left +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.y

plot.y.pgfetch <- plot.linespoint.facet.colour2(
	df = plot.pgfetch.df,
	factor = plot.x,
	respvar = plot.y,
	param = plot.factor,
	facet = plot.facet,
	title = plot.title,
	subtitle = plot.subtitle,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.x.labels = plot.axis.x.labels,
	axis.y.title = plot.axis.y.pgfetch.title,
	axis.y.breaks = plot.axis.y.pgfetch.breaks,
	axis.y.limits = plot.axis.y.pgfetch.limits,
	colour = c("#ca0020", "#92c5de", "#0571b0")
) + plot.theme.title +
	plot.theme.legend.bottom.right +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.y

plot.services <- grid.arrange(plot.y.pginval, plot.y.pgfetch, nrow = 2)

plot.save(
	plot = plot.services,
	height = 4,
	width = 6.5,
	directory = experiment.outdir,
	filename  = paste(experiment.outfile, "time-services", sep = "-")
)

#===============================================================================
# Power
#===============================================================================

#===============================================================================
# Input Reading
#===============================================================================

it <- 0

# Experiment File
power.infile <-	paste(
	"./results",
	"cooked/services",
	paste(experiment.outfile, "profile.csv", sep = "-"),
	sep = "/"
)

# Experiment File
power.outfile.total <- paste(
	"./results",
	"cooked/services",
	paste(experiment.outfile, it, "power-total.csv", sep = "-"),
	sep = "/"
)

#===============================================================================
# Total
#===============================================================================

baseline.df.cooked <- subset(x = experiment.df.cooked, subset = (version == "baseline"))
comm.df.cooked <- subset(x = experiment.df.cooked, subset = (version == "comm"))
daemons.df.cooked <- subset(x = experiment.df.cooked, subset = (version == "daemons"))

print(paste("Ploting Total Consumption", it, sep = " "))

# Generate power table
power.df <- experiment.generate.power.services(
	experiment.df = filter(read.delim(file = power.infile, sep = ";", header = TRUE), service != "rstream"),
	experiment.name = experiment.outfile,
	experiment.outfile.total = power.outfile.total,
	experiment.versions = c("baseline", "comm", "daemons"),
	experiment.apps.time = rbind(baseline.df.cooked, comm.df.cooked, daemons.df.cooked),
	experiment.return = "total"
)

#===============================================================================
# Pre-Processing
#===============================================================================

#power.df$total <- power.df$total / 100 # number of operations

experiment.df.cooked <- experiment.df.cooked %>%
	mutate(mean = ifelse(service == "pginval", mean * MILLI, mean))

user.df.cooked <- experiment.df.cooked %>% filter(nprocs == 16)
user.df.total <- setNames(
	aggregate(
		x   = user.df.cooked$mean,
		by  = list(user.df.cooked$service, user.df.cooked$version),
		FUN = sum
	),
	c("service", "version", "time")
)

energy.user.df <- merge(
	user.df.total,
	power.df
)

energy.user.df$energy <- energy.user.df$avg*energy.user.df$time

#===============================================================================
# Mean
#===============================================================================

variables.id <- c("service", "version")
variables <- c("energy")

energy.user.df.melted <- melt(
	data = energy.user.df,
	id.vars = variables.id,
	measure.vars = variables
)

energy.user.df.cooked <- ddply(
	energy.user.df.melted,
	c(variables.id, "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)

print("Energy Mean and SD")
print(energy.user.df.cooked)

energy.user.df.cooked$min <- energy.user.df.cooked$mean - energy.user.df.cooked$sd
energy.user.df.cooked$max <- energy.user.df.cooked$mean + energy.user.df.cooked$sd

energy.comp <- filter(energy.user.df.cooked, version == "daemons" & service == "pgfetch")$mean[1]/filter(energy.user.df.cooked, version == "baseline" & service == "pgfetch")$mean[1]
energy.max  <- filter(energy.user.df.cooked, version == "daemons" & service == "pgfetch")$min[1]/filter(energy.user.df.cooked, version == "baseline" & service == "pgfetch")$min[1]
energy.min  <- filter(energy.user.df.cooked, version == "daemons" & service == "pgfetch")$max[1]/filter(energy.user.df.cooked, version == "baseline" & service == "pgfetch")$max[1]
energy.sd   <- max(energy.comp - energy.min, energy.max - energy.comp)

print("pgfetch Energy efficiency")
print(paste(energy.comp, " +-", energy.sd))

energy.comp <- filter(energy.user.df.cooked, version == "baseline" & service == "pginval")$mean[1]/filter(energy.user.df.cooked, version == "daemons" & service == "pginval")$mean[1]
energy.max  <- filter(energy.user.df.cooked, version == "baseline" & service == "pginval")$min[1]/filter(energy.user.df.cooked, version == "daemons" & service == "pginval")$min[1]
energy.min  <- filter(energy.user.df.cooked, version == "baseline" & service == "pginval")$max[1]/filter(energy.user.df.cooked, version == "daemons" & service == "pginval")$max[1]
energy.sd   <- max(energy.comp - energy.min, energy.max - energy.comp)

print("pginval Energy efficiency")
print(paste(energy.comp, " +-", energy.sd))

#===============================================================================
# Plot
#===============================================================================

plot.df <- energy.user.df.cooked

plot.x      <- "version"
plot.y      <- "mean"
plot.factor <- "version"
plot.facet  <- "service"

# Titles
plot.title    <- NULL
plot.subtitle <- NULL

plot.df$service <- factor(plot.df$service, levels=c("pgfetch", "pginval"))
levels(plot.df$service) <- c("Pgfetch (16 processes)", "Pginval (16 processes)")

# Legend
plot.legend.title  <- "Nanvix Variant"
plot.legend.labels <- c("Baseline", "Partial", "Full")
plot.df$version <- factor(plot.df$version, levels=c("baseline", "comm", "daemons"))
#levels(plot.df$version) <- c("Baseline", "Comm with Tasks", "Comm and Daemons with Tasks")

# X Axis
plot.axis.x.title <- "Nanvix Variant"
plot.axis.x.breaks <- c("Baseline", "Partial", "Full")

# Y Axis
plot.axis.y.title <- "Energy (J)"
plot.pgfetch.axis.y.limits = c(0, 10)
plot.pgfetch.axis.y.breaks = seq(from = 0, to = 10, by = 2)
plot.pginval.axis.y.limits = c(0, 0.2)
plot.pginval.axis.y.breaks = seq(from = 0, to = 0.2, by = 0.04)

# Data Labels
plot.data.labels.digits <- 2

plot.pgfetch.df = filter(plot.df, service == "Pgfetch (16 processes)")
plot.pginval.df = filter(plot.df, service == "Pginval (16 processes)")

plot.pgfetch <- plot.bars.facet.colour(
	df = plot.pgfetch.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	facet = plot.facet,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.y.title = plot.axis.y.title,
	axis.y.limits = plot.pgfetch.axis.y.limits,
	axis.y.breaks = plot.pgfetch.axis.y.breaks,
	data.labels.digits = plot.data.labels.digits,
	colour = c("#ca0020", "#92c5de", "#0571b0")
) + plot.theme.title +
	plot.theme.legend.none +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x

plot.pginval <- plot.bars.facet.colour(
	df = plot.pginval.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	facet = plot.facet,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.y.title = plot.axis.y.title,
	axis.y.limits = plot.pginval.axis.y.limits,
	axis.y.breaks = plot.pginval.axis.y.breaks,
	data.labels.digits = plot.data.labels.digits,
	colour = c("#ca0020", "#92c5de", "#0571b0")
) + plot.theme.title +
	plot.theme.legend.none +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x

plot.save(
	plot.pgfetch,
	height = 4,
	width = 4,
	directory = experiment.outdir,
	filename = paste(experiment.outfile, "energy-pgfetch", sep = "-")
)

plot.save(
	plot.pginval,
	height = 4,
	width = 4,
	directory = experiment.outdir,
	filename = paste(experiment.outfile, "energy-pginval", sep = "-")
)

plot.services <- grid.arrange(plot.pginval, plot.pgfetch, nrow = 1)

plot.save(
	plot.services,
	height = 4,
	width = 7,
	directory = experiment.outdir,
	filename = paste(experiment.outfile, "energy-services", sep = "-")
)


