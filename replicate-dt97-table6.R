
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
scl.str.DAT_NAME <- "dt97-table6-data.csv"
scl.str.FIG_DIR  <- "~/Dropbox/research/trading_on_coincidences/figures/"










## Load DT97 data from WRDS
mat.dfm.DT97       <- read.csv(paste(scl.str.DAT_DIR, scl.str.DAT_NAME, sep = ""), stringsAsFactors = FALSE)

mat.dfm.DT97$year  <- floor(mat.dfm.DT97$DATE/10000)
mat.dfm.DT97$month <- floor((mat.dfm.DT97$DATE - mat.dfm.DT97$year * 10000)/100)
mat.dfm.DT97$t     <- mat.dfm.DT97$year + (mat.dfm.DT97$month - 1)/12

mat.dfm.DT97$ret   <- mat.dfm.DT97$ret * 100
mat.dfm.DT97$rf    <- mat.dfm.DT97$rf * 100
mat.dfm.DT97$retx  <- mat.dfm.DT97$ret - mat.dfm.DT97$rf
mat.dfm.DT97$mkt   <- mat.dfm.DT97$mkt * 100
mat.dfm.DT97$smb   <- mat.dfm.DT97$smb * 100
mat.dfm.DT97$hml   <- mat.dfm.DT97$hml * 100








## Plot Table 3 in Daniel and Titman (1997)
mat.dfm.PLOT         <- ddply(mat.dfm.DT97,
                              c("sizePortfolio", "bookToMarketPortfolio", "hmlLoadingPortfolio"),
                              function(X)c(mean(X$retx))
                              )
names(mat.dfm.PLOT)  <- c("sizePortfolio", "bookToMarketPortfolio", "hmlLoadingPortfolio", "Estimated")
mat.dfm.PLOT$Actual  <- c(0.202, 0.833, 0.902, 0.731, 0.504,
                          1.036, 0.964, 1.014, 1.162, 0.862,
                          1.211, 1.112, 1.174, 1.265, 0.994,
                          0.711, 0.607, 0.776, 0.872, 0.710,
                          0.847, 0.957, 0.997, 0.873, 0.724,
                          1.122, 1.166, 1.168, 1.080, 0.955,
                          0.148, 0.287, 0.396, 0.400, 0.830,
                          0.645, 0.497, 0.615, 0.572, 0.718,
                          0.736, 0.933, 0.571, 0.843, 0.961
                          )


mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S1", ]$sizePortfolio <- "$S_L$"
mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S2", ]$sizePortfolio <- "${}S_M$"
mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S3", ]$sizePortfolio <- "${}{}S_H$"

mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio == "V1", ]$bookToMarketPortfolio <- "$\\mathrm{BM}_L$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio == "V2", ]$bookToMarketPortfolio <- "${}\\mathrm{BM}_M$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio == "V3", ]$bookToMarketPortfolio <- "${}{}\\mathrm{BM}_H$"

mat.dfm.PLOT[mat.dfm.PLOT$hmlLoadingPortfolio == "hml1", ]$hmlLoadingPortfolio <- "$z_L$"
mat.dfm.PLOT[mat.dfm.PLOT$hmlLoadingPortfolio == "hml2", ]$hmlLoadingPortfolio <- "${}z_2$"
mat.dfm.PLOT[mat.dfm.PLOT$hmlLoadingPortfolio == "hml3", ]$hmlLoadingPortfolio <- "${}z_3$"
mat.dfm.PLOT[mat.dfm.PLOT$hmlLoadingPortfolio == "hml4", ]$hmlLoadingPortfolio <- "${}z_4$"
mat.dfm.PLOT[mat.dfm.PLOT$hmlLoadingPortfolio == "hml5", ]$hmlLoadingPortfolio <- "${}z_H$"

mat.dfm.PLOT <- melt(mat.dfm.PLOT,
                     c("sizePortfolio", "bookToMarketPortfolio", "hmlLoadingPortfolio")
                     )

theme_set(theme_bw())

