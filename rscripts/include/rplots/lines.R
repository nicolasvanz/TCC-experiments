#
# Copyright(C) 2020 Pedro Henrique Penna <pedrohenriquepenna@gmail.com>
#
# All rights reserved.
#

library("ggplot2")

# Plots a line chart.
plot.linespoint <- function(
  df,
  factor, respvar, param,
  title, subtitle = NULL,
  legend.title, legend.labels,
  axis.x.title, axis.x.breaks,
  axis.x.trans = "identity",
  axis.y.title, axis.y.limits = NULL,
  axis.y.trans = 'identity',
  axis.y.trans.fn = function(x) x,
  axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
  axis.y.trans.format = math_format()(1:10),
  colour = c("black", "black", "black", "black")
) {
	ggplot(
		data = df,
		aes(x = get(factor), y = get(respvar), group = get(param))
	) +
	geom_line(
		aes(colour = get(param), linetype = get(param)),
		size = 0.7
	) +
	geom_point(
		aes(shape = get(param), fill = get(param)),
		size = 2.5
	) +
	labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title
	) +
	scale_fill_manual(
		name = legend.title,
		labels = legend.labels,
		values = colour,
		guide = FALSE
	) +
	scale_shape_manual(
		name = legend.title,
		labels = legend.labels,
		values = c(21, 22, 23, 24, 25)
	) +
	scale_color_manual(
		name = legend.title,
		labels = legend.labels,
		values = colour,
		guide = FALSE
	) +
	scale_linetype_manual(
		name = legend.title,
		labels = legend.labels,
		values = c(1, 2, 3, 4, 5)
	) +
	scale_x_continuous(
		breaks = axis.x.breaks,
		trans = axis.x.trans
	) +
	scale_y_continuous(
		expand = c(0, 0),
		limits = axis.y.limits,
		trans = axis.y.trans,
		breaks = axis.y.breaks,
		labels = trans_format(axis.y.trans, axis.y.trans.format)
	) +
	theme_classic()
}


# Plots a line chart.
plot.linespoint2 <- function(
  df,
  factor, respvar, param, facet = NULL,
  title = NULL, subtitle = NULL,
  legend.title, legend.labels,
  axis.x.title, axis.x.breaks, axis.x.labels = NULL,
  axis.x.trans = "identity",
  axis.y.title, axis.y.limits = NULL,
  axis.y.trans = 'identity',
  axis.y.trans.fn = function(x) x,
  axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
  axis.y.trans.format = math_format()(1:10),
  line.size  = 0.7, line.types  = c(1, 2, 3, 4, 5),
  point.size = 2.5, point.types = c(21, 22, 23, 24, 25),
  colours = c("black", "black", "black", "black", "black")
) {
	# Default plot
	g <- ggplot(
		data = df,
		aes(x = get(factor), y = get(respvar), group = get(param))
	)

	# General informations
	g <- g + labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title
	)

	# Line configration
	g <- g + geom_line(
		aes(colour = get(param), linetype = get(param)),
		size = line.size
	) +
	scale_linetype_manual(
		name = legend.title,
		labels = legend.labels,
		values = line.types
	) +
	scale_y_continuous(
		expand = c(0, 0),
		limits = axis.y.limits,
		trans = axis.y.trans,
		breaks = axis.y.breaks,
		labels = trans_format(axis.y.trans, axis.y.trans.format)
	)

	# Points configration
	g <- g + geom_point(
		aes(shape = get(param), fill = get(param)),
		size = point.size
	) +
	scale_fill_manual(
		name = legend.title,
		labels = legend.labels,
		values = colours,
		guide = FALSE
	) +
	scale_shape_manual(
		name = legend.title,
		labels = legend.labels,
		values = point.types
	) +
	scale_color_manual(
		name = legend.title,
		labels = legend.labels,
		values = colours,
		guide = FALSE
	) +
	scale_x_continuous(
		breaks = axis.x.breaks,
		labels = if (is.null(axis.x.labels)) axis.x.breaks else axis.x.labels,
		trans = axis.x.trans
	)

	# Add extra grouping (facets)
	if (!is.null(facet)) {
		g <- g + facet_grid(~ get(facet))
	}

	# Return the plot.
	return (g + theme_classic())
}

