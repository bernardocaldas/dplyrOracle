#' Set of internal over functions
#' @keywords internal
#' NULL


#' Over
#' @export
#' @rdname over
# Generate SQL expression for window function
# over("avg(x)", frame = c(-Inf, 0))
# over("avg(x)", order = "y")
over <- function(expr, partition = NULL, order = NULL, frame = NULL) {
  args <- (!is.null(partition)) + (!is.null(order)) + (!is.null(frame))
  if (args == 0) {
    #stop("Must supply at least one of partition, order, frame", call. = FALSE)
  }
  
  if (!is.null(partition)) {
    partition <- build_sql("PARTITION BY ", 
      sql_vector_over(partition, collapse = ", "))
  }
  if (!is.null(order)) {
    order <- build_sql("ORDER BY ", sql_vector_over(order, collapse = ", "))
  }
  if (!is.null(frame)) {
    if (is.numeric(frame)) frame <- rows(frame[1], frame[2])
    frame <- build_sql("ROWS ", frame)
  }
  
  over <- dplyr:::sql_vector(dplyr:::compact(list(partition, order, frame)), parens = TRUE)
  build_sql(expr, " OVER ", over)
}

rows <- function(from = -Inf, to = 0) {
  if (from >= to) stop("from must be less than to", call. = FALSE)
  
  dir <- function(x) if (x < 0) "PRECEDING" else "FOLLOWING"
  val <- function(x) if (is.finite(x)) as.integer(abs(x)) else "UNBOUNDED"
  bound <- function(x) {
    if (x == 0) return("CURRENT ROW")
    paste(val(x), dir(x))
  }

  if (to == 0) {
    sql(bound(from))
  } else {
    sql(paste0("BETWEEN ", bound(from), " AND ", bound(to)))
  }
}

#' SQL Vector Over
#' Collapse arguments in such way it can be used in partition/order by
#' clause of window functions
#' @export
#' @param x xx
#' @param parens xx
#' @param collapse xx
#' @param con xx
#' @rdname sql_vector_over
sql_vector_over <- function(x, parens = NA, collapse = " ", con = NULL) {
  if (is.na(parens)) {
    parens <- length(x) > 1L
  }
  
  x <- dplyr:::names_to_as(x, con = con)
  x <- paste(x, collapse = collapse)
  if (parens) x <- paste0("", x, " ")
  sql(x)
}