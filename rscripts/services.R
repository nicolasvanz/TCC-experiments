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

do_arrange <- TRUE

# R Libraries
library(plyr)
library(ggplot2)
library(reshape2)
library(scales)
library(dplyr, warn.conflicts = FALSE)
if (do_arrange)
{
	library(grid, warn.conflicts = FALSE)
	library(gridExtra, warn.conflicts = FALSE)
	#library(ggpubr)
}

# My Utilities
source(file = "rscripts/include/rplots/utils.R")
source(file = "rscripts/include/rplots/theme.R")
source(file = "rscripts/include/rplots/bars.R")
source(file = "rscripts/include/utils.R")
source(file = "rscripts/include/consts.R")
source(file = "rscripts/power.R")

#===============================================================================
# Experiment Information
#===============================================================================

experiment.name = "services"
experiment.nanvix.version = "4ef39d3"

#===============================================================================
# Input Reading
#===============================================================================

args = commandArgs(trailingOnly=TRUE)

# Experiment File
experiment.file<-ifelse(
	length(args) >= 2,
	args[1],
	paste(
		"./results",
		"cooked",
		experiment.nanvix.version,
		paste(experiment.name, "csv", sep = "."),
		sep = "/"
	)
)

# Output Directory
outdir <- ifelse(
	length(args) >= 3,
	args[2],
	getwd()
)

experiment.df <- read.table(file = experiment.file, sep = ";", header = TRUE)

#===============================================================================
# Filter
#===============================================================================

# Convert cycles to ms
experiment.df$time  <- experiment.df$cycles/MPPA.FREQ/MILLI

# Drop PgInval
#experiment.df <- experiment.df %>% filter(service != "pginval")

#===============================================================================
# Pre-Processing
#===============================================================================

variables.id <- c("version")
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

print(experiment.df.cooked)
print("Energy efficiency: user vs thread")
print(
	filter(experiment.df.cooked, version == "user")$mean[1]/
	filter(experiment.df.cooked, version == "thread")$mean[1]
)
print("Energy efficiency: user vs task")
print(
	filter(experiment.df.cooked, version == "user")$mean[1]/
	filter(experiment.df.cooked, version == "dispatcher")$mean[1]
)
print("Energy efficiency: thread vs task")
print(
	filter(experiment.df.cooked, version == "thread")$mean[1]/
	filter(experiment.df.cooked, version == "dispatcher")$mean[1]
)

#==============================================================================
# Plot Configuration
#==============================================================================

plot.df <- experiment.df.cooked

plot.x      <- "version"
plot.y      <- "mean"
plot.factor <- "version"

# Titles
plot.title <- "Different approaches of Nanvix Services"
plot.subtitle <- paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- ""
plot.legend.labels <- ""

# X Axis

plot.df$version<- factor(plot.df$version, levels=c("user", "thread", "dispatcher"))
levels(plot.df$version) <- c("Sequential", "Parallel", "Tasks")

plot.axis.x.title <- "Use Case Scenario"
plot.axis.x.breaks <- levels(as.factor(plot.df$version))

# Y Axis
plot.axis.y.title <- "Time (ms)"

#===============================================================================
# Plot
#===============================================================================

plot.data.labels.digits <- 1

plot.axis.y.breaks <- seq(from = 0, to = 12, by = 2)
plot.axis.y.limits <- c(0, 12)

plot <- plot.bars(
	df = plot.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.y.title = plot.axis.y.title,
	axis.y.limits = plot.axis.y.limits,
	data.labels.digits = plot.data.labels.digits
) + plot.theme.title +
	plot.theme.legend.none +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor

plot.save(
	plot = plot,
	width = 5,
	height = 5,
	directory = outdir,
	filename  = paste(experiment.name, "time", sep = "-")
)

if (do_arrange)
{
	plot.time <- plot.bars(
		df = plot.df,
		var.x = plot.x,
		var.y = plot.y,
		factor = plot.factor,
		title = "Latency", 
		legend.title = plot.legend.title,
		legend.labels = plot.legend.labels,
		axis.x.title = plot.axis.x.title,
		axis.x.breaks = plot.axis.x.breaks,
		axis.y.title = plot.axis.y.title,
		axis.y.limits = plot.axis.y.limits,
		data.labels.digits = plot.data.labels.digits
	) + plot.theme.title +
		plot.theme.legend.none +
		plot.theme.axis.x +
		plot.theme.axis.y +
		plot.theme.grid.wall +
		plot.theme.grid.major +
		plot.theme.grid.minor

	force(plot.time)
}

