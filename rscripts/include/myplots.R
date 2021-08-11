#===============================================================================
# Utilities
#===============================================================================

#
# @brief Save a plot into a file.
#
# @param directory Output directory.
# @param filename  Output filename.
# @param plot      Target plot.
# @param width     Plot width.
# @param height    Plot height.
#
plot.save <- function(
	directory = getwd(),
	filename = "plot.pdf",
	plot, width = 7, height = 4
) {
	filename <- paste(directory, filename, sep = "/")
	filename <- paste(filename, "pdf", sep = ".")

	ggsave(
		filename = filename,
		plot = plot,
		width = width,
		height = height
	)
}

#===============================================================================
# Bars Plot
#===============================================================================

plot.bars <- function(
	df,
	var.x, var.y, factor,
	title = NULL, subtitle = NULL,
	axis.x.title, axis.x.breaks = NULL,
	axis.y.title, axis.y.limits = NULL,
	legend.labels = NULL, legend.title = NULL,
	data.labels.hjust = 0.0,
	data.labels.vjust = -0.5,
	data.labels.digits,
	axis.y.trans = 'identity',
	axis.y.trans.fn = function(x) x,
	position = position_dodge(),
	axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
	axis.y.trans.format = math_format()(1:10)
) {
	return (
		ggplot(
			data = df,
			aes(
				x = get(var.x),
				y = get(var.y),
				fill = get(factor)
			)
		) +
		geom_bar(
			stat = "identity",
			width = 0.8,
			colour = "black",
			position = position
		) +
		geom_text(
			aes(
				label = round(get(var.y), data.labels.digits),
				group = get(factor)
			),
			hjust = data.labels.hjust,
			vjust = data.labels.vjust,
			position = position_dodge(width = 0.8),
			angle = 45
		) +
		labs(
			title = title,
			subtitle = subtitle,
			x = axis.x.title,
			y = axis.y.title,
			fill = legend.title
		) +
		scale_x_discrete(
			labels = axis.x.breaks
		) +
		scale_y_continuous(
			expand = c(0, 0),
			limits = axis.y.limits,
			trans = axis.y.trans,
			breaks = axis.y.breaks,
			labels = trans_format(axis.y.trans, axis.y.trans.format)
		) +
		scale_fill_grey(
			labels = legend.labels
		)
	)
}

#===============================================================================
# Bubbles Plot
#===============================================================================

plot.bubbles <- function(
  df,
  var.x, var.y, var.z, factor,
  title, subtitle = NULL,
  legend.title = NULL, legend.labels = NULL,
  axis.x.title, axis.y.title, axis.z.title)
{
	ggplot(
		df,
		aes(
			x = get(var.x),
			y = get(var.y)
		)
	) +
	geom_point(
		aes(
			color = get(factor),
			size = get(var.z)
		),
		alpha = 0.5
	) +
	scale_size(
		name = axis.z.title,
		range = c(05, 14)
	) +
	labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title,
		color = legend.labels
	) +
	theme_classic()
}

#===============================================================================
# Linespoint Plot
#===============================================================================

myTheme <- theme(
	# Legend
	legend.title = element_text(size = 10, color = 'black'),
	legend.text = element_text(size = 10, color = 'black'),
	legend.justification = c(1.0, 0.0),
	legend.position = c(0.98, 0.02),
	legend.background = element_rect(fill="white",size=0.5, linetype="solid",colour ="black"),
	# X Axis
	axis.text.x = element_text(size = 10, color = 'black'),
	axis.title.x = element_text(size = 12, color = 'black', margin = margin(t = 10, r = 0, b = 0, l = 0)),
	# Y Axis
	axis.text.y = element_text(size = 10, color = 'black'),
	axis.title.y = element_text(size = 12, color = 'black', margin = margin(t = 0, r = 5, b = 0, l = 0)),
	# Grid
	panel.border = element_rect(colour = "black", fill = NA, size = 1),
	panel.grid.major = element_line(color = 'gray', size = 0.2, linetype = 'dashed'),
	panel.grid.minor = element_line(color = 'gray', size = 0.1, linetype = 'dashed')
)

