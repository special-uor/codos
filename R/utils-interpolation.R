#' Shift vector
#'
#' Shift vector by \code{n} positions.
#'
#' @param x Numeric vector.
#' @param n Number of positions.
#' @param invert Boolean flag to indicate if the vector should be inverted.
#'
#' @return Shifted numeric vector.
#' @export
#'
#' @examples
#' shift(c(1:10), 2)
#'
#' @author Kamolphat Atsawawaranunt
shift <- function(x, n, invert = FALSE){
  stopifnot(length(x) >= n)
  if (n == 0)
    return(x)
  n <- ifelse(invert, -n, n)
  forward <- TRUE
  if (n < 0) {
    n <- abs(n)
    forward = FALSE
  }
  if (forward) {
    return(c(x[seq(length(x) - n + 1, length(x))], x[seq_len(length(x) - n)]))
  } else {
    return(c(x[seq(n + 1, length(x))], x[1:n]))
  }
}
