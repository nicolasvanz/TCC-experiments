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
library(stringr)
library(mgcv)

# My Utilities
source(file = "rscripts/rplots/utils.R")
source(file = "rscripts/consts.R")

#===============================================================================
# Spline
#===============================================================================

# We use Left Riemann Sum -> https://en.wikipedia.org/wiki/Riemann_sum
smooth.spline.integrate <- function(model, a, b, n = 1000)
{
	h    <- (b - a) / n
	area <- 0

	for (x in seq(from = a, to = b, length.out = n))
		area <- area + (predict(model, x)$y * h)

	return (area)
}

#===============================================================================
# GAM
#===============================================================================

# We use Left Riemann Sum -> https://en.wikipedia.org/wiki/Riemann_sum
gam.integrate <- function(model, a, b, n = 1000)
{
	h    <- (b - a) / n
	area <- 0

	xs <- data.frame(time  = seq(from = a, to = b, length.out = n))
	ys <- data.frame(power = predict.gam(model, xs))

	for (y in ys$power)
		area <- area + (y * h)

	return (area)
}

#===============================================================================
# Create power table
#===============================================================================

experiment.generate.power <- function(
	experiment.df = NULL,
	experiment.name = NULL,
	experiment.outfile.total = "dummy",
	experiment.outfile.predict = "dummy",
	experiment.outfile.means = "dummy",
	experiment.outfile.all = "dummy",
	experiment.versions = NULL,
	experiment.iteration = 0,
	experiment.apps.time = NULL,
	experiment.return = "total",
	experiment.force.generation = FALSE
)
{
	if (!experiment.force.generation)
	{
		if (experiment.return == "total" & file.exists(experiment.outfile.total))
			return (read.delim(file = experiment.outfile.total, sep = ";", header = TRUE))

		if (experiment.return == "predict" & file.exists(experiment.outfile.predict))
			return (filter(read.delim(file = experiment.outfile.predict, sep = ";", header = TRUE), it == experiment.iteration))

		if (experiment.return == "means" & file.exists(experiment.outfile.means))
			return (filter(read.delim(file = experiment.outfile.means, sep = ";", header = TRUE), it == experiment.iteration))

		if (experiment.return == "all")
			return (filter(experiment.df, component == "power" & it == experiment.iteration & time >= 100))
	}

	#===============================================================================
	# Pre-Processing
	#===============================================================================

	experiment.df.cmp <- filter(experiment.df, component == "power" & time >= 100)
	print(head(experiment.df.cmp))

	power.total.df <- data.frame(
		version = character(0), it = integer(0), nprocs = integer(0), total = double(0), avg = double(0)
	)
	power.predict.df <- data.frame(
		version = character(0), it = integer(0), nprocs = integer(0), time = double(0), power = double(0)
	)
	power.means.df <- data.frame(
		version = character(0), it = integer(0), nprocs = integer(0), group = integer(0), time = double(0), power = double(0)
	)
	interval <- 300

	# Compute means of intervals
	for (currit in unique(experiment.df.cmp$it))
	{
		print(paste("Generating power stats of", currit, "iteration of", experiment.name))

		for (v in unique(experiment.df.cmp$version))
		{
			#print(paste("Do version", v))

			for (p in unique(experiment.df.cmp$nprocs))
			{
				#print(paste("Do nprocs", p))

				#================================================================
				# Total
				#================================================================

				time.limit <- filter(experiment.apps.time,
					api == v & nprocs == (p / 12)
				)$mean[1]

				vi.df <- filter(experiment.df.cmp,
					it == currit & version == v & nprocs == p & time <= (103 + time.limit)
				)

				# Minimum
				vi.x.min <- as.numeric(range(vi.df$time)[1])

				# Decrement boot time.
				vi.df <- vi.df %>% mutate(time = (time - vi.x.min))

				# Regresion
				vi.fit <- gam(power ~ s(time, bs = "cs"), data = vi.df)

				# Integral
				vi.x.min <- as.numeric(range(vi.df$time)[1])
				vi.x.max <- as.numeric(range(vi.df$time)[2])
				ta = vi.x.min
				tb = vi.x.max

				vi.total <- gam.integrate(
					model = vi.fit,
					a = ta,
					b = tb,
					n = 1000
				)
				vi.avg <- vi.total / (tb - ta)

				power.total.df <- rbind(
					power.total.df,
					data.frame(version = v, it = currit, nprocs = p, total = vi.total, avg = vi.avg)
				)

				if (p %in% c(12, 48, 192))
				{
					#================================================================
					# Predict
					#================================================================

					# Generate regression data
					vi.predict.df <- data.frame(
						version = vi.df$version,
						it = currit, 
						nprocs = vi.df$nprocs,
						time = vi.df$time,
						power = predict.gam(vi.fit, data = vi.df)
					)
					power.predict.df <- rbind(power.predict.df, vi.predict.df)

					#================================================================
					# Mean
					#================================================================

					vi.means.df <- vi.df

					# Drop uncomplete interval
					len    <- length(vi.df$time)
					remain <- len %% interval
					vi.means.df <- vi.means.df[1:(len-remain),]

					vi.means.df <- vi.means.df %>%
						group_by(group = gl(length(power) / interval, interval)) %>%
						summarise(power = mean(power))

					# Redefine group
					vi.means.df$nprocs  <- p
					vi.means.df$version <- v
					vi.means.df$time    <- seq(from = 0, to = length(vi.means.df$power) - 1, by = 1)

					# Concatenate data frame
					power.means.df <- rbind(power.means.df, vi.means.df)
				}
			}
		}
	}

	write.table(
		x = power.total.df,
		file = experiment.outfile.total,
		sep = ";",
		append = FALSE,
		quote = FALSE,
		row.names = FALSE
	)

	write.table(
		x = power.predict.df,
		file = experiment.outfile.predict,
		sep = ";",
		append = FALSE,
		quote = FALSE,
		row.names = FALSE
	)

	write.table(
		x = power.means.df,
		file = experiment.outfile.means,
		sep = ";",
		append = FALSE,
		quote = FALSE,
		row.names = FALSE
	)

	if (experiment.return == "predict")
		return(filter(power.predict.df, it == experiment.iteration))
	else if (experiment.return == "means")
		return(filter(power.means.df, it == experiment.iteration))
	else if (experiment.return == "all")
		return (filter(experiment.df.cmp, it == experiment.iteration))

	return(filter(power.total.df, it == experiment.iteration))
}

