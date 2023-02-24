#
# Copyright(C) 2020 Pedro Henrique Penna <pedrohenriquepenna@gmail.com>
#
# All rights reserved.
#

library("ggplot2")

#===============================================================================
# Title
#===============================================================================

# Bottom Right
plot.theme.title <- theme(
	plot.title = element_text(size = 15),
	plot.subtitle = element_text(size = 13)
)

#===============================================================================
# Legend
#===============================================================================

# Bottom Right
plot.theme.legend.bottom.right <- theme(
	legend.title = element_text(size = 15, color = 'black'),
	legend.text = element_text(size = 14, color = 'black'),
	legend.justification = c(1.0, 0.0),
	legend.position = c(0.995, 0.02),
	legend.background = element_rect(fill="white", size=0.5, linetype="solid", colour ="black")
)

# Bottom Right
plot.theme.legend.bottom.right2 <- theme(
	legend.title = element_text(size = 15, color = 'black'),
	legend.text = element_text(size = 14, color = 'black'),
	legend.justification = c(1.0, 0.0),
	legend.position = c(0.98, 0.1),
	legend.background = element_rect(fill="white", size=0.5, linetype="solid", colour ="black")
)

# Top Right
plot.theme.legend.top.right <- theme(
	legend.title = element_text(size = 15, color = 'black'),
	legend.text = element_text(size = 14, color = 'black'),
	legend.justification = c(1.0, 1.0),
	legend.position = c(0.98, 0.98),
	legend.background = element_rect(fill="white", size=0.5, linetype="solid", colour ="black")
)

# Top Right
plot.theme.legend.top.right2 <- theme(
	legend.title = element_text(size = 15, color = 'black'),
	legend.text = element_text(size = 14, color = 'black'),
	legend.justification = c(1.0, 1.0),
	legend.position = c(0.98, 0.96),
	legend.background = element_rect(fill="white", size=0.5, linetype="solid", colour ="black")
)

# Center Right
plot.theme.legend.center.right <- theme(
	legend.title = element_text(size = 15, color = 'black'),
	legend.text = element_text(size = 14, color = 'black'),
	legend.justification = c(1.0, 1.0),
	legend.position = c(0.98, 0.70),
	legend.background = element_rect(fill="white", size=0.5, linetype="solid", colour ="black")
)

# Bottom Left
plot.theme.legend.bottom.left <- theme(
	legend.title = element_text(size = 15, color = 'black'),
	legend.text = element_text(size = 14, color = 'black'),
	legend.justification = c(0.0, 0.0),
	legend.position = c(0.02, 0.02),
	legend.background = element_rect(fill="white", size=0.5, linetype="solid", colour ="black")
)

# Top Left
plot.theme.legend.top.left <- theme(
	legend.title = element_text(size = 15, color = 'black'),
	legend.text = element_text(size = 14, color = 'black'),
	legend.justification = c(0.0, 1.0),
	legend.position = c(0.02, 0.98),
	legend.background = element_rect(fill="white", size=0.5, linetype="solid", colour ="black")
)

# Top Left
plot.theme.legend.top.left2 <- theme(
	legend.title = element_text(size = 15, color = 'black'),
	legend.text = element_text(size = 14, color = 'black'),
	legend.justification = c(0.0, 1.0),
	legend.position = c(0.01, 0.99),
	legend.background = element_rect(fill="white", size=0.5, linetype="solid", colour ="black")
)

# None
plot.theme.legend.none <- theme(legend.position = "none")

#===============================================================================
# Grid
#===============================================================================

# Grid Wall
plot.theme.grid.wall <- theme(
	panel.border = element_blank(),#element_rect(colour = "gray", fill = NA, size = 1),
	plot.margin = margin(t = 12.0, r = 12.0, b = 6.0, l = 6.0)
)

# Major Grid
plot.theme.grid.major <- theme(
	panel.grid.major = element_line(color = 'gray', size = 0.2, linetype = 'dashed')
)

# Minor Grid
plot.theme.grid.minor <- theme(
	panel.grid.minor = element_line(color = 'gray', size = 0.1, linetype = 'dashed')
)

#===============================================================================
# Axis
#===============================================================================

# Y Axis
plot.theme.axis.y <- theme(
	axis.title.y = element_text(size = 18, color = 'black', margin = margin(t = 0, r = 5, b = 0, l = 0)),
	axis.text.y = element_text(size = 14, color = 'black'),
	axis.line.y = element_line(color = "black", size = 0.5)
)

# X Axis
plot.theme.axis.x <- theme(
	axis.title.x = element_text(size = 18, color = 'black', margin = margin(t = 10, r = 0, b = 0, l = 0)),
	axis.text.x = element_text(size = 14, color = 'black'),
	axis.line.x = element_line(color = "black", size = 0.5)
)

plot.theme.axis.x.specific <- function(
	title.size = 18,
	text.size = 14,
	text.angle = 0
) {
	theme(
		axis.title.x = element_text(size = title.size, color = 'black', margin = margin(t = 10, r = 0, b = 0, l = 0)),
		axis.text.x = element_text(size = text.size, angle = text.angle, color = 'black'),
		axis.line.x = element_line(color = "black", size = 0.5)
	)
}

# X Axis
plot.theme.axis.x.angle <- function(angle = 90) {
	theme(
		axis.title.x = element_text(size = 18, color = 'black', margin = margin(t = 10, r = 0, b = 0, l = 0)),
		axis.text.x = element_text(size = 14, color = 'black', angle = angle, vjust = 0.5),
	  axis.line.x = element_line(color = "black", size = 0.5)
	)
}

#===============================================================================
# Facet
#===============================================================================

# Y Axis
plot.theme.facet.y <- theme(
	panel.spacing.y = unit(1, "lines"),
	strip.text.y = element_text(size = 14.5, color = 'black'),
	strip.background = element_rect(color="black", fill="grey90", size=1, linetype="solid")
)

# X Axis
plot.theme.facet.x <- theme(
	panel.spacing.x = unit(0.2, "lines"),
	strip.text.x = element_text(size = 14.5, color = 'black'),
	strip.background = element_rect(color="black", fill="grey90", size=0.8, linetype="solid")
)

# X Axis
plot.theme.facet.x2 <- theme(
	panel.spacing.x = unit(0.5, "lines"),
	strip.text.x = element_text(size = 14.5, color = 'black'),
	strip.background = element_rect(color="black", fill="grey90", size=0.8, linetype="solid")
)

