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
  title = NULL, subtitle = NULL,
  legend.title, legend.labels,
  axis.x.title, axis.x.breaks, axis.x.minor.breaks = NULL,
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
		aes(colour = get(param))
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
		values = colour,
		guide = FALSE
	) +
	scale_shape_manual(
		name = legend.title,
		labels = legend.labels,
		values = c(21, 22, 23, 24, 25)
	) +
	scale_color_manual(
		values = colour,
		guide = FALSE
	) +
	scale_x_continuous(
		breaks = axis.x.breaks,
		minor_breaks = axis.x.minor.breaks,
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
		aes(colour = get(param))
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
		values = colour,
		guide = FALSE
	) +
	scale_shape_manual(
		name = legend.title,
		labels = legend.labels,
		values = c(21, 22, 23, 24, 25)
	) +
	scale_color_manual(
		values = colour,
		guide = FALSE
	) +
	scale_x_discrete(
		breaks = axis.x.breaks
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
