
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
scl.str.DAT_NAME <- "ff93-factors.csv"
scl.str.FIG_DIR  <- "~/Dropbox/research/trading_on_coincidences/figures/"










## Load FF93 factor data
mat.dfm.FF93       <- read.csv(paste(scl.str.DAT_DIR, scl.str.DAT_NAME, sep = ""), stringsAsFactors = FALSE)
mat.dfm.FF93$year  <- floor(mat.dfm.FF93$DATE/10000)
mat.dfm.FF93$month <- floor((mat.dfm.FF93$DATE - mat.dfm.FF93$year * 10000)/100)
mat.dfm.FF93$t     <- mat.dfm.FF93$year + (mat.dfm.FF93$month - 1)/12
mat.dfm.FF93       <- mat.dfm.FF93[mat.dfm.FF93$t >= 1963.5, ]
mat.dfm.FF93$retx  <- (mat.dfm.FF93$ret - mat.dfm.FF93$rf) * 100
mat.dfm.FF93$mkt   <- mat.dfm.FF93$mkt * 100
mat.dfm.FF93$smb   <- mat.dfm.FF93$smb * 100
mat.dfm.FF93$hml   <- mat.dfm.FF93$hml * 100










## Replicate Table 1 in Daniel and Titman (1997)
mat.dfm.TABLE1a  <- cast(mat.dfm.FF93[, c("sizePortfolio", "bookToMarketPortfolio", "retx")],
                         sizePortfolio ~ bookToMarketPortfolio,
                         fun.aggregate = mean
                         )
mat.dfm.TABLE1b  <- cast(mat.dfm.FF93[mat.dfm.FF93$month == 1, c("sizePortfolio", "bookToMarketPortfolio", "retx")],
                         sizePortfolio ~ bookToMarketPortfolio,
                         fun.aggregate = mean
                         )
mat.dfm.TABLE1c  <- cast(mat.dfm.FF93[mat.dfm.FF93$month != 1, c("sizePortfolio", "bookToMarketPortfolio", "retx")],
                         sizePortfolio ~ bookToMarketPortfolio,
                         fun.aggregate = mean
                         )












## Plot Figures 20.12 and 20.13 from Cochrane (2001)
mat.dfm.PLOT        <- ddply(mat.dfm.FF93,
                             c("sizePortfolio", "bookToMarketPortfolio"),
                             function(X)c(mean(X$retx),
                                          - lm(X$retx ~ X$mkt + X$hml + X$smb)$coef[1] + mean(X$retx)
                                          )
                             )
names(mat.dfm.PLOT) <- c("sizePortfolio", "bookToMarketPortfolio", "mean", "predicted")

mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S1", ]$sizePortfolio <- "$S_{\\mathrm{Low}}$"
mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S2", ]$sizePortfolio <- "${}S_2$"
mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S3", ]$sizePortfolio <- "${}S_3$"
mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S4", ]$sizePortfolio <- "${}S_4$"
mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S5", ]$sizePortfolio <- "${}S_{\\mathrm{High}}$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio == "V1", ]$bookToMarketPortfolio <- "$\\mathrm{BM}_{\\mathrm{Low}}$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio == "V2", ]$bookToMarketPortfolio <- "${}\\mathrm{BM}_2$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio == "V3", ]$bookToMarketPortfolio <- "${}\\mathrm{BM}_3$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio == "V4", ]$bookToMarketPortfolio <- "${}\\mathrm{BM}_4$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio == "V5", ]$bookToMarketPortfolio <- "${}\\mathrm{BM}_{\\mathrm{High}}$"

theme_set(theme_bw())

obj.vplayout <- function(x, y) viewport(layout.pos.row = x, layout.pos.col = y)

scl.str.RAW_FILE <- 'cochrane01-famaFrench93-vs-5x5sort'
scl.str.TEX_FILE <- paste(scl.str.RAW_FILE,'.tex',sep='')
scl.str.PDF_FILE <- paste(scl.str.RAW_FILE,'.pdf',sep='')
scl.str.PNG_FILE <- paste(scl.str.RAW_FILE,'.png',sep='')
scl.str.AUX_FILE <- paste(scl.str.RAW_FILE,'.aux',sep='')
scl.str.LOG_FILE <- paste(scl.str.RAW_FILE,'.log',sep='')

