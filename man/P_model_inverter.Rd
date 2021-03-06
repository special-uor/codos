% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/p-model.R
\name{P_model_inverter}
\alias{P_model_inverter}
\title{P-model inverter class}
\description{
This class allows to create objects of the \code{P-model}.
}
\examples{
codos::P_model_inverter$new(T_diff = 1.334567,
                            T_ref = 11.57957,
                            m_rec = 0.3357231,
                            c_ratio = 0.7361765,
                            lat = -30)$calculate_m_true()
}
\section{Methods}{
\subsection{Public methods}{
\itemize{
\item \href{#method-new}{\code{P_model_inverter$new()}}
\item \href{#method-calculate_m_true}{\code{P_model_inverter$calculate_m_true()}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-new"></a>}}
\if{latex}{\out{\hypertarget{method-new}{}}}
\subsection{Method \code{new()}}{
Create a new \code{p-model} object.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{P_model_inverter$new(T_diff, T_ref, m_rec, c_ratio, lat = -30, ...)}\if{html}{\out{</div>}}
}

\subsection{Arguments}{
\if{html}{\out{<div class="arguments">}}
\describe{
\item{\code{T_diff}}{Temperature difference.}

\item{\code{T_ref}}{Reference temperature (e.g. modern temperature).}

\item{\code{m_rec}}{Reconstructed moisture index.}

\item{\code{c_ratio}}{CO2 ratio.}

\item{\code{lat}}{Latitude.}

\item{\code{...}}{Optional parameters (not used).}
}
\if{html}{\out{</div>}}
}
}
\if{html}{\out{<hr>}}
\if{html}{\out{<a id="method-calculate_m_true"></a>}}
\if{latex}{\out{\hypertarget{method-calculate_m_true}{}}}
\subsection{Method \code{calculate_m_true()}}{
Calculate true moisture index.
\subsection{Usage}{
\if{html}{\out{<div class="r">}}\preformatted{P_model_inverter$calculate_m_true()}\if{html}{\out{</div>}}
}

\subsection{Returns}{
A list with three elements:
\describe{
\item{\code{mi}:}{Numeric value of moisture index.}
\item{\code{cph}:}{Boolean flat to indicate whether or not the compensation point 'law' is upheld.}
\item{\code{ci}:}{Numeric value of c_i.}
}
}
}
}