#===============================================================================
# Power
#===============================================================================

#===============================================================================
# Input Reading
#===============================================================================

# Experiment File
power.infile <- paste(
	"./results",
	"cooked",
	experiment.nanvix.version,
	paste(experiment.name, "profile.csv", sep = "-"),
	sep = "/"
)

# Experiment File
power.outfile <- paste(
	"./results",
	"cooked",
	experiment.nanvix.version,
	paste(experiment.name, "power.csv", sep = "-"),
	sep = "/"
)

# Generate power table
power.df.a <- experiment.generate.power(
	experiment.df = read.delim(file = power.infile, sep = ";", header = TRUE),
	experiment.name = experiment.name,
	experiment.outfile = power.outfile,
	experiment.version.baseline = "thread",
	experiment.version.nanvix = "dispatcher"
)
power.df.b <- experiment.generate.power(
	experiment.df = read.delim(file = power.infile, sep = ";", header = TRUE),
	experiment.name = experiment.name,
	experiment.outfile = power.outfile,
	experiment.version.baseline = "user",
	experiment.version.nanvix = "dispatcher"
) %>% filter(version == "user")

power.df <- rbind(power.df.a, power.df.b)

#===============================================================================
# Pre-Processing
#===============================================================================

experiment.df.total <- setNames(
	aggregate(
		x   = experiment.df.cooked$mean,
		by  = list(experiment.df.cooked$version),
		FUN = sum
	),
	c("version", "time")
)

energy.df <- merge(
	experiment.df.total,
	power.df
)

energy.df$energy <- energy.df$power*energy.df$time

#===============================================================================
# Energy Plot
#===============================================================================

plot.df <- energy.df

plot.x      <- "version"
plot.y      <- "energy"
plot.factor <- "version"

# Titles
plot.title    <- "Energy of Core Usage Benchmark"
plot.subtitle <- paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
#plot.legend.title <- "User Scenario"
#plot.legend.labels <- as.factor()

# X Axis

plot.df$version<- factor(plot.df$version, levels=c("user", "thread", "dispatcher"))
levels(plot.df$version) <- c("Sequential", "Parallel", "Tasks")

plot.axis.x.title <- "Use Case Scenario"
plot.axis.x.breaks <- levels(as.factor(plot.df$version))

# Y Axis
plot.axis.y.title <- "Energy (uJ)"

# Data Labels
plot.data.labels.digits <- 1

plot.axis.y.breaks <- seq(from = 0, to = 75, by = 10)
plot.axis.y.limits <- c(0, 75)

plot <- plot.bars(
	df = plot.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.y.title = plot.axis.y.title,
	axis.y.limits = plot.axis.y.limits,
	axis.y.breaks = plot.axis.y.breaks,
	data.labels.digits = plot.data.labels.digits
) + plot.theme.title +
	plot.theme.legend.none +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor

plot.save(
	plot = plot,
	width = 5,
	height = 5,
	directory = outdir,
	filename  = paste(
		experiment.name,
		"energy",
		sep = "-"
	)
)

if (do_arrange)
{
	plot.energy <- plot.bars(
		df = plot.df,
		var.x = plot.x,
		var.y = plot.y,
		factor = plot.factor,
		title = "Energy",
		legend.title = plot.legend.title,
		legend.labels = plot.legend.labels,
		axis.x.title = plot.axis.x.title,
		axis.x.breaks = plot.axis.x.breaks,
		axis.y.title = plot.axis.y.title,
		axis.y.limits = plot.axis.y.limits,
		data.labels.digits = plot.data.labels.digits
	) + plot.theme.title +
		plot.theme.legend.none +
		plot.theme.axis.x +
		plot.theme.axis.y +
		plot.theme.grid.wall +
		plot.theme.grid.major +
		plot.theme.grid.minor

	force(plot.energy)

	arrange <- grid.arrange(
		plot.time,
		plot.energy,
		nrow = 1,
		widths = c(1,1),
		top = textGrob("Heartbeat Performance", gp=gpar(fontsize=20,font=8))
	)

	plot.save(
		plot = arrange,
		width = 5,
		height = 3,
		directory = outdir,
		filename  = paste(
			experiment.name,
			"all",
			sep = "-"
		)
	)
}