tikz(file = scl.str.TEX_FILE, height = 4, width = 7, standAlone=TRUE)

## 20.12
obj.gg2.PLOT1 <- ggplot()
obj.gg2.PLOT1 <- obj.gg2.PLOT1 + geom_point(data = mat.dfm.PLOT,
                                          aes(x      = predicted,
                                              y      = mean,
                                              group  = bookToMarketPortfolio,
                                              colour = bookToMarketPortfolio
                                              )
                                          )
obj.gg2.PLOT1 <- obj.gg2.PLOT1 + geom_path(data = mat.dfm.PLOT,
                                         aes(x      = predicted,
                                             y      = mean,
                                             group  = bookToMarketPortfolio,
                                             colour = bookToMarketPortfolio
                                             )
                                         )
obj.gg2.PLOT1 <- obj.gg2.PLOT1 + xlab('')
obj.gg2.PLOT1 <- obj.gg2.PLOT1 + ylab('')
obj.gg2.PLOT1 <- obj.gg2.PLOT1 + opts(legend.position = c(0.25,0.80))
obj.gg2.PLOT1 <- obj.gg2.PLOT1 + labs(group = "", colour = "")
obj.gg2.PLOT1 <- obj.gg2.PLOT1 + theme(plot.margin = unit(c(0.5,0,0,0), "lines"),
                                       axis.title.x = element_text(size = rel(0)),
                                       axis.title.y = element_text(size = rel(0)),
                                       axis.text.y = element_text(size = rel(0.75)),
                                       axis.text.x = element_text(size = rel(0.75)),
                                       axis.ticks  = theme_segment(colour = "black", size = rel(0.25))
                                       )


## 20.13
obj.gg2.PLOT2 <- ggplot()
obj.gg2.PLOT2 <- obj.gg2.PLOT2 + geom_point(data = mat.dfm.PLOT,
                                            aes(x      = predicted,
                                                y      = mean,
                                                group  = sizePortfolio,
                                                colour = sizePortfolio
                                                )
                                            )
obj.gg2.PLOT2 <- obj.gg2.PLOT2 + geom_path(data = mat.dfm.PLOT,
                                           aes(x      = predicted,
                                               y      = mean,
                                               group  = sizePortfolio,
                                               colour = sizePortfolio
                                               )
                                           )
obj.gg2.PLOT2 <- obj.gg2.PLOT2 + xlab('')
obj.gg2.PLOT2 <- obj.gg2.PLOT2 + ylab('')
obj.gg2.PLOT2 <- obj.gg2.PLOT2 + opts(legend.position = c(0.25,0.80))
obj.gg2.PLOT2 <- obj.gg2.PLOT2 + labs(group = "", colour = "")
obj.gg2.PLOT2 <- obj.gg2.PLOT2 + theme(plot.margin = unit(c(0.5,0.1,0,0), "lines"),
                                       axis.title.x = element_text(size = rel(0)),
                                       axis.title.y = element_text(size = rel(0)),
                                       axis.text.y = element_text(size = rel(0.75)),
                                       axis.text.x = element_text(size = rel(0.75)),
                                       axis.ticks  = theme_segment(colour = "black", size = rel(0.25))
                                       )


## Combine plots
pushViewport(viewport(layout = grid.layout(2, 3, heights = unit(c(6, 0.25), "null"), widths = unit(c(0.25, 6, 6), "null"))))
grid.text("$\\beta_{n,\\mathrm{Mkt}} \\cdot \\mathrm{E}[r_{\\mathrm{Mkt},t+1} - r_{f,t+1}] + \\beta_{n,\\mathrm{HML}} \\cdot \\mathrm{E}[r_{\\mathrm{HML},t+1}] + \\beta_{n,\\mathrm{SMB}} \\cdot \\mathrm{E}[r_{\\mathrm{SMB},t+1}]$: Predicted", vp = viewport(layout.pos.row = 2, layout.pos.col = 2:3))
grid.text("$\\mathrm{E}[r_{n,t+1} - r_{f,t+1}]$: Monthly Excess Return", vp = viewport(layout.pos.row = 1, layout.pos.col = 1), rot = 90)
print(obj.gg2.PLOT1, vp = viewport(layout.pos.row = 1, layout.pos.col = 2))
print(obj.gg2.PLOT2, vp = viewport(layout.pos.row = 1, layout.pos.col = 3))
dev.off()