#===============================================================================
# Create power table
#===============================================================================

experiment.generate.power.services <- function(
	experiment.df,
	experiment.name,
	experiment.outfile.total,
	experiment.versions,
	experiment.iteration = 0,
	experiment.apps.time,
	experiment.return = "total",
	experiment.force.generation = TRUE
)
{
	if (!experiment.force.generation)
	{
		if (experiment.return == "total" & file.exists(experiment.outfile.total))
			return (read.delim(file = experiment.outfile.total, sep = ";", header = TRUE))
	}

	#===============================================================================
	# Pre-Processing
	#===============================================================================

	experiment.df.cmp <- filter(experiment.df,
		component == "power" & it == experiment.iteration & time >= 103
	)

	power.total.df <- data.frame(
		version = character(0), nprocs = integer(0), total = double(0), avg = double(0)
	)
	interval <- 300

	# Compute means of intervals
	for (s in unique(experiment.df.cmp$service))
	{
		for (v in unique(experiment.df.cmp$version))
		{
			for (p in unique(experiment.df.cmp$nprocs))
			{
				#================================================================
				# Total
				#================================================================

				time.limit <- filter(experiment.apps.time,
					service == s & version == v & nprocs == p
				)$mean[1]

				vi.df <- filter(experiment.df.cmp,
					service == s & version == v & nprocs == p & time >= 103
				)

				# Minimum
				vi.x.min <- as.numeric(range(vi.df$time)[1])

				# Decrement boot time.
				vi.df <- vi.df %>% mutate(time = (time - vi.x.min))

				# Regresion
				vi.fit <- gam(power ~ s(time, bs = "cs"), data = vi.df)

				# Integral
				vi.x.min <- as.numeric(range(vi.df$time)[1])
				vi.x.max <- as.numeric(range(vi.df$time)[2])
				ta = vi.x.min
				tb = vi.x.max

				vi.total <- gam.integrate(
					model = vi.fit,
					a = ta,
					b = tb,
					n = 1000
				)
				vi.avg <- vi.total / (tb - ta)

				power.total.df <- rbind(
					power.total.df,
					data.frame(service = s, version = v, nprocs = p, total = vi.total, avg = vi.avg)
				)
			}
		}
	}

	write.table(
		x = power.total.df,
		file = experiment.outfile.total,
		sep = ";",
		append = FALSE,
		quote = FALSE,
		row.names = FALSE
	)

	return(power.total.df)
}

