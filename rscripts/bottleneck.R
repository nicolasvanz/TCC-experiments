
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
library(ggstatsplot)

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

args <- commandArgs(trailingOnly = TRUE)

if (length(args) >= 3) {
	experiment.infile <- args[1]
	experiment.outdir <- args[2]
	experiment.outfile <- args[3]
} else {
	experiment.infile <- "./results/cooked/bottleneck"
	experiment.outdir <- "./results/plots"
	experiment.outfile <- "bottleneck"
}

experiment.power.it <- 0

#===============================================================================
# Input Reading
#===============================================================================

experiment.df <- read_delim(
	file = experiment.infile,
	col_names = TRUE,
	delim = ";"
)
experiment.df <- filter(experiment.df, it < 14 | it > 38)

result.df <- data.frame(
  kernel=character(),
  it=numeric(),
  tasks=numeric(),
  size=numeric(),
  unit=numeric(),
  both=numeric(),
  work=numeric()
)
for (nkernel in c("total")) {
  for (ntasks in 2^seq(0,10)) {
    for (nsize in 2^seq(0,18)) {
      stats.df <- filter(experiment.df, kernel == nkernel & tasks == ntasks & size == nsize)

      #print(paste(nkernel, ntasks, nsize, nrow(stats.df)))
      #plot(ggbetweenstats(stats.df, kernel, engine, outlier.tagging = TRUE))
      #boxplot(stats.df$both, plot=TRUE)
      #readline(prompt = "Press [enter] to get the square of x.")


#find Q1, Q3, and interquartile range for values in column A
      Q1 <- quantile(stats.df$dispatch, .25)
      Q3 <- quantile(stats.df$dispatch, .75)
      IQR <- IQR(stats.df$dispatch)

#only keep rows in dataframe that have values within 1.5*IQR of Q1 and Q3
      if (!is.na(IQR) & IQR > 0) {
        stats.df <- subset(stats.df, stats.df$dispatch > (Q1 - 1.5*IQR) & stats.df$dispatch < (Q3 + 1.5*IQR))
      }


#find Q1, Q3, and interquartile range for values in column A
      Q1 <- quantile(stats.df$wait, .25)
      Q3 <- quantile(stats.df$wait, .75)
      IQR <- IQR(stats.df$wait)

#only keep rows in dataframe that have values within 1.5*IQR of Q1 and Q3
      if (!is.na(IQR) & IQR > 0) {
        stats.df <- subset(stats.df, stats.df$wait > (Q1 - 1.5*IQR) & stats.df$wait < (Q3 + 1.5*IQR))
      }

      #print(paste(nkernel, ntasks, nsize, nrow(stats.df), IQR))
      #plot(ggbetweenstats(stats.df, kernel, work, outlier.tagging = TRUE))
      #readline(prompt = "Press [enter] to get the square of x.\n")

#find Q1, Q3, and interquartile range for values in column A
      Q1 <- quantile(stats.df$work, .25)
      Q3 <- quantile(stats.df$work, .75)
      IQR <- IQR(stats.df$work)

#only keep rows in dataframe that have values within 1.5*IQR of Q1 and Q3
      if (!is.na(IQR) & IQR > 0) {
        stats.df <- subset(stats.df, stats.df$work > (Q1 - 1.5*IQR) & stats.df$work < (Q3 + 1.5*IQR))
      }
      #print(paste(nkernel, ntasks, nsize, nrow(stats.df), IQR))

      if (nrow(stats.df) == 0) {
        print(paste(nkernel, ntasks, nsize, nrow(stats.df), IQR))
      }
      result.df <- rbind(result.df, stats.df)
    }
  }
}

experiment.df <- result.df
print(head(experiment.df))

#===============================================================================
# Filter
#===============================================================================

# Convert cycles to ms
#experiment.df$total <- experiment.df$total / experiment.df$tasks
#experiment.df$total_for <- experiment.df$total_for / experiment.df$tasks

both.df <- filter(experiment.df, kernel == "total", size %in% c(1024, 16384, 262144))
both.df$engine <- both.df$dispatch + both.df$wait - both.df$work
both.df$dispatch <- both.df$dispatch / MPPA.FREQ / MILLI
both.df$wait <- both.df$wait / MPPA.FREQ / MILLI
both.df$work <- both.df$work / MPPA.FREQ / MILLI
both.df$engine <- both.df$engine / MPPA.FREQ / MILLI

both.df <- pivot_longer(both.df,
	cols = c("dispatch", "wait", "work", "engine"),
	names_to = "type",
	values_to = "time"
)