system(paste('pdflatex', file.path(scl.str.TEX_FILE)), ignore.stdout = TRUE)
system(paste('convert -density 450', file.path(scl.str.PDF_FILE), ' ', file.path(scl.str.PNG_FILE)))
system(paste('mv ', scl.str.PNG_FILE, ' ', scl.str.FIG_DIR, sep = ''))
system(paste('rm ', scl.str.TEX_FILE, sep = ''))
system(paste('mv ', scl.str.PDF_FILE, ' ', scl.str.FIG_DIR, sep = ''))
system(paste('rm ', scl.str.AUX_FILE, sep = ''))
system(paste('rm ', scl.str.LOG_FILE, sep = ''))














## Plot Figures 20.9, 20.10, and 20.11 from Cochrane (2001)
mat.dfm.PLOT        <- ddply(mat.dfm.FF93,
                             c("sizePortfolio", "bookToMarketPortfolio"),
                             function(X)c(mean(X$retx), lm(X$retx ~ X$mkt)$coef[2])
                             )
names(mat.dfm.PLOT) <- c("sizePortfolio", "bookToMarketPortfolio", "mean", "beta")

mat.dfm.PLOT$sizePortfolioLab <- ""
mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S1", ]$sizePortfolioLab <- "$S_{\\mathrm{Low}}$"
mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S2", ]$sizePortfolioLab <- "${}S_2$"
mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S3", ]$sizePortfolioLab <- "${}S_3$"
mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S4", ]$sizePortfolioLab <- "${}S_4$"
mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S5", ]$sizePortfolioLab <- "${}S_{\\mathrm{High}}$"
mat.dfm.PLOT$bookToMarketPortfolioLab <- ""
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio == "V1", ]$bookToMarketPortfolioLab <- "$\\mathrm{BM}_{\\mathrm{Low}}$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio == "V2", ]$bookToMarketPortfolioLab <- "${}\\mathrm{BM}_2$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio == "V3", ]$bookToMarketPortfolioLab <- "${}\\mathrm{BM}_3$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio == "V4", ]$bookToMarketPortfolioLab <- "${}\\mathrm{BM}_4$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio == "V5", ]$bookToMarketPortfolioLab <- "${}\\mathrm{BM}_{\\mathrm{High}}$"

theme_set(theme_bw())

obj.vplayout <- function(x, y) viewport(layout.pos.row = x, layout.pos.col = y)

scl.str.RAW_FILE <- 'cochrane01-mktModel-vs-5x5sort'
scl.str.TEX_FILE <- paste(scl.str.RAW_FILE,'.tex',sep='')
scl.str.PDF_FILE <- paste(scl.str.RAW_FILE,'.pdf',sep='')
scl.str.PNG_FILE <- paste(scl.str.RAW_FILE,'.png',sep='')
scl.str.AUX_FILE <- paste(scl.str.RAW_FILE,'.aux',sep='')
scl.str.LOG_FILE <- paste(scl.str.RAW_FILE,'.log',sep='')

tikz(file = scl.str.TEX_FILE, height = 4, width = 7, standAlone=TRUE)


## 20.9
obj.gg2.PLOT1 <- ggplot()
obj.gg2.PLOT1 <- obj.gg2.PLOT1 + geom_point(data = mat.dfm.PLOT,
                                          aes(x = beta,
                                              y = mean
                                              )
                                          )