# Plots a line chart.
plot.linespoint3 <- function(
  df,
  factor, respvar, param,
  title, subtitle = NULL,
  legend.title, legend.labels,
  axis.x.title, axis.x.breaks, axis.x.labels,
  axis.x.trans = "identity",
  axis.y.title, axis.y.limits = NULL,
  axis.y.trans = 'identity',
  axis.y.trans.fn = function(x) x,
  axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
  axis.y.trans.format = math_format()(1:10),
  colour = c("black", "black", "black", "black")
) {
	ggplot(
		data = df,
		aes(x = get(factor), y = get(respvar), group = get(param))
	) +
	geom_line(
		aes(colour = get(param), linetype = get(param)),
		size = 0.7
	) +
	geom_point(
		aes(shape = get(param), fill = get(param)),
		size = 2.5
	) +
	labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title
	) +
	scale_fill_manual(
		name = legend.title,
		labels = legend.labels,
		values = colour,
		guide = FALSE
	) +
	scale_shape_manual(
		name = legend.title,
		labels = legend.labels,
		values = c(21, 22, 23, 24, 25)
	) +
	scale_color_manual(
		name = legend.title,
		labels = legend.labels,
		values = colour,
		guide = FALSE
	) +
	scale_linetype_manual(
		name = legend.title,
		labels = legend.labels,
		values = c(1, 2, 3, 4, 5)
	) +
	scale_x_continuous(
		breaks = axis.x.breaks,
		labels = axis.x.labels,
		trans = axis.x.trans
	) +
	scale_y_continuous(
		expand = c(0, 0),
		limits = axis.y.limits,
		trans = axis.y.trans,
		breaks = axis.y.breaks,
		labels = trans_format(axis.y.trans, axis.y.trans.format)
	) +
	theme_classic()
}

# Plots a line with facet chart.
plot.lines.facet <- function(
  df,
  factor, respvar, param, facet,
  title, subtitle = NULL,
  legend.title, legend.labels,
  axis.x.title, axis.x.breaks,
  axis.x.trans = "identity",
  axis.y.title, axis.y.limits = NULL,
  axis.y.trans = 'identity',
  axis.y.trans.fn = function(x) x,
  axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
  axis.y.trans.format = math_format()(1:10),
  colour = c("black", "black", "black", "black")
)
{
	ggplot(
		data = df,
		aes(x = get(factor), y = get(respvar), group = get(param))
	) +
	geom_line(
		aes(colour = get(param), linetype = get(param)),
		size = 0.7
	) +
	labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title
	) +
	scale_color_manual(
		name = legend.title,
		labels = legend.labels,
		values = colour,
		guide = FALSE
	) +
	scale_linetype_manual(
		name = legend.title,
		labels = legend.labels,
		values = c(1, 2, 3, 4, 5)
	) +
	scale_x_continuous(
		breaks = axis.x.breaks,
		trans = axis.x.trans
	) +
	scale_y_continuous(
		expand = c(0, 0),
		limits = axis.y.limits,
		trans = axis.y.trans,
		breaks = axis.y.breaks,
		labels = trans_format(axis.y.trans, axis.y.trans.format)
	) +
	facet_grid(~ get(facet)) +
	theme_classic()
}

# Plots a line with facet chart.
plot.lines.facet2 <- function(
  df,
  factor, respvar, param, facet,
  title, subtitle = NULL,
  legend.title, legend.labels,
  axis.x.title, axis.x.breaks,
  axis.x.trans = "identity",
  axis.y.title, axis.y.limits = NULL,
  axis.y.trans = 'identity',
  axis.y.trans.fn = function(x) x,
  axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
  axis.y.trans.format = math_format()(1:10),
  colour = c("black", "black", "black", "black")
)
{
	ggplot(
		data = df,
		aes(x = get(factor), y = get(respvar), group = get(param))
	) +
	geom_line(
		aes(colour = get(param), linetype = get(param)),
		size = 0.7
	) +
	geom_point(
		data = df %>% filter(
			(time < 0.0000001)                |
			(lag(time) < 125  & time >= 125 ) |
			(lag(time) < 250  & time >= 250 ) |
			(lag(time) < 375  & time >= 375 ) |
			(lag(time) < 500  & time >= 500 ) |
			(lag(time) < 625  & time >= 625 ) |
			(lag(time) < 750  & time >= 750 ) |
			(lag(time) < 875  & time >= 875 ) |
			(lag(time) < 875  & time >= 875 ) |
			(lead(time) <= 0.0000001)         |
			(row_number() == n())
		),
		aes(shape = get(param), fill = get(param)),
		size = 2.5
	) +	
	labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title
	) +
	scale_fill_manual(
		name = legend.title,
		labels = legend.labels,
		values = colour,
		guide = FALSE
	) +
	scale_shape_manual(
		name = legend.title,
		labels = legend.labels,
		values = c(21, 22, 23, 24, 25)
	) +
	scale_color_manual(
		name = legend.title,
		labels = legend.labels,
		values = colour,
		guide = FALSE
	) +
	scale_linetype_manual(
		name = legend.title,
		labels = legend.labels,
		values = c(1, 2, 3, 4, 5)
	) +
	scale_x_continuous(
		breaks = axis.x.breaks,
		trans = axis.x.trans
	) +
	scale_y_continuous(
		expand = c(0, 0),
		limits = axis.y.limits,
		trans = axis.y.trans,
		breaks = axis.y.breaks,
		labels = trans_format(axis.y.trans, axis.y.trans.format)
	) +
	facet_grid(~ get(facet)) +
	theme_classic()
}

