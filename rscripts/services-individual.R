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
library(plyr)
library(ggplot2)
library(reshape2)
library(scales)
library(dplyr, warn.conflicts = FALSE)

# My Utilities
source(file = "rscripts/include/rplots/utils.R")
source(file = "rscripts/include/rplots/theme.R")
source(file = "rscripts/include/rplots/stacks.R")
source(file = "rscripts/include/rplots/bars.R")
source(file = "rscripts/include/utils.R")
source(file = "rscripts/include/consts.R")

#===============================================================================
# Experiment Information
#===============================================================================

experiment.name = "services"
experiment.nanvix.version = "8a71137"

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

variables.id <- c("version", "service")
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

plot.df <- experiment.df.cooked

plot.x      <- "version"
plot.y      <- "mean"
plot.factor <- "service"
plot.facet  <- "service"

# Titles
plot.title <- "Multikernel Services"
plot.subtitle <- paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- ""
plot.legend.labels <- ""

# X Axis
plot.axis.x.title <- "IKC Version"
plot.axis.x.breaks <- levels(as.factor(plot.df$version))

# Y Axis
plot.axis.y.title <- "Time (ms)"

#===============================================================================
# Plot
#===============================================================================

plot.axis.y.breaks <- seq(from = 0, to = 40, by = 5)
plot.axis.y.limits <- c(0, 40)

plot <- plot.stacks(
	df = plot.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	facet = plot.facet,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.y.title = plot.axis.y.title,
	axis.y.breaks = plot.axis.y.breaks,
	axis.y.limits = plot.axis.y.limits,
	title = plot.title,
	subtitle = plot.subtitle
) + plot.theme.title +
	plot.theme.legend.top.right +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x

plot.save(
	plot = plot,
	width = 10,
	height = 6.0,
	directory = outdir,
	filename  = paste(experiment.name, "time-grid", sep = "-")
)

plot.axis.y.breaks <- seq(from = 0, to = 8, by = 2)
plot.axis.y.limits <- c(0, 8)

plot <- plot.stacks2(
	df = plot.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	facet = plot.facet,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.y.title = plot.axis.y.title,
	axis.y.breaks = plot.axis.y.breaks,
	axis.y.limits = plot.axis.y.limits,
	title = plot.title,
	subtitle = plot.subtitle
) + plot.theme.title +
	plot.theme.legend.top.right +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x

plot.save(
	plot = plot,
	width = 10,
	height = 6.0,
	directory = outdir,
	filename  = paste(experiment.name, "time-wrap", sep = "-")
)