scl.str.RAW_FILE <- 'dt97-meanPortfolioReturns'
scl.str.TEX_FILE <- paste(scl.str.RAW_FILE,'.tex',sep='')
scl.str.PDF_FILE <- paste(scl.str.RAW_FILE,'.pdf',sep='')
scl.str.PNG_FILE <- paste(scl.str.RAW_FILE,'.png',sep='')
scl.str.AUX_FILE <- paste(scl.str.RAW_FILE,'.aux',sep='')
scl.str.LOG_FILE <- paste(scl.str.RAW_FILE,'.log',sep='')

tikz(file = scl.str.TEX_FILE, height = 5, width = 7, standAlone=TRUE)

obj.gg2.PLOT <- ggplot()
obj.gg2.PLOT <- obj.gg2.PLOT + geom_text(data = mat.dfm.PLOT,
                                         aes(x      = hmlLoadingPortfolio,
                                             y      = value,
                                             colour = variable,
                                             label  = round(value,3)
                                             ),
                                         size = 3
                                         )
obj.gg2.PLOT <- obj.gg2.PLOT + facet_grid(sizePortfolio ~ bookToMarketPortfolio)
obj.gg2.PLOT <- obj.gg2.PLOT + xlab('')
obj.gg2.PLOT <- obj.gg2.PLOT + labs(colour = 'Excess Return')
obj.gg2.PLOT <- obj.gg2.PLOT + ylab('$\\%/\\mathrm{Month}$')

print(obj.gg2.PLOT)
dev.off()

system(paste('pdflatex', file.path(scl.str.TEX_FILE)), ignore.stdout = TRUE)
system(paste('convert -density 450', file.path(scl.str.PDF_FILE), ' ', file.path(scl.str.PNG_FILE)))
system(paste('mv ', scl.str.PNG_FILE, ' ', scl.str.FIG_DIR, sep = ''))
system(paste('rm ', scl.str.TEX_FILE, sep = ''))
system(paste('mv ', scl.str.PDF_FILE, ' ', scl.str.FIG_DIR, sep = ''))
system(paste('rm ', scl.str.AUX_FILE, sep = ''))
system(paste('rm ', scl.str.LOG_FILE, sep = ''))










## Estimate Table 6 in Daniel and Titman (1997)
mat.dfm.HML5        <- mat.dfm.DT97[mat.dfm.DT97$hmlLoadingPortfolio == "hml5",
                                    c("t", "sizePortfolio", "bookToMarketPortfolio", "ret")
                                    ]
names(mat.dfm.HML5) <- c("t", "sizePortfolio", "bookToMarketPortfolio", "ret5")
mat.dfm.HML4        <- mat.dfm.DT97[mat.dfm.DT97$hmlLoadingPortfolio == "hml4",
                                    c("t", "sizePortfolio", "bookToMarketPortfolio", "ret")
                                    ]
names(mat.dfm.HML4) <- c("t", "sizePortfolio", "bookToMarketPortfolio", "ret4")


mat.dfm.HML1        <- mat.dfm.DT97[mat.dfm.DT97$hmlLoadingPortfolio == "hml1",
                                    c("t", "sizePortfolio", "bookToMarketPortfolio", "ret")
                                    ]
names(mat.dfm.HML1) <- c("t", "sizePortfolio", "bookToMarketPortfolio", "ret1")
mat.dfm.HML2        <- mat.dfm.DT97[mat.dfm.DT97$hmlLoadingPortfolio == "hml2",
                                    c("t", "sizePortfolio", "bookToMarketPortfolio", "ret")
                                    ]
names(mat.dfm.HML2) <- c("t", "sizePortfolio", "bookToMarketPortfolio", "ret2")


mat.dfm.FF93        <- ddply(mat.dfm.DT97,
                             c("t"),
                             function(X)c(mean(X$rf),mean(X$mkt), mean(X$hml), mean(X$smb))
                             )
names(mat.dfm.FF93) <- c("t", "rf", "mkt", "hml", "smb")


mat.dfm.REG <- merge(mat.dfm.HML5,
                     mat.dfm.HML4,
                     by = c("t", "sizePortfolio", "bookToMarketPortfolio")
                     )
mat.dfm.REG <- merge(mat.dfm.REG,
                     mat.dfm.HML2,
                     by = c("t", "sizePortfolio", "bookToMarketPortfolio")
                     )
mat.dfm.REG <- merge(mat.dfm.REG,
                     mat.dfm.HML1,
                     by = c("t", "sizePortfolio", "bookToMarketPortfolio")
                     )
mat.dfm.REG <- merge(mat.dfm.REG,
                     mat.dfm.FF93,
                     by = c("t")
                     )


mat.dfm.REG$retx <- (mat.dfm.REG$ret5 + mat.dfm.REG$ret4) - (mat.dfm.REG$ret2 + mat.dfm.REG$ret1)
## mat.dfm.REG$retx <- mat.dfm.REG$ret5 - mat.dfm.REG$ret1

mat.dfm.EST         <- ddply(mat.dfm.REG,
                             c("bookToMarketPortfolio", "sizePortfolio"),
                             function(X)c(summary(lm(X$retx ~ X$mkt + X$smb + X$hml))$coef[1,1],
                                          summary(lm(X$retx ~ X$mkt + X$smb + X$hml))$coef[2,1],
                                          summary(lm(X$retx ~ X$mkt + X$smb + X$hml))$coef[3,1],
                                          summary(lm(X$retx ~ X$mkt + X$smb + X$hml))$coef[4,1]
                                          )
                             )
names(mat.dfm.EST) <- c("bookToMarketPortfolio",
                        "sizePortfolio",
                        "$\\alpha$",
                        "$\\beta_{\\mathrm{Mkt}}$",
                        "$\\beta_{\\mathrm{SMB}}$",
                        "$\\beta_{\\mathrm{HML}}$"
                        )


mat.dfm.SE        <- ddply(mat.dfm.REG,
                           c("bookToMarketPortfolio", "sizePortfolio"),
                           function(X)c(summary(lm(X$retx ~ X$mkt + X$smb + X$hml))$coef[1,2],
                                        summary(lm(X$retx ~ X$mkt + X$smb + X$hml))$coef[2,2],
                                        summary(lm(X$retx ~ X$mkt + X$smb + X$hml))$coef[3,2],
                                        summary(lm(X$retx ~ X$mkt + X$smb + X$hml))$coef[4,2]
                                        )
                           )
names(mat.dfm.SE) <- c("bookToMarketPortfolio",
                       "sizePortfolio",
                       "$\\alpha$",
                       "$\\beta_{\\mathrm{Mkt}}$",
                       "$\\beta_{\\mathrm{SMB}}$",
                       "$\\beta_{\\mathrm{HML}}$"
                       )

mat.dfm.R2        <- ddply(mat.dfm.REG,
                           c("bookToMarketPortfolio", "sizePortfolio"),
                           function(X)c(summary(lm(X$retx ~ X$mkt + X$smb + X$hml))$r.squared * 100)
                           )
names(mat.dfm.R2) <- c("bookToMarketPortfolio",
                       "sizePortfolio",
                       "label"
                       )












## Plot coefficient estimates and error-bounds for Table 6 in Daniel and Titman (1997)
mat.dfm.EST        <- melt(mat.dfm.EST,
                           c("sizePortfolio", "bookToMarketPortfolio")
                           )
names(mat.dfm.EST) <- c("sizePortfolio", "bookToMarketPortfolio", "variable", "estimate")
mat.dfm.SE         <- melt(mat.dfm.SE,
                           c("sizePortfolio", "bookToMarketPortfolio")
                           )
names(mat.dfm.SE)  <- c("sizePortfolio", "bookToMarketPortfolio", "variable", "se")


mat.dfm.PLOT     <- merge(mat.dfm.EST,
                          mat.dfm.SE,
                          by = c("sizePortfolio", "bookToMarketPortfolio", "variable")
                          )
mat.dfm.PLOT$ub  <- mat.dfm.PLOT$estimate + 1.60 * mat.dfm.PLOT$se
mat.dfm.PLOT$lb  <- mat.dfm.PLOT$estimate - 1.60 * mat.dfm.PLOT$se
mat.dfm.PLOT$sig <- as.numeric((mat.dfm.PLOT$lb > 0) | (mat.dfm.PLOT$ub < 0))


mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S1",]$sizePortfolio <- "$S_L$"
mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S2",]$sizePortfolio <- "${}S_M$"
mat.dfm.PLOT[mat.dfm.PLOT$sizePortfolio == "S3",]$sizePortfolio <- "${}{}S_H$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio=="V1",]$bookToMarketPortfolio <- "$\\mathrm{BM}_L$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio=="V2",]$bookToMarketPortfolio <- "${}\\mathrm{BM}_M$"
mat.dfm.PLOT[mat.dfm.PLOT$bookToMarketPortfolio=="V3",]$bookToMarketPortfolio <- "${}{}\\mathrm{BM}_H$"

mat.dfm.R2$label  <- paste("$R^2 = ", round(mat.dfm.R2$label), "\\%$", sep = "")
mat.dfm.R2$x      <- "$\\beta_{\\mathrm{HML}}$"
mat.dfm.R2$y      <- 1.10
mat.dfm.R2[mat.dfm.R2$sizePortfolio == "S1",]$sizePortfolio <- "$S_L$"
mat.dfm.R2[mat.dfm.R2$sizePortfolio == "S2",]$sizePortfolio <- "${}S_M$"
mat.dfm.R2[mat.dfm.R2$sizePortfolio == "S3",]$sizePortfolio <- "${}{}S_H$"
mat.dfm.R2[mat.dfm.R2$bookToMarketPortfolio=="V1",]$bookToMarketPortfolio <- "$\\mathrm{BM}_L$"
mat.dfm.R2[mat.dfm.R2$bookToMarketPortfolio=="V2",]$bookToMarketPortfolio <- "${}\\mathrm{BM}_M$"
mat.dfm.R2[mat.dfm.R2$bookToMarketPortfolio=="V3",]$bookToMarketPortfolio <- "${}{}\\mathrm{BM}_H$"





theme_set(theme_bw())

scl.str.RAW_FILE <- 'dt97-alphaPortfolioReturns'
scl.str.TEX_FILE <- paste(scl.str.RAW_FILE,'.tex',sep='')
scl.str.PDF_FILE <- paste(scl.str.RAW_FILE,'.pdf',sep='')
scl.str.PNG_FILE <- paste(scl.str.RAW_FILE,'.png',sep='')
scl.str.AUX_FILE <- paste(scl.str.RAW_FILE,'.aux',sep='')
scl.str.LOG_FILE <- paste(scl.str.RAW_FILE,'.log',sep='')

tikz(file = scl.str.TEX_FILE, height = 5, width = 7, standAlone=TRUE)

obj.gg2.PLOT <- ggplot()
obj.gg2.PLOT <- obj.gg2.PLOT + geom_hline(yintercept = 0,
                                          linetype = 4,
                                          size = 0.50
                                          )
obj.gg2.PLOT <- obj.gg2.PLOT + geom_linerange(data = mat.dfm.PLOT,
                                              aes(x      = variable,
                                                  ymin   = lb,
                                                  ymax   = ub
                                                  ),
                                              size = 1.5
                                              )
obj.gg2.PLOT <- obj.gg2.PLOT + geom_point(data = mat.dfm.PLOT,
                                          aes(x      = variable,
                                              y      = estimate
                                              ),
                                          size = 2
                                          )
obj.gg2.PLOT <- obj.gg2.PLOT + geom_linerange(data = mat.dfm.PLOT[mat.dfm.PLOT$sig == 1,],
                                              aes(x      = variable,
                                                  ymin   = lb,
                                                  ymax   = ub
                                                  ),
                                              colour = "red",
                                              size = 1.5
                                              )
obj.gg2.PLOT <- obj.gg2.PLOT + geom_point(data = mat.dfm.PLOT[mat.dfm.PLOT$sig == 1,],
                                          aes(x      = variable,
                                              y      = estimate
                                              ),
                                          colour = "red",
                                          size = 2
                                          )
obj.gg2.PLOT <- obj.gg2.PLOT + geom_text(data = mat.dfm.R2,
                                          aes(x     = x,
                                              y     = y,
                                              label = label
                                              ),
                                          size = 3
                                          )
obj.gg2.PLOT <- obj.gg2.PLOT + facet_grid(sizePortfolio ~ bookToMarketPortfolio)
obj.gg2.PLOT <- obj.gg2.PLOT + xlab('')
obj.gg2.PLOT <- obj.gg2.PLOT + ylab("$\\alpha$ in $\\%/\\mathrm{Month}$, $\\beta$'s are dimensionless")
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
