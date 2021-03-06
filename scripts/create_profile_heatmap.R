#' Functions for creating heatmap & profile plots
#' 

# plot heatmap --------------------------------------------------------
heatmap_plotting <- function(data,
                             x_axis,
                             var1_id,
                             var2_id,
                             low_color_var1,
                             high_color_var1,
                             low_color_var2,
                             high_color_var2,
                             para_color,
                             x_size,
                             y_size,
                             legend_size,
                             main_legend,
                             dot_zoom,
                             x_angle,
                             guideline){
  data_heat <- data

  # rescale numbers of paralogs
  data_heat$paralog <- as.numeric(data_heat$paralog)
  if (length(unique(na.omit(data_heat$paralog))) > 0) {
    max_paralog <- max(na.omit(data_heat$paralog))
    data_heat$paralogSize <- (data_heat$paralog / max_paralog) * 3
  }

  # remove prefix number of taxa names but keep the order
  data_heat$supertaxon <- {
    mapvalues(warn_missing = F,
              data_heat$supertaxon,
              from = as.character(data_heat$supertaxon),
              to = substr(as.character(data_heat$supertaxon),
                          6,
                          nchar(as.character(data_heat$supertaxon))))
  }

  # format plot
  if (x_axis == "genes") {
    p <- ggplot(data_heat, aes(x = geneID, y = supertaxon)) # global aes
  } else{
    p <- ggplot(data_heat, aes(y = geneID, x = supertaxon)) # global aes
  }
  if (length(unique(na.omit(data_heat$var2))) != 1) {
    p <- p + scale_fill_gradient(low = low_color_var2,
                                high = high_color_var2,
                                na.value = "gray95",
                                limits = c(0, 1)) +  # fill color (var2)
      geom_tile(aes(fill = var2))    # filled rect (var2 score)
  }
  if (length(unique(na.omit(data_heat$presSpec))) < 3) {
    if (length(unique(na.omit(data_heat$var1))) == 1) {
      # geom_point for circle illusion (var1 and presence/absence)
      p <- p + geom_point(aes(colour = var1),
                         size = data_heat$presSpec * 5 * (1 + dot_zoom),
                         na.rm = TRUE, show.legend = F)
    } else {
      # geom_point for circle illusion (var1 and presence/absence)
      p <- p + geom_point(aes(colour = var1),
                         size = data_heat$presSpec * 5 * (1 + dot_zoom),
                         na.rm = TRUE)
      # color of the corresponding aes (var1)
      p <- p + scale_color_gradient(low = low_color_var1,
                                   high = high_color_var1,
                                   limits = c(0, 1))
    }
  } else {
    if (length(unique(na.omit(data_heat$var1))) == 1) {
      # geom_point for circle illusion (var1 and presence/absence)
      p <- p + geom_point(aes(size = presSpec),
                         color = "#336a98",
                         na.rm = TRUE)
    } else {
      # geom_point for circle illusion (var1 and presence/absence)
      p <- p + geom_point(aes(colour = var1, size = presSpec),
                         na.rm = TRUE)
      # color of the corresponding aes (var1)
      p <- p + scale_color_gradient(low = low_color_var1, high = high_color_var1,
                                   limits = c(0, 1))
    }
  }

  # plot inparalogs (if available)
  if (length(unique(na.omit(data_heat$paralog))) > 0) {
    p <- p + geom_point(data = data_heat,
                        aes(size = paralog),
                        color = para_color,
                        na.rm = TRUE,
                        show.legend = TRUE)
    p <- p + guides(size = guide_legend(title = "# of co-orthologs"))

    # to tune the size of circles;
    # "floor(value*10)/10" is used to round "down" the value with one decimal number
    p <- p + scale_size_continuous(range = c(min(na.omit(data_heat$paralogSize)) * (1 + dot_zoom),
                                             max(na.omit(data_heat$paralogSize)) * (1 + dot_zoom)))
  } else {
    # remain the scale of point while filtering
    present_vl <- data_heat$presSpec[!is.na(data_heat$presSpec)]

    # to tune the size of circles;
    # "floor(value*10)/10" is used to round "down" the value with one decimal number
    p <- p + scale_size_continuous(range = c( (floor(min(present_vl) * 10) / 10 * 5) * (1 + dot_zoom),
                                             (floor(max(present_vl) * 10) / 10 * 5) * (1 + dot_zoom)))
  }
  p <- p + guides(fill = guide_colourbar(title = var2_id),
                 color = guide_colourbar(title = var1_id))
  base_size <- 9

  # guideline for separating ref species
  if (guideline == 1) {
    if (x_axis == "genes") {
      p <- p + labs(y = "Taxon")
      p <- p + geom_hline(yintercept = 0.5, colour = "dodgerblue4")
      p <- p + geom_hline(yintercept = 1.5, colour = "dodgerblue4")
    } else{
      p <- p + labs(x = "Taxon")
      p <- p + geom_vline(xintercept = 0.5, colour = "dodgerblue4")
      p <- p + geom_vline(xintercept = 1.5, colour = "dodgerblue4")
    }
  }
  
  # format theme
  p <- p + theme_minimal()
  p <- p + theme(axis.text.x = element_text(angle = x_angle,
                                           hjust = 1,
                                           size = x_size),
                axis.text.y = element_text(size = y_size),
                axis.title.x = element_text(size = x_size),
                axis.title.y = element_text(size = y_size),
                legend.title = element_text(size = legend_size),
                legend.text = element_text(size = legend_size),
                legend.position = main_legend)
  # return plot
  return(p)
}