obj.gg2.PLOT1 <- obj.gg2.PLOT1 + xlab('')
obj.gg2.PLOT1 <- obj.gg2.PLOT1 + ylab('')
obj.gg2.PLOT1 <- obj.gg2.PLOT1 + opts(legend.position = "none")
obj.gg2.PLOT1 <- obj.gg2.PLOT1 + theme(plot.margin = unit(c(0.5,0,0,0), "lines"),
                                       axis.title.x = element_text(size = rel(0)),
                                       axis.title.y = element_text(size = rel(0)),
                                       axis.text.y  = element_text(size = rel(0.75)),
                                       axis.text.x  = element_text(size = rel(0.75)),
                                       axis.ticks   = theme_segment(colour = "black", size = rel(0.25))
                                       )

## 20.10
obj.gg2.PLOT2 <- ggplot()
obj.gg2.PLOT2 <- obj.gg2.PLOT2 + geom_point(data = mat.dfm.PLOT,
                                          aes(x      = beta,
                                              y      = mean,
                                              group  = bookToMarketPortfolio,
                                              colour = bookToMarketPortfolioLab
                                              )
                                          )
obj.gg2.PLOT2 <- obj.gg2.PLOT2 + geom_path(data = mat.dfm.PLOT,
                                         aes(x      = beta,
                                             y      = mean,
                                             group  = bookToMarketPortfolio,
                                             colour = bookToMarketPortfolioLab
                                             )
                                         )
obj.gg2.PLOT2 <- obj.gg2.PLOT2 + xlab('')
obj.gg2.PLOT2 <- obj.gg2.PLOT2 + ylab('')
obj.gg2.PLOT2 <- obj.gg2.PLOT2 + opts(legend.position = c(0.75,0.80))
obj.gg2.PLOT2 <- obj.gg2.PLOT2 + labs(group = "", colour = "")
obj.gg2.PLOT2 <- obj.gg2.PLOT2 + theme(plot.margin = unit(c(0.5,0,0,0), "lines"),
                                       axis.title.x = element_text(size = rel(0)),
                                       axis.title.y = element_text(size = rel(0)),
                                       axis.text.y = element_text(size = rel(0.75)),
                                       axis.text.x = element_text(size = rel(0.75)),
                                       axis.ticks  = theme_segment(colour = "black", size = rel(0.25))
                                       )


## 20.11
obj.gg2.PLOT3 <- ggplot()
obj.gg2.PLOT3 <- obj.gg2.PLOT3 + geom_point(data = mat.dfm.PLOT,
                                            aes(x      = beta,
                                                y      = mean,
                                                group  = sizePortfolio,
                                                colour = sizePortfolioLab
                                                )
                                            )
obj.gg2.PLOT3 <- obj.gg2.PLOT3 + geom_path(data = mat.dfm.PLOT,
                                           aes(x      = beta,
                                               y      = mean,
                                               group  = sizePortfolio,
                                               colour = sizePortfolioLab
                                               )
                                           )
obj.gg2.PLOT3 <- obj.gg2.PLOT3 + xlab('')
obj.gg2.PLOT3 <- obj.gg2.PLOT3 + ylab('')
obj.gg2.PLOT3 <- obj.gg2.PLOT3 + opts(legend.position = c(0.75,0.80))
obj.gg2.PLOT3 <- obj.gg2.PLOT3 + labs(group = "", colour = "")
obj.gg2.PLOT3 <- obj.gg2.PLOT3 + theme(plot.margin = unit(c(0.5,0.1,0,0), "lines"),
                                       axis.title.x = element_text(size = rel(0)),
                                       axis.title.y = element_text(size = rel(0)),
                                       axis.text.y = element_text(size = rel(0.75)),
                                       axis.text.x = element_text(size = rel(0.75)),
                                       axis.ticks  = theme_segment(colour = "black", size = rel(0.25))
                                       )