#===============================================================================
# Create power table (SBAC VERSION)
#===============================================================================

experiment.generate.power.sbac <- function(
	experiment.df,
	experiment.name,
	experiment.outfile,
	experiment.version.baseline = "baseline",
	experiment.version.nanvix   = "daemon",
	experiment.iteration = 0,
	experiment.force.generation = TRUE
)
{
	if (file.exists(experiment.outfile) & !experiment.force.generation)
		return (read.delim(file = experiment.outfile, sep = ";", header = TRUE))

	#===============================================================================
	# Pre-Processing
	#===============================================================================

	power.df <- data.frame(
		version = character(),
		kernel  = character(),
		it      = integer(),
		power   = double()
	)

	for (currit in unique(experiment.df$it))
	{
		experiment.df.mppa <- filter(experiment.df, component == "power" & it == currit)
		#experiment.df.ddr0 <- filter(experiment.df, component == "ddr0"  & it == currit)
		#experiment.df.ddr1 <- filter(experiment.df, component == "ddr1"  & it == currit)

		# Baseline
		baseline.df <- filter(experiment.df.mppa, version == experiment.version.baseline & time >= 103)

		if (nrow(baseline.df) != 0)
		{
			# Regresion
			baseline.fit <- gam(power ~ s(time, bs = "cs"), data = baseline.df)

			# Integral
			baseline.x.min <- as.numeric(range(baseline.df$time)[1])
			baseline.x.max <- as.numeric(range(baseline.df$time)[2])
			baseline.ta = baseline.x.min
			baseline.tb = baseline.x.max
			baseline.power.total <- gam.integrate(
				model = baseline.fit,
				a = baseline.ta,
				b = baseline.tb,
				n = 1000
			)
			baseline.power.avg <- baseline.power.total / (baseline.tb - baseline.ta)
		}

		# Nanvix
		nanvix.df <- filter(experiment.df.mppa, version == experiment.version.nanvix & time >= 103)

		if (nrow(nanvix.df) != 0)
		{
			# Regresion
			nanvix.fit <- gam(power ~ s(time, bs = "cs"), data = nanvix.df)

			# Integral
			nanvix.x.min <- as.numeric(range(nanvix.df$time)[1])
			nanvix.x.max <- as.numeric(range(nanvix.df$time)[2])
			nanvix.ta = nanvix.x.min
			nanvix.tb = nanvix.x.max
			nanvix.power.total <- gam.integrate(
				model = nanvix.fit,
				a = nanvix.ta,
				b = nanvix.tb,
				n = 1000
			)
			nanvix.power.avg <- nanvix.power.total / (nanvix.tb - nanvix.ta)
		}

		if (nrow(baseline.df) != 0 && nrow(nanvix.df) != 0)
		{
			power.df <- rbind(
				power.df,
				data.frame(
					version = c(experiment.version.baseline, experiment.version.nanvix),
					kernel  = c(experiment.name, experiment.name),
					it      = c(currit, currit),
					power   = c(baseline.power.avg, nanvix.power.avg)
				)
			)
		}
	}

	write.table(
		x = power.df,
		file = experiment.outfile,
		sep = ";",
		append = FALSE,
		quote = FALSE,
		row.names = FALSE
	)

	return(power.df)
	#return(filter(power.df, it == experiment.iteration))
}
