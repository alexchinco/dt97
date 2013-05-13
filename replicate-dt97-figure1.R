
## Prep workspace
rm(list=ls())
library(foreign)
library(grid)
library(plyr)
library(ggplot2)
library(tikzDevice)
library(reshape)
library(vars)


scl.str.DAT_DIR  <- "~/Dropbox/research/trading_on_coincidences/data/"
scl.str.DAT_NAME <- "dt97-figure1-data.csv"
scl.str.FIG_DIR  <- "~/Dropbox/research/trading_on_coincidences/figures/"










## Load DT97 data from WRDS
mat.dfm.DT97        <- read.csv(paste(scl.str.DAT_DIR, scl.str.DAT_NAME, sep = ""), stringsAsFactors = FALSE)
names(mat.dfm.DT97) <- c("t", "hml", "y")
mat.dfm.DT97$hml    <- mat.dfm.DT97$hml * 100
mat.dfm.DT97$y      <- mat.dfm.DT97$y - 1900









## Plot Figure 1 in Daniel and Titman (1997)
mat.dfm.MEAN        <- ddply(mat.dfm.DT97,
                             c("t"),
                             function(X)mean(X$hml)
                             )
names(mat.dfm.MEAN) <- c("t", "hml")

theme_set(theme_bw())

scl.str.RAW_FILE <- 'dt97-figure1'
scl.str.TEX_FILE <- paste(scl.str.RAW_FILE,'.tex',sep='')
scl.str.PDF_FILE <- paste(scl.str.RAW_FILE,'.pdf',sep='')
scl.str.PNG_FILE <- paste(scl.str.RAW_FILE,'.png',sep='')
scl.str.AUX_FILE <- paste(scl.str.RAW_FILE,'.aux',sep='')
scl.str.LOG_FILE <- paste(scl.str.RAW_FILE,'.log',sep='')

tikz(file = scl.str.TEX_FILE, height = 4, width = 7, standAlone=TRUE)

obj.gg2.PLOT <- ggplot()
obj.gg2.PLOT <- obj.gg2.PLOT + geom_hline(yintercept = 0,
                                          linetype   = 4,
                                          size       = 0.75
                                          )
obj.gg2.PLOT <- obj.gg2.PLOT + geom_path(data = mat.dfm.MEAN,
                                         aes(x = t,
                                             y = hml
                                             ),
                                         size = 2.0
                                         )
obj.gg2.PLOT <- obj.gg2.PLOT + geom_text(data = mat.dfm.DT97,
                                         aes(x     = t,
                                             y     = hml,
                                             label = y,
                                             group = t
                                             ),
                                         size = 1.5
                                         )
obj.gg2.PLOT <- obj.gg2.PLOT + stat_summary(data = mat.dfm.DT97,
                                            aes(x     = t,
                                                y     = hml,
                                                group = t
                                                ),
                                            fun.data = "mean_cl_normal",
                                            geom     = "crossbar",
                                            width    = 0.50,
                                            size     = 0.50
                                            )
obj.gg2.PLOT <- obj.gg2.PLOT + xlab('$\\tau$: Months before Portfolio Formation in July')
obj.gg2.PLOT <- obj.gg2.PLOT + ylab('$r_{\\mathrm{HML},\\tau}$ $(\\%/\\mathrm{Month})$')
obj.gg2.PLOT <- obj.gg2.PLOT + coord_cartesian(ylim = c(-6, 6))
obj.gg2.PLOT <- obj.gg2.PLOT + scale_x_continuous(breaks = c(0, -6, -12, -18, -24, -30, -36, -42))


print(obj.gg2.PLOT)
dev.off()

system(paste('pdflatex', file.path(scl.str.TEX_FILE)), ignore.stdout = TRUE)
system(paste('convert -density 450', file.path(scl.str.PDF_FILE), ' ', file.path(scl.str.PNG_FILE)))
system(paste('mv ', scl.str.PNG_FILE, ' ', scl.str.FIG_DIR, sep = ''))
system(paste('rm ', scl.str.TEX_FILE, sep = ''))
system(paste('mv ', scl.str.PDF_FILE, ' ', scl.str.FIG_DIR, sep = ''))
system(paste('rm ', scl.str.AUX_FILE, sep = ''))
system(paste('rm ', scl.str.LOG_FILE, sep = ''))