## Combine plots
pushViewport(viewport(layout = grid.layout(2, 4, heights = unit(c(6, 0.25), "null"), widths = unit(c(0.25, 4, 4, 4), "null"))))
grid.text("$\\beta_{n,\\mathrm{Mkt}}$: Beta on Market", vp = viewport(layout.pos.row = 2, layout.pos.col = 2:4))
grid.text("$\\mathrm{E}[r_{n,t+1} - r_{f,t+1}]$: Monthly Excess Return", vp = viewport(layout.pos.row = 1, layout.pos.col = 1), rot = 90)
print(obj.gg2.PLOT1, vp = viewport(layout.pos.row = 1, layout.pos.col = 2))
print(obj.gg2.PLOT2, vp = viewport(layout.pos.row = 1, layout.pos.col = 3))
print(obj.gg2.PLOT3, vp = viewport(layout.pos.row = 1, layout.pos.col = 4))
dev.off()

system(paste('pdflatex', file.path(scl.str.TEX_FILE)), ignore.stdout = TRUE)
system(paste('convert -density 450', file.path(scl.str.PDF_FILE), ' ', file.path(scl.str.PNG_FILE)))
system(paste('mv ', scl.str.PNG_FILE, ' ', scl.str.FIG_DIR, sep = ''))
system(paste('rm ', scl.str.TEX_FILE, sep = ''))
system(paste('mv ', scl.str.PDF_FILE, ' ', scl.str.FIG_DIR, sep = ''))
system(paste('rm ', scl.str.AUX_FILE, sep = ''))
system(paste('rm ', scl.str.LOG_FILE, sep = ''))















## Plot Table 1(a) in Daniel and Titman (1997)
mat.dfm.PLOT         <- ddply(mat.dfm.FF93,
                             c("year", "sizePortfolio", "bookToMarketPortfolio"),
                             function(X)c(mean(X$retx))
                             )
names(mat.dfm.PLOT)  <- c("t", "sizePortfolio", "bookToMarketPortfolio", "value")
mat.dfm.MEANS        <- ddply(mat.dfm.FF93,
                              c("sizePortfolio", "bookToMarketPortfolio"),
                              function(X)c(mean(X$retx))
                              )
names(mat.dfm.MEANS) <- c("sizePortfolio", "bookToMarketPortfolio", "mean")
mat.dfm.PLOT         <- merge(mat.dfm.PLOT,
                              mat.dfm.MEANS,
                              by = c("sizePortfolio", "bookToMarketPortfolio")
                              )
mat.dfm.PLOT <- mat.dfm.PLOT[order(mat.dfm.PLOT$t, mat.dfm.PLOT$sizePortfolio, mat.dfm.PLOT$bookToMarketPortfolio), ]

mat.dfm.LABEL        <- mat.dfm.MEANS
mat.dfm.LABEL$x      <- 1988
mat.dfm.LABEL$y      <- -5
names(mat.dfm.LABEL) <- c("sizePortfolio", "bookToMarketPortfolio", "text", "x", "y")
mat.dfm.LABEL$text   <- paste("$\\mu = ", as.character(signif(mat.dfm.LABEL$text, 2)), "$", sep = "")

mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S1", ]$sizePortfolio <- "$S_{\\mathrm{Low}}$"
mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S2", ]$sizePortfolio <- "${}S_2$"
mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S3", ]$sizePortfolio <- "${}S_3$"
mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S4", ]$sizePortfolio <- "${}S_4$"
mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S5", ]$sizePortfolio <- "${}S_{\\mathrm{High}}$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio == "V1", ]$bookToMarketPortfolio <- "$\\mathrm{BM}_{\\mathrm{Low}}$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio == "V2", ]$bookToMarketPortfolio <- "${}\\mathrm{BM}_2$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio == "V3", ]$bookToMarketPortfolio <- "${}\\mathrm{BM}_3$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio == "V4", ]$bookToMarketPortfolio <- "${}\\mathrm{BM}_4$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio == "V5", ]$bookToMarketPortfolio <- "${}\\mathrm{BM}_{\\mathrm{High}}$"