#experiment.df <- experiment.df %>%
#	mutate(amount = ifelse(ndispatchers == 1 & nusers == 0, 0, nusers + ndispatchers))

# Pre-Processing
#===============================================================================

variables.id <- c("tasks", "size", "type")
variables <- c("time")

both.df.melted <- melt(
	data = both.df,
	id.vars = variables.id,
	measure.vars = variables
)

both.df.cooked <- ddply(
	both.df.melted,
	c(variables.id, "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)

both.df.cooked <- filter(both.df.cooked, type != "engine" & type != "wait")

#===============================================================================
# Plot
#===============================================================================

plot.df <- both.df.cooked 
plot.df <- plot.df %>%
  mutate(size_str=
    ifelse(size == 128, "128",
    ifelse(size == 256, "256",
    ifelse(size == 512, "512",
    ifelse(size == 1024, "1K",
    ifelse(size == 2048, "2K",
    ifelse(size == 4096, "4K",
    ifelse(size == 8192, "8K",
    ifelse(size == 16384, "16K",
    ifelse(size == 32768, "32K",
    ifelse(size == 65536, "64K",
    ifelse(size == 131072, "128K",
    "256K"
    )))))))))))
  )

print(plot.df)

plot.x      <- "tasks"
plot.y      <- "mean"
plot.factor <- "type"
plot.facet  <- "size_str"

# Titles
plot.title    <- NULL#"Energy of Core Usage Benchmark"
plot.subtitle <- NULL#paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- "Operation"
plot.legend.labels <- c("Overhead", "Computation")

# X Axis
plot.axis.x.title <- "Number of Tasks"
plot.axis.x.breaks <- as.numeric(levels(as.factor(plot.df$tasks)))
plot.axis.x.labels <- c("1", "2", "4", "8", "16", "32", "64", "128", "256", "512", "1024")

#facet
plot.df$size_str <- factor(
  plot.df$size_str,
  c("128", "256", "512", "1K", "2K", "4K", "8K", "16K", "32K", "64K", "128K", "256K")
)

# Y Axis
plot.axis.y.title <- "Time (s)"

# Data Labels
plot.data.labels.digits <- 3

plot.axis.y.breaks <- seq(from = 0, to = 15, by = 2.5) # by = 10
plot.axis.y.limits <- c(0, 15)

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
	axis.x.labels = plot.axis.x.labels,
  axis.x.trans = "log2",
	axis.y.title = plot.axis.y.title,
	data.labels.digits = plot.data.labels.digits,
	data.labels.angle = 85,
	colour = c("#0571b0", "#ca0020")
) + plot.theme.title +
	plot.theme.legend.top.left +
  plot.theme.axis.x.angle(30) +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x +
	plot.theme.facet.y

plot.save(
	plot = plot,
	width = 18,
	height = 5,
	directory = experiment.outdir,
	filename  = paste(
		experiment.outfile,
		"bars-total",
		sep = "-"
	)
)

#===============================================================================
# Plot
#===============================================================================
print("hello")

plot.df <- plot.df %>%
  mutate(size_str= paste(size_str, type, sep="_"))
plot.df <- filter(plot.df, size_str %in% c("1K_dispatch", "1K_work", "16K_work", "256K_work"))

print(plot.df)
print(filter(plot.df, size_str == "1K_dispatch"))

plot.x      <- "tasks"
plot.y      <- "mean"
plot.factor <- "size_str"

# Titles
plot.title    <- NULL#"Energy of Core Usage Benchmark"
plot.subtitle <- NULL#paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- "Operation"
plot.legend.labels <- c("Engine Overhead", "Workload (1K)", "Workload (16K)", "Workload (256K)")

# X Axis
plot.axis.x.title <- "Number of Tasks"
plot.axis.x.breaks <- as.numeric(levels(as.factor(plot.df$tasks)))
plot.axis.x.labels <- c("1", "2", "4", "8", "16", "32", "64", "128", "256", "512", "1024")

#facet
plot.df$size_str <- factor(
  plot.df$size_str,
  c("1K_dispatch", "1K_work", "16K_work", "256K_work")
)

# Y Axis
plot.axis.y.title <- "Time (s)"

# Data Labels
plot.data.labels.digits <- 3

plot.axis.y.breaks <- seq(from = 0, to = 15, by = 2.5) # by = 10
plot.axis.y.limits <- c(0, 15)

plot <- plot.bars.colour.bottleneck(
	df = plot.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.x.labels = plot.axis.x.labels,
  axis.x.trans = "log2",
	axis.y.title = plot.axis.y.title,
	data.labels.digits = plot.data.labels.digits,
	data.labels.angle = 85,
	colour = c("#ca0021", "#3182bd", "#9ecae1", "#deebf7")
) + plot.theme.title +
	plot.theme.legend.top.left +
  plot.theme.axis.x.angle(0) +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x +
	plot.theme.facet.y

plot.save(
	plot = plot,
	width = 15,
	height = 5,
	directory = experiment.outdir,
	filename  = paste(
		experiment.outfile,
		"bars-reduced",
		sep = "-"
	)
)
exit(0)

 # ========= plot

plot.df <- experiment.df.cooked


plot.x      <- "size"
plot.y      <- "mean"
plot.factor <- "tasks"

# Titles
plot.title <- NULL#"Response Time of User/Dispatcher Kernel Calls"
plot.subtitle <- NULL#paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- "Number of Tasks"
plot.legend.labels <- levels(as.factor(plot.df$tasks))

plot.df$tasks <- as.factor(plot.df$tasks)

# X Axis
plot.axis.x.title <- "Number of Operations"
plot.axis.x.breaks <- as.numeric(levels(as.factor(plot.df$size)))
plot.axis.x.breaks <- 2^seq(0, 10)
print(plot.axis.x.breaks)
#plot.axis.x.minor.breaks <- seq(from = 1, to = max(plot.df$amount))

# Y Axis
plot.axis.y.title <- "Time (ms)"
plot.axis.y.breaks <- seq(from = 0, to = 100, by = 25) # by = 10
plot.axis.y.limits <- c(0, 100)

plot.thread <- plot.stacks.colour(
	df = plot.thread.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	facet = plot.facet,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.x.labels = plot.axis.x.labels,
	axis.y.title = plot.axis.y.title,
	axis.y.breaks = plot.axis.y.breaks,
	axis.y.limits = plot.axis.y.limits,
	legend.title = plot.legend.title,
	legend.labels = plot.thread.legend.labels
) + plot.theme.title +
	plot.theme.legend.top.left +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x

plot <- plot.linespoint.colour(
	df = plot.df,
	factor = plot.x,
	respvar = plot.y,
	param = plot.factor,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.x.labels = plot.axis.x.labels,
	axis.y.title = plot.axis.y.title,
	axis.y.limits = plot.axis.y.limits,
	axis.y.breaks = plot.axis.y.breaks,
	colour = c("#ca0020", "#fddbc7", "#0571b0", "#ca0020", "#fddbc7", "#0571b0", "#ca0020", "#fddbc7", "#0571b0", "#ca0020", "#fddbc7", "#0571b0", "#ca0020", "#fddbc7", "#0571b0")
) + plot.theme.title +
	plot.theme.legend.top.left +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major
	#axis.x.minor.breaks = plot.axis.x.minor.breaks,

#axis.y.trans = "log10",
#axis.y.trans.format = math_format(expr = 10^.x)

plot.save(
	plot = plot,
	width = 8,
	height = 5,
	directory = experiment.outdir,
	filename  = paste(
		experiment.outfile,
		"time-all",
		sep = "-"
	)
)


exit(0)


#==============================================================================
# Plot Configuration
#==============================================================================

plot.df <- experiment.df.cooked

plot.x = "tasks"
plot.y = "mean"
plot.factor = "size"

# Titles
plot.title <- NULL#"Response Time of User/Dispatcher Kernel Calls"
plot.subtitle <- NULL#paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- ""
plot.legend.labels <- ""

# X Axis
plot.axis.x.title <- "Number of Tasks"
plot.axis.x.breaks <- as.character(levels(as.factor(plot.df$tasks)))

# Y Axis
plot.axis.y.title <- "Time (ms)"
plot.axis.y.breaks <- seq(from = 0, to = max(plot.df$mean)) # by = 10
plot.axis.y.limits <- c(0, max(plot.df$mean))

# Data Labels
plot.data.labels.digits <- 2

#===============================================================================
# Plot
#===============================================================================

plot <- plot.linespoint(
	df = plot.df,
	factor = plot.x,
	respvar = plot.y,
	param = plot.factor,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.y.title = plot.axis.y.title,
) + plot.theme.title +
	plot.theme.legend.none +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor

plot.save(
	plot = plot,
	width = 8,
	height = 5,
	directory = experiment.outdir,
	filename  = paste(
		experiment.outfile,
		"time",
		sep = "-"
	)
)
