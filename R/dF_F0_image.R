#' Create delta F over F pseudocolor representation
#'
#' @param obj A target image of Image object or an array.
#' @param ref A reference image of Image object or an array.
#' @export
#' @examples
#' dF_F0_image()
#'

dF_F0_image <- function(flimgreg, fvimgbwbrfhregimg, regimgi, colmax=F, cmin, cmax, goodfr=NULL, output){
  Fmean <- dipr::rollmeanimg(flimgreg, 5)
  F0 <- rowMeans(flimgreg[,,1:5], dims=2)
  deltaF <- dipr::ssweep(Fmean, F0, op="-")
  dFF0 <- dipr::ssweep(deltaF, 1/F0, op="*")
  dFF0[is.na(dFF0)] <- 0
  dFF0[is.infinite(dFF0)] <- 0
  dFF0masked <- fvimgbwbrfhregimg*dFF0
  dFF0maskedpos <- dFF0masked * 100 # Convert to %
  dFF0maskedpos[which(dFF0maskedpos < 0)] <- 0
  if(colmax==F){
    colmax <- median(apply(dFF0maskedpos, 3, max))
  }
  dFF0maskedpos <- medianFilter(dFF0maskedpos/colmax, 3) # medianFilter cuts > 1
  dFF0fin <- array(0, dim=c(dim(fvimgbwbrfhregimg)[c(1,2)], 3, dim(fvimgbwbrfhregimg)[3]))
  for(cfr in 1:dim(dFF0maskedpos)[3]){
    dFF0fin[,,,cfr] <- dipr::pseudoColor(dFF0maskedpos[,,cfr], cmin, cmax)
  }
  dFF0fin <- Image(dFF0fin, colormode="Color")
  message(sprintf("Pseudocolor range is %d to %d", cmin, cmax))

  dFF0finmask <- dFF0fin
  dFF0finmask[,,1,] <- fvimgbwbrfhregimg
  dFF0finmask[,,2,] <- fvimgbwbrfhregimg
  dFF0finmask[,,3,] <- fvimgbwbrfhregimg
  dFF0regimg <- dFF0fin
  dFF0regimg[,,1,] <- 255-regimgi
  dFF0regimg[,,2,] <- 255-regimgi
  dFF0regimg[,,3,] <- 255-regimgi
  dFF0finmaskfly <- dFF0fin*dFF0finmask+dFF0regimg/255
  writeImage(dFF0finmaskfly, bits.per.sample = 8,
             file=paste0(output, "_dFF0finmaskfly.tif"))
  writeImage(Fmean, bits.per.sample = 8,
             file=paste0(output, "_Fmean.tif"))
  writeImage(F0, bits.per.sample = 8,
             file=paste0(output, "_F0.tif"))
  writeImage(dFF0maskedpos, bits.per.sample = 8,
             file=paste0(output, "_dF_F0_median_masked.tif"))
  if ((length(goodfr)>1) && any(goodfr)) {
    writeImage(dFF0finmaskfly@.Data[,,,goodfr], bits.per.sample = 8,
                        file=paste0(output, "_dFF0finmaskfly_goodfr_.tif"))
    writeImage(Fmean[,,goodfr], bits.per.sample = 8,
               file=paste0(output, "_Fmean_goodfr_.tif"))
    writeImage(dFF0maskedpos[,,goodfr], bits.per.sample = 8,
               file=paste0(output, "_dF_F0_median_masked_goodfr_.tif"))
  }
}