mat.dfm.LABEL[mat.dfm.LABEL$sizePortfolio == "S1", ]$sizePortfolio <- "$S_{\\mathrm{Low}}$"
mat.dfm.LABEL[mat.dfm.LABEL$sizePortfolio == "S2", ]$sizePortfolio <- "${}S_2$"
mat.dfm.LABEL[mat.dfm.LABEL$sizePortfolio == "S3", ]$sizePortfolio <- "${}S_3$"
mat.dfm.LABEL[mat.dfm.LABEL$sizePortfolio == "S4", ]$sizePortfolio <- "${}S_4$"
mat.dfm.LABEL[mat.dfm.LABEL$sizePortfolio == "S5", ]$sizePortfolio <- "${}S_{\\mathrm{High}}$"
mat.dfm.LABEL[mat.dfm.LABEL$bookToMarketPortfolio == "V1", ]$bookToMarketPortfolio <- "$\\mathrm{BM}_{\\mathrm{Low}}$"
mat.dfm.LABEL[mat.dfm.LABEL$bookToMarketPortfolio == "V2", ]$bookToMarketPortfolio <- "${}\\mathrm{BM}_2$"
mat.dfm.LABEL[mat.dfm.LABEL$bookToMarketPortfolio == "V3", ]$bookToMarketPortfolio <- "${}\\mathrm{BM}_3$"
mat.dfm.LABEL[mat.dfm.LABEL$bookToMarketPortfolio == "V4", ]$bookToMarketPortfolio <- "${}\\mathrm{BM}_4$"
mat.dfm.LABEL[mat.dfm.LABEL$bookToMarketPortfolio == "V5", ]$bookToMarketPortfolio <- "${}\\mathrm{BM}_{\\mathrm{High}}$"

theme_set(theme_bw())

scl.str.RAW_FILE <- 'ff93-5x5sort-portfolioReturns'
scl.str.TEX_FILE <- paste(scl.str.RAW_FILE,'.tex',sep='')
scl.str.PDF_FILE <- paste(scl.str.RAW_FILE,'.pdf',sep='')
scl.str.PNG_FILE <- paste(scl.str.RAW_FILE,'.png',sep='')
scl.str.AUX_FILE <- paste(scl.str.RAW_FILE,'.aux',sep='')
scl.str.LOG_FILE <- paste(scl.str.RAW_FILE,'.log',sep='')

tikz(file = scl.str.TEX_FILE, height = 7, width = 11, standAlone=TRUE)

obj.gg2.PLOT <- ggplot()
obj.gg2.PLOT <- obj.gg2.PLOT + geom_ribbon(data = mat.dfm.PLOT,
                                           aes(x    = t,
                                               ymax = mean,
                                               ymin = 0
                                               ),
                                           fill  = "red",
                                           alpha = 0.50
                                           )
obj.gg2.PLOT <- obj.gg2.PLOT + geom_hline(yintercept = 0, size = 0.50, linetype = 4)
obj.gg2.PLOT <- obj.gg2.PLOT + geom_path(data = mat.dfm.PLOT,
                                         aes(x = t, 
                                             y = value
                                             )
                                         )
obj.gg2.PLOT <- obj.gg2.PLOT + geom_text(data = mat.dfm.LABEL,
                                         aes(x     = x, 
                                             y     = y,
                                             label = text
                                             )
                                         )
obj.gg2.PLOT <- obj.gg2.PLOT + facet_grid(sizePortfolio ~ bookToMarketPortfolio)
obj.gg2.PLOT <- obj.gg2.PLOT + xlab('July 1963 to December 1993')
obj.gg2.PLOT <- obj.gg2.PLOT + ylab('Percent Per Month ($\\mu$: mean)')
obj.gg2.PLOT <- obj.gg2.PLOT + opts(legend.position = "none")

print(obj.gg2.PLOT)
dev.off()

system(paste('pdflatex', file.path(scl.str.TEX_FILE)), ignore.stdout = TRUE)
system(paste('convert -density 450', file.path(scl.str.PDF_FILE), ' ', file.path(scl.str.PNG_FILE)))
system(paste('mv ', scl.str.PNG_FILE, ' ', scl.str.FIG_DIR, sep = ''))
system(paste('rm ', scl.str.TEX_FILE, sep = ''))
system(paste('mv ', scl.str.PDF_FILE, ' ', scl.str.FIG_DIR, sep = ''))
system(paste('rm ', scl.str.AUX_FILE, sep = ''))
system(paste('rm ', scl.str.LOG_FILE, sep = ''))

