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
source(file = "rscripts/rplots/stacks.R")
source(file = "rscripts/rplots/bars.R")
source(file = "rscripts/rplots/theme.R")
source(file = "rscripts/rplots/utils.R")
source(file = "rscripts/consts.R")

#===============================================================================
# Experiment Information
#===============================================================================

args = commandArgs(trailingOnly=TRUE)

if (length(args) >= 3) {
	experiment.infile <- args[1]
	experiment.outdir <- args[2]
	experiment.outfile <- args[3]
} else {
	experiment.infile <- "./results/cooked/sizes.csv"
	experiment.outdir <- "./results/plots"
	experiment.outfile <- "sizes"
}

#===============================================================================
# Input Reading
#===============================================================================

experiment.df <- read_delim(
	file = experiment.infile,
	col_names = TRUE,
	delim = ";"
)

#kb.df <- experiment.df
#kb.df$size    <- kb.df$total
#kb.df$size_kb <- kb.df$total/KB
#print(subset(kb.df, select = -c(text, data, bss, total)), n=40)

#===============================================================================
# Filter
#===============================================================================

#===============================================================================
# Pre-Processing
#===============================================================================

#-------------------------------------------------------------------------------
# Stack
#-------------------------------------------------------------------------------

# Compute total size
experiment.df$total <- experiment.df$text + experiment.df$data + experiment.df$bss

# Original columns
stack.df <- subset(experiment.df, subset = cluster == "cc", select = -c(cluster, text, data, bss))

stack.factors <- c("runtime", "binary")
stack.variables <- c("total")

#-------------------------------------------------------------------------------
# Total
#-------------------------------------------------------------------------------

stack.with.user <- FALSE

stack.df$total[stack.df$runtime == "baseline" & stack.df$binary == "libhal"] <-
	stack.df$total[stack.df$runtime == "baseline" & stack.df$binary == "libhal"] +
	stack.df$total[stack.df$runtime == "baseline" & stack.df$binary == "barelib"]
stack.df$total[stack.df$runtime == "daemon" & stack.df$binary == "libhal"] <-
	stack.df$total[stack.df$runtime == "daemon" & stack.df$binary == "libhal"] +
	stack.df$total[stack.df$runtime == "daemon" & stack.df$binary == "barelib"]

stack.df <- subset(stack.df, subset = binary != "barelib")

stack.df$total[stack.df$runtime == "daemon" & stack.df$binary == "libkernel"] <-
	stack.df$total[stack.df$runtime == "daemon" & stack.df$binary == "libkernel"] - 3*2*4*KB

agg.df <- aggregate(total ~ runtime, data = subset(stack.df, select = -binary), FUN = sum)

if (stack.with.user) {
	stack.df <- rbind(stack.df, data.frame(runtime="baseline", binary="user", total=2*MB + agg.df$total[agg.df$runtime == "baseline"]))
	stack.df <- rbind(stack.df, data.frame(runtime="daemon", binary="user", total=2*MB + 3*4*KB - agg.df$total[agg.df$runtime == "daemon"]))
}

stack.df$total <- stack.df$total/KB
agg.df$total <- agg.df$total/KB

#===============================================================================
# Stack
#===============================================================================

plot.df <- stack.df

if (stack.with.user) {
	plot.df$binary <- factor(plot.df$binary, levels=c("user", "libmpi", "libruntime", "libc", "libnanvix", "libkernel", "libhal", "barelib"))
	levels(plot.df$binary) <- c("User", "LWMPI", "OS Services", "Ulibc", "LibNanvix", "Microkernel", "HAL", "Barelib")
} else {
	plot.df$binary <- factor(plot.df$binary, levels=c("libmpi", "libruntime", "libc", "libnanvix", "libkernel", "libhal", "barelib"))
	levels(plot.df$binary) <- c("LWMPI", "OS Services", "Ulibc", "LibNanvix", "Microkernel", "HAL", "Barelib")
}

plot.df$runtime <- factor(plot.df$runtime, levels=c("baseline", "daemon"))
levels(plot.df$runtime) <- c("Baseline", "Daemons")

plot.var.x  <- "runtime"
plot.var.y  <- "total"
plot.factor <- "binary"

# Titles
plot.title    <- NULL
plot.subtitle <- NULL

# Legend
plot.legend.title  <- "Section"
plot.legend.labels <- levels(as.factor(plot.df$binary))

# X Axis
plot.axis.x.title  <- "Experimental environment"
plot.axis.x.breaks <- levels(as.factor(plot.df$runtime))
plot.axis.x.labels <- levels(as.factor(plot.df$runtime))

# Y Axis
plot.axis.y.title  <- "Size (kB)"
plot.axis.ymin     <- 0
if (stack.with.user) {
	plot.axis.ymax <- 2048 + 32
} else {
	plot.axis.ymax <- 1280 + 128 + 32
}
plot.axis.y.limits <- c(plot.axis.ymin, plot.axis.ymax + 32)
plot.axis.y.breaks <- seq(from = plot.axis.ymin, to = plot.axis.ymax, by = 128)

if (FALSE) {
	plot <- plot.stacks.grey(
		df = plot.df,
		var.x = plot.var.x,
		var.y = plot.var.y,
		factor = plot.factor,
		axis.x.title = plot.axis.x.title,
		axis.x.breaks = plot.axis.x.breaks,
		axis.x.labels = plot.axis.x.labels,
		axis.y.title = plot.axis.y.title,
		axis.y.breaks = plot.axis.y.breaks,
		axis.y.limits = plot.axis.y.limits,
		legend.title = plot.legend.title,
		legend.labels = plot.legend.labels
	) + plot.theme.title +
		plot.theme.legend.bottom.right +
		plot.theme.axis.x +
		plot.theme.axis.y +
		plot.theme.grid.wall +
		plot.theme.grid.major +
		plot.theme.grid.minor +
		plot.theme.facet.x

	print("Ploting libs...")

	if (length(args) >= 1) {
		plot.save(
			plot,
			height = 5,
			width = 7,
			directory = experiment.outdir,
			filename = paste(experiment.outfile, "all", sep = "-")
		)
	} else {
		plot
	}
}

#==============================================================================
# Plot Configuration
#==============================================================================

print(agg.df)
stack.df <- rbind(stack.df, data.frame(runtime="baseline", binary="total", total=agg.df$total[agg.df$runtime == "baseline"]))
stack.df <- rbind(stack.df, data.frame(runtime="daemon", binary="total", total=agg.df$total[agg.df$runtime == "daemon"]))

plot.df <- stack.df

plot.x  <- "runtime"
plot.y  <- "total"
plot.factor <- "runtime"
plot.facet  <- "binary"

# Titles
plot.title <- NULL#"Response Time of User/Dispatcher Kernel Calls"
plot.subtitle <- NULL#paste("Nanvix Version", experiment.nanvix.version, sep = " ")

plot.df$binary <- factor(plot.df$binary, levels=rev(c("total", "libmpi", "libruntime", "libc", "libnanvix", "libkernel", "libhal", "barelib")))
levels(plot.df$binary) <- rev(c("Total", "LWMPI", "OS Services", "Ulibc", "LibNanvix", "Microkernel", "HAL", "Barelib"))

plot.df$runtime <- factor(plot.df$runtime, levels=c("baseline", "daemon"))
levels(plot.df$runtime) <- c("Baseline", "Daemons")

# Legend
plot.legend.title  <- "Experimental Environment"
plot.legend.labels <- c("Base (Baseline)", "Full")

# X Axis
plot.axis.x.title  <- "Experimental environment"
plot.axis.x.breaks <- c("Base", "Full")
plot.axis.x.labels <- c("Base", "Full")

# Y Axis
plot.axis.y.title  <- "Size (KB)"
plot.axis.ymin     <- 0
plot.axis.ymax     <- 2048
plot.axis.y.limits <- c(plot.axis.ymin, plot.axis.ymax + 32)
plot.axis.y.breaks <- seq(from = plot.axis.ymin, to = plot.axis.ymax, by = 256)

# Data Labels
plot.data.labels.digits <- 0

#===============================================================================
# Plot
#===============================================================================

plot <- plot.bars.facet.colour(
	df = plot.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	facet = plot.facet,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.y.title = plot.axis.y.title,
	axis.y.limits = plot.axis.y.limits,
	axis.y.breaks = plot.axis.y.breaks,
	data.labels.digits = plot.data.labels.digits,
	colour = c("#ca0020", "#0571b0")
) + plot.theme.title +
	plot.theme.legend.top.left +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x

if (length(args) >= 1) {
	plot.save(
		plot,
		height = 5,
		width = 12,
		directory = experiment.outdir,
		filename = paste(experiment.outfile, "real", sep = "-")
	)
} else {
	plot
}

#==============================================================================
# Plot Configuration
#==============================================================================

print(agg.df)
stack.df <- rbind(stack.df, data.frame(runtime="baseline", binary="microkernel",
	total=stack.df$total[stack.df$runtime == "baseline" & stack.df$binary == "libhal"] +
		stack.df$total[stack.df$runtime == "baseline" & stack.df$binary == "libkernel"] +
		stack.df$total[stack.df$runtime == "baseline" & stack.df$binary == "libnanvix"] +
		stack.df$total[stack.df$runtime == "baseline" & stack.df$binary == "libc"]
))
stack.df <- rbind(stack.df, data.frame(runtime="daemon", binary="microkernel",
	total=stack.df$total[stack.df$runtime == "daemon" & stack.df$binary == "libhal"] +
		stack.df$total[stack.df$runtime == "daemon" & stack.df$binary == "libkernel"] +
		stack.df$total[stack.df$runtime == "daemon" & stack.df$binary == "libnanvix"] +
		stack.df$total[stack.df$runtime == "daemon" & stack.df$binary == "libc"]
))

stack.df <- filter(stack.df, binary == "microkernel" | binary == "libruntime" | binary == "libmpi" | binary == "total")

plot.df <- stack.df

plot.x      <- "runtime"
plot.y      <- "total"
plot.factor <- "runtime"
plot.facet  <- "binary"

# Titles
plot.title <- NULL#"Response Time of User/Dispatcher Kernel Calls"
plot.subtitle <- NULL#paste("Nanvix Version", experiment.nanvix.version, sep = " ")

plot.df$binary <- factor(plot.df$binary, levels=rev(c("total", "libmpi", "libruntime", "microkernel")))
levels(plot.df$binary) <- rev(c("Total", "User Library", "Runtime Library", "Microkernel"))

plot.df$runtime <- factor(plot.df$runtime, levels=c("baseline", "daemon"))
levels(plot.df$runtime) <- c("Baseline", "Daemons")

# Legend
plot.legend.title  <- "Experimental Environment"
plot.legend.labels <- c("Base (Baseline)", "Full")

# X Axis
plot.axis.x.title  <- "Experimental environment"
plot.axis.x.breaks <- c("Baseline", "Full")
plot.axis.x.labels <- c("Baseline", "Full")

# Y Axis
plot.axis.y.title  <- "Size (KB)"
plot.axis.ymin     <- 0
plot.axis.ymax     <- 2048
plot.axis.y.limits <- c(plot.axis.ymin, plot.axis.ymax + 32)
plot.axis.y.breaks <- seq(from = plot.axis.ymin, to = plot.axis.ymax, by = 256)

# Data Labels
plot.data.labels.digits <- 0

#===============================================================================
# Plot
#===============================================================================

plot <- plot.bars.facet.colour(
	df = plot.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	facet = plot.facet,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.y.title = plot.axis.y.title,
	axis.y.limits = plot.axis.y.limits,
	axis.y.breaks = plot.axis.y.breaks,
	data.labels.digits = plot.data.labels.digits,
	colour = c("#ca0020", "#0571b0")
) + plot.theme.title +
	plot.theme.legend.none +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x

if (length(args) >= 1) {
	plot.save(
		plot,
		height = 5,
		width = 12,
		directory = experiment.outdir,
		filename = paste(experiment.outfile, "software", sep = "-")
	)
} else {
	plot
}
print("Done.")

#==============================================================================
# Experimental software architecture
#==============================================================================

