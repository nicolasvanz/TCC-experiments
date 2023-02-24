#
# Copyright(C) 2020 Pedro Henrique Penna <pedrohenriquepenna@gmail.com>
#
# All rights reserved.
#

library("ggplot2")
library("RColorBrewer")
library("gcookbook")
library("ggsci")

#devtools::install_github("zeehio/facetscales")
#library(facetscales)

# Plots a line chart.
plot.linespoint <- function(
  df,
  factor, respvar, param,
  title = NULL, subtitle = NULL,
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
  factor, respvar, param, facet,
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
	facet_grid(~ get(facet)) +
	theme_classic()
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
#		guide = FALSE
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
#		guide = FALSE
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
  axis.x.title, axis.x.breaks, axis.x.labels,
  axis.x.trans = "identity",
  axis.y.title, axis.y.limits = NULL,
  axis.y.trans = 'identity',
  axis.y.trans.fn = function(x) x,
  axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
  axis.y.trans.format = math_format()(1:10)
)
{
	ggplot(
		data = df,
		aes(x = get(factor), y = get(respvar), group = get(param))
	) +
	geom_line(
		aes(colour = get(param), linetype = get(param)),
		size = 1
	) +
	geom_point(
		aes(shape = get(param), fill = get(param)),
		size = 3
	) +
	geom_errorbar(
		aes(ymin = get(respvar) - sd, ymax = get(respvar) + sd),
		width = 0.2,
		position = position_dodge(0.05)
	) +
	labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title
	) +
	scale_fill_tron(
		name = legend.title,
		labels = legend.labels
	) +
	scale_shape_manual(
		name = legend.title,
		labels = legend.labels,
		values = c(21, 22, 23, 24, 25)
	) +
	scale_linetype_manual(
		name = legend.title,
		labels = legend.labels,
		values = c(1, 2, 3, 4, 5)
	) +
	scale_color_tron(
		name = legend.title,
		labels = legend.labels
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
	facet_wrap(facet, scales = "free") +
	theme_classic()
	#facet_grid(facet) +
}

## Plots a line with facet chart.
#plot.lines.facet.scales <- function(
#  df,
#  factor, respvar, param, facet,
#  title, subtitle = NULL,
#  legend.title, legend.labels,
#  axis.x.title, axis.x.breaks, axis.x.labels,
#  axis.x.trans = "identity",
#  axis.y.title, axis.y.scales
#)
#{
#	ggplot(
#		data = df,
#		aes(x = get(factor), y = get(respvar), group = get(param))
#	) +
#	geom_line(
#		aes(colour = get(param), linetype = get(param)),
#		size = 1
#	) +
#	geom_point(
#		aes(shape = get(param), fill = get(param)),
#		size = 3
#	) +
#	geom_errorbar(
#		aes(ymin = get(respvar) - sd, ymax = get(respvar) + sd),
#		width = 0.2,
#		position = position_dodge(0.05)
#	) +
#	labs(
#		title = title,
#		subtitle = subtitle,
#		x = axis.x.title,
#		y = axis.y.title
#	) +
#	scale_fill_tron(
#		name = legend.title,
#		labels = legend.labels
#	) +
#	scale_shape_manual(
#		name = legend.title,
#		labels = legend.labels,
#		values = c(21, 22, 23, 24, 25)
#	) +
#	scale_linetype_manual(
#		name = legend.title,
#		labels = legend.labels,
#		values = c(1, 2, 3, 4, 5)
#	) +
#	scale_color_tron(
#		name = legend.title,
#		labels = legend.labels
#	) +
#	scale_x_continuous(
#		breaks = axis.x.breaks,
#		labels = axis.x.labels,
#		trans = axis.x.trans
#	) +
#	facet_grid_sc(facet, scales = list(y = axis.y.scales)) +
#	theme_classic()
#}

# Plots a line with facet chart.
plot.lines.facet2 <- function(
  df,
  factor, respvar, param, facet, interval.size,
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
			(lag(time) < (1*interval.size) & time >= (1*interval.size)) |
			(lag(time) < (2*interval.size) & time >= (2*interval.size)) |
			(lag(time) < (3*interval.size) & time >= (3*interval.size)) |
			(lag(time) < (4*interval.size) & time >= (4*interval.size)) |
			(lag(time) < (5*interval.size) & time >= (5*interval.size)) |
			(lag(time) < (6*interval.size) & time >= (6*interval.size)) |
			(lag(time) < (7*interval.size) & time >= (7*interval.size)) |
			(lag(time) < (8*interval.size) & time >= (8*interval.size)) |
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
		#guide = FALSE
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
		#guide = FALSE
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

# Plots a line chart.
plot.linespoint.colour <- function(
  df,
  factor, respvar, param,
  title = NULL, subtitle = NULL,
  legend.title, legend.labels,
  axis.x.title, axis.x.breaks, axis.x.minor.breaks = NULL,
  axis.x.trans = "log2",
  axis.y.title, axis.y.limits = NULL,
  axis.y.trans = 'identity',
  axis.y.trans.fn = function(x) x,
  axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
  axis.y.trans.format = math_format()(1:10),
  colour = rep("black", 12)
) {
	ggplot(
		data = df,
		aes(x = get(factor), y = get(respvar), group = get(param))
	) +
	geom_line(
		aes(colour = get(param), linetype = get(param)), size = 1.3
	) +
	geom_point(
		aes(shape = get(param), fill = get(param)),
		size = 5
	) +
	labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title
	) +
#	scale_fill_manual(
#		values = colour,
  scale_fill_brewer(
		name = legend.title,
		labels = legend.labels,
#		guide = FALSE
	) +
	scale_shape_manual(
		name = legend.title,
		labels = legend.labels,
		values = c(21, 22, 23, 24, 25, 21, 22, 23, 24, 25, 21)
	) +
#	scale_color_manual(
#		values = colour,
  scale_color_brewer(
		name = legend.title,
		labels = legend.labels,
	) +
	scale_linetype_manual(
		name = legend.title,
		labels = legend.labels,
		values = c(1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1)
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
plot.linespoint.facet.colour <- function(
  df,
  factor, respvar, param, facet,
  title = NULL, subtitle = NULL,
  legend.title, legend.labels,
  axis.x.title, axis.x.breaks, axis.x.labels, axis.x.minor.breaks = NULL,
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
		aes(colour = get(param), linetype = get(param)), size = 1.3
	) +
	geom_point(
		aes(shape = get(param), fill = get(param)),
		size = 5
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
#		guide = FALSE
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
#		guide = FALSE
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
	facet_wrap(~ get(facet), scales = "free", row = 3, col = 7) +
	theme_classic()
}

# Plots a line chart.
plot.linespoint.facet.colour2 <- function(
  df,
  factor, respvar, param, facet,
  title = NULL, subtitle = NULL,
  legend.title, legend.labels,
  axis.x.title, axis.x.breaks, axis.x.labels, axis.x.minor.breaks = NULL,
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
		aes(colour = get(param), linetype = get(param)), size = 1.3
	) +
	geom_point(
		aes(shape = get(param), fill = get(param)),
		size = 5
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
#		guide = FALSE
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
#		guide = FALSE
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
	facet_grid(get(facet) ~ .) +
	theme_classic()
}