myTheme2 <- theme (
	# Legend
	legend.text = element_text(size = 10, color = 'black'),
	legend.justification = c(0.0, 1.0),
	legend.position = c(0.02, 0.98),
	legend.background = element_rect(fill="white", size=0.5, linetype="solid", colour ="black"),

	# X Axis
	axis.text.x = element_text(size = 10, color = 'black'),
	axis.title.x = element_text(size = 12, color = 'black', margin = margin(t = 10, r = 0, b = 0, l = 0)),
	# Y Axis
	axis.text.y = element_text(size = 10, color = 'black'),
	axis.title.y = element_text(size = 12, color = 'black', margin = margin(t = 0, r = 5, b = 0, l = 0)),
	# Grid
	panel.border = element_rect(colour = "black", fill = NA, size = 1),
	panel.grid.major = element_line(color = 'gray', size = 0.2, linetype = 'dashed'),
	panel.grid.minor = element_line(color = 'gray', size = 0.1, linetype = 'dashed')
)

myTheme3 <- theme(
	# Legend
	legend.text = element_text(size = 10, color = 'black'),
	legend.background = element_rect(fill="white", size=0.5, linetype="solid", colour ="black"),

	# X Axis
	axis.text.x = element_text(size = 10, color = 'black'),
	axis.title.x = element_text(size = 12, color = 'black', margin = margin(t = 10, r = 0, b = 0, l = 0)),
	# Y Axis
	axis.text.y = element_text(size = 10, color = 'black'),
	axis.title.y = element_text(size = 12, color = 'black', margin = margin(t = 0, r = 5, b = 0, l = 0)),
	# Grid
	panel.border = element_rect(colour = "black", fill = NA, size = 1),
	panel.grid.major = element_line(color = 'gray', size = 0.2, linetype = 'dashed'),
	panel.grid.minor = element_line(color = 'gray', size = 0.1, linetype = 'dashed')
)


plot.linespoint <- function(
  df,
  factor, respvar, param,
  title, subtitle = NULL,
  legend.title, legend.labels,
  axis.x.title, axis.x.breaks,
  axis.y.title, axis.y.limits = NULL,
  axis.y.trans = 'identity',
  axis.y.trans.fn = function(x) x,
  axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
  axis.y.trans.format = math_format()(1:10))
{
ggplot(
    data = df,
    aes(x = get(factor), y = get(respvar), group = get(param))
  ) +
	geom_line() +
	geom_point(
		aes(shape = get(param)),
		fill = "black"
	) +
  labs(
    title = title,
    subtitle = subtitle,
    x = axis.x.title,
    y = axis.y.title
  ) +
  scale_shape_manual(
    name = legend.title,
    labels = legend.labels,
	values = c(21, 22, 23, 24, 25)

  ) +
  scale_x_continuous(
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

#===============================================================================
# Legend
#===============================================================================

# Bottom Right
plot.theme.legend.bottom.right <-  theme(
	legend.text = element_text(size = 10, color = 'black'),
	legend.justification = c(1.0, 0.0),
	legend.position = c(0.98, 0.02),
	legend.background = element_rect(fill="white", size=0.5, linetype="solid", colour ="black")
)

# Top Right
plot.theme.legend.top.right <-  theme(
	legend.text = element_text(size = 10, color = 'black'),
	legend.justification = c(1.0, 1.0),
	legend.position = c(0.98, 0.98),
	legend.background = element_rect(fill="white", size=0.5, linetype="solid", colour ="black")
)

# Top Left
plot.theme.legend.top.left <-  theme(
	legend.text = element_text(size = 10, color = 'black'),
	legend.justification = c(0.0, 1.0),
	legend.position = c(0.02, 0.98),
	legend.background = element_rect(fill="white", size=0.5, linetype="solid", colour ="black")
)

# None
plot.theme.legend.none <- theme(legend.position = "none")

#===============================================================================
# Grid
#===============================================================================

# Grid Wall
plot.theme.grid.wall <- theme(
	panel.border = element_rect(colour = "black", fill = NA, size = 1),
	plot.margin = unit(c(5.5,12,5.5,5.5), "pt")
)

# Major Grid
plot.theme.grid.major <- theme(
	panel.grid.major = element_line(color = 'gray', size = 0.2, linetype = 'dashed')
)

# Minor Grid
plot.theme.grid.minor <- theme(
	panel.grid.minor = element_line(color = 'gray', size = 0.1, linetype = 'dashed')
)

# Y Axis
plot.theme.axis.y <- theme(
	axis.text.y = element_text(size = 10, color = 'black'),
	axis.title.y = element_text(size = 12, color = 'black', margin = margin(t = 0, r = 5, b = 0, l = 0))
)

# X Axis
plot.theme.axis.x <- theme(
	axis.text.x = element_text(size = 10, color = 'black'),
	axis.title.x = element_text(size = 12, color = 'black', margin = margin(t = 10, r = 0, b = 0, l = 0))
)