# create profile plot ------------------------------------------------------
profile_plot <- function(data_heat, plot_parameter, taxon_name, rank_select, gene_highlight){
  p <- heatmap_plotting(data_heat,
                        plot_parameter$x_axis,
                        plot_parameter$var1_id,
                        plot_parameter$var2_id,
                        plot_parameter$low_color_var1,
                        plot_parameter$high_color_var1,
                        plot_parameter$low_color_var2,
                        plot_parameter$high_color_var2,
                        plot_parameter$para_color,
                        plot_parameter$x_size,
                        plot_parameter$y_size,
                        plot_parameter$legend_size,
                        plot_parameter$main_legend,
                        plot_parameter$dot_zoom,
                        plot_parameter$x_angle,
                        plot_parameter$guideline)
  
  # highlight taxon
  if (taxon_name != "none") {
    # get selected highlight taxon ID
    rank_select <- rank_select
    # get rank name from rank_select
    rank_rame <- substr(rank_select,
                      4,
                      nchar(rank_select))
    taxa_list <- as.data.frame(read.table("data/taxonNamesReduced.txt",
                                          sep = "\t",
                                          header = T))
    taxon_highlight_id <- {
      taxa_list$ncbiID[taxa_list$fullName == taxon_name
                       & taxa_list$rank == rank_rame]
    }

    if (length(taxon_highlight_id) == 0L) {
      taxon_highlight_id <- {
        taxa_list$ncbiID[taxa_list$fullName == taxon_name]
      }
    }

    # get taxonID together with it sorted index
    highlight_taxon <- {
      toString(data_heat[data_heat$supertaxonID == taxon_highlight_id, 2][1])
    }

    # get index
    selected_index <- as.numeric(as.character(substr(highlight_taxon, 2, 4)))

    # draw a rect to highlight this taxon's column
    if (plot_parameter$x_axis == "taxa") {
      rect <- data.frame(xmin = selected_index - 0.5,
                         xmax = selected_index + 0.5,
                         ymin = -Inf,
                         ymax = Inf)
    } else {
      rect <- data.frame(ymin = selected_index - 0.5,
                         ymax = selected_index + 0.5,
                         xmin = -Inf,
                         xmax = Inf)
    }

    p <- p + geom_rect(data = rect,
                      aes(xmin = xmin, xmax = xmax,
                          ymin = ymin, ymax = ymax),
                      color = "yellow",
                      alpha = 0.3,
                      inherit.aes = FALSE)
  }

  # highlight gene
  if (gene_highlight != "none") {
    # get selected highlight gene ID
    gene_highlight <- gene_highlight

    # get index
    all_genes <- levels(data_heat$geneID)
    selected_index <- match(gene_highlight, all_genes)

    # draw a rect to highlight this taxon's column
    if (plot_parameter$x_axis == "taxa") {
      rect <- data.frame(ymin = selected_index - 0.5,
                         ymax = selected_index + 0.5,
                         xmin = -Inf,
                         xmax = Inf)
    } else {
      rect <- data.frame(xmin = selected_index - 0.5,
                         xmax = selected_index + 0.5,
                         ymin = -Inf,
                         ymax = Inf)
    }

    p <- p + geom_rect(data = rect,
                      aes(xmin = xmin, xmax = xmax,
                          ymin = ymin, ymax = ymax),
                      color = "yellow",
                      alpha = 0.3,
                      inherit.aes = FALSE)
  }

  return(p)
}

# create data for main profile -----------------------
data_main_plot <- function(data_heat){
  # reduce number of inparalogs based on filtered dataHeat
  data_heat_tb <- data.table(na.omit(data_heat))
  data_heat_tb[, paralogNew := .N, by = c("geneID", "supertaxon")]
  data_heat_tb <- data.frame(data_heat_tb[, c("geneID",
                                          "supertaxon",
                                          "paralogNew")])

  data_heat <- merge(data_heat, data_heat_tb,
                    by = c("geneID", "supertaxon"),
                    all.x = TRUE)
  data_heat$paralog <- data_heat$paralogNew
  data_heat <- data_heat[!duplicated(data_heat), ]

  # remove unneeded dots
  data_heat$presSpec[data_heat$presSpec == 0] <- NA
  data_heat$paralog[data_heat$presSpec < 1] <- NA
  data_heat$paralog[data_heat$paralog == 1] <- NA
  
  return(data_heat)
}

# create data for customized profile -------------------------------------------
data_customized_plot <- function(data_heat, in_taxa, in_seq){
  # process data
    data_heat$supertaxonMod <- {
      substr(data_heat$supertaxon,
             6,
             nchar(as.character(data_heat$supertaxon)))
    }

    if (in_taxa[1] == "all" & in_seq[1] != "all") {
      # select data from dataHeat for selected sequences only
      data_heat <- subset(data_heat, geneID %in% in_seq)
    } else if (in_seq[1] == "all" & in_taxa[1] != "all") {
      # select data from dataHeat for selected taxa only
      data_heat <- subset(data_heat, supertaxonMod %in% in_taxa)
    } else {
      # select data from dataHeat for selected sequences and taxa
      data_heat <- subset(data_heat,
                         geneID %in% in_seq
                         & supertaxonMod %in% in_taxa)
    }

    # remove unneeded dots
    data_heat$presSpec[data_heat$presSpec == 0] <- NA
    data_heat$paralog[data_heat$presSpec < 1] <- NA
    data_heat$paralog[data_heat$paralog == 1] <- NA
    
    return(data_heat)
}