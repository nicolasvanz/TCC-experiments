#
# Copyright(C) 2020 Pedro Henrique Penna <pedrohenriquepenna@gmail.com>
#
# All rights reserved.
#

library("ggplot2")
library("scales")

# Plots a line chart.
plot.timeseries <- function(
  df,
  factor, respvar, param,
  title, subtitle = NULL,
  legend.title, legend.labels,
  axis.x.title,
  axis.y.title, axis.y.limits = NULL,
  axis.y.trans = 'identity',
  axis.y.trans.fn = function(x) x,
  axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
  axis.y.trans.format = math_format()(1:10)
) {
	ggplot(
		data = df,
		aes(x = get(factor), y = get(respvar), color= get(param))
	) +
	labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title
	) +
	scale_color_grey(
		name = legend.title,
		labels = legend.labels,
	) +
	geom_line() +
	scale_y_continuous(
		expand = c(0, 0),
		limits = axis.y.limits,
		trans = axis.y.trans,
		breaks = axis.y.breaks,
		labels = trans_format(axis.y.trans, axis.y.trans.format)
	) +
	theme_classic()
}