library(shiny)

drugnames_unsorted <- read.table(paste0("results_memory.txt"),
        stringsAsFactors = F,
        sep = "\t",
        h = T)[,"results.drug"]

data <- read.table(paste0("results_memory_sorted.txt"),
        stringsAsFactors = F,
        sep = "\t",
        h = T)

data <- data[!is.na(data$results.ROR),]
p_crit <- 0.05/(nrow(data)*12)

all_drugs <- unique(data$results.drug)

load("assignments_list.RData")
load("drugbank_list_processedList.RData")

shinyServer(function(input, output, session) {

    newData_allCases <- reactive({
        #-------------------------- Read in sorted data for all cases
        read.table(paste0("results_",
                input$result_name,"_sorted.txt"),
            stringsAsFactors = F,
            sep = "\t",
            h = T)
    })
    
    newRange <- reactive({
        #-------------------------- Get range from sliders
        range_out <- round(input$range)
        range_out
    })
    
    newRangeY <- reactive({
        #-------------------------- Get range from sliders
        range_out <- round(input$rangeY)
        range_out
    })
    
    newIndication_list <- reactive({
        load(paste0("result_lists_",input$result_name,".RData"))
        indication_list
    })
    
    newIndication_drug_list <- reactive({
        load(paste0("result_lists_",input$result_name,".RData"))

        names(indication_drug_list) <- drugnames_unsorted
        indication_drug_list
    })
    
    observe({
        if(!is.null(input$pvalPlot_click$x)){
            updateSelectInput(session, inputId = "drug",
                selected = all_drugs[round(input$pvalPlot_click$x)])
        }else if(!is.null(input$ORPlot_click$x)){
            updateSelectInput(session, inputId = "drug",
                selected = all_drugs[round(input$ORPlot_click$x)])
        }
    })
    
    observe({
        if(!is.null(input$pvalPlot_dblclick$x)){
            updateSliderInput(session, inputId = "range",
                value = c(1,nrow(data)))
        }else if(!is.null(input$ORPlot_dblclick$x)){
            updateSliderInput(session, inputId = "range",
                value = c(1,nrow(data)))
        }
    })

    observe({
        if(!is.null(input$pvalPlot_brush$xmin)){
            updateSliderInput(session, inputId = "range",
                value = c(round(input$pvalPlot_brush$xmin),
                    round(input$pvalPlot_brush$xmax)))
        }else if(!is.null(input$ORPlot_brush$xmin)){
            updateSliderInput(session, inputId = "range",
                value = c(round(input$ORPlot_brush$xmin),
                    round(input$ORPlot_brush$xmax)))
        }
    })
    
    output$ORPlot <- renderPlot({
        #-------------------------- Plot the count of adverse events (y-axis) per active ingredient (x-axis)
        
        if(input$result_name == "anorexia"){
            reac_print <- "eating disorder"
        }else if(input$result_name == "anxiety"){
            reac_print <- "anxiety"
        }else if(input$result_name == "attention"){
            reac_print <- "disturbed attention"
        }else if(input$result_name == "dementia"){
            reac_print <- "dementia"
        }else if(input$result_name == "depression"){
            reac_print <- "depression"
        }else if(input$result_name == "emotional"){
            reac_print <- "disturbed emotions"
        }else if(input$result_name == "mania"){
            reac_print <- "bipolar/mania"
        }else if(input$result_name == "memory"){
            reac_print <- "impaired memory"
        }else if(input$result_name == "panic_attack"){
            reac_print <- "panic attack"
        }else if(input$result_name == "paranoia"){
            reac_print <- "paranoia"
        }else if(input$result_name == "psychotic"){
            reac_print <- "psychotic disorder"
        }else if(input$result_name == "suicide"){
            reac_print <- "suicide"
        }
        
        data <- newData_allCases() # is sorted

        range_use <- newRange()
        
        if(input$type == "all"){
            columnname_use <- "results"
        }else{
            columnname_use <- paste0("results_",input$type)
        }
        
        data[data[,paste0(columnname_use,".ROR")] == 0,
           paste0(columnname_use,".ROR")] <- 0.0000000000001
        
        data[,paste0(columnname_use,".ROR")] <- log(data[,paste0(columnname_use,".ROR")])
        
        plot(data[,paste0(columnname_use,".ROR")],
            bty = "n",
            main = paste0("log(Odds ratio) for ",reac_print," and ",input$drug," intake"),
            ylab = "log(Odds ratio)",
            type = "n",
            cex = 0.75,
            ylim = c(-5,5),
            xlim = range_use,
            xaxt = "n",
            xlab = "Active Ingredients")
        abline(v = data$count_change, col = "lightgrey", xpd = F)
        points(x = 1:length(data[,paste0(columnname_use,".ROR")]),
            y = data[,paste0(columnname_use,".ROR")],
            pch = 20,
            cex = 0.75,
            col = "grey")
        
        points(x = which(data[,paste0(columnname_use,".pval")] < p_crit),
            y = data[data[,paste0(columnname_use,".pval")] < p_crit &
                        !is.na(data[,paste0(columnname_use,".pval")]),
                    paste0(columnname_use,".ROR")],
            pch = 20,
            col = "blue",
            cex = 0.75)
        
        points(x = which(data$results.drug == input$drug),
            y = data[,paste0(columnname_use,".ROR")][which(data$results.drug == input$drug)],
            pch = 20,
            col = "red")
        
        lines(x = rep(which(data$results.drug == input$drug),2),
            y = c(0,data[,paste0(columnname_use,".ROR")][which(data$results.drug == input$drug)]),
            col = "red")
        abline(h = 0, col = "grey")
        
        axis(1)
    })
    
    output$pvalPlot <- renderPlot({
        #-------------------------- Plot -log10(p) (y-axis) per active ingredient (x-axis)
        
        data <- newData_allCases()
        
        range_use <- newRange()
        rangeY_use <- newRangeY()
        
        if(input$type == "all"){
            columnname_use <- "results"
        }else{
            columnname_use <- paste0("results_",input$type)
        }
        
        data[data[,paste0(columnname_use,".pval")] == 0,
            paste0(columnname_use,".pval")] <- exp(-700)
        
        logPval_use <- -log10(data[,paste0(columnname_use,".pval")])*ifelse(data[,paste0(columnname_use,".ROR")] < 1,-1,1)
        
        plot(logPval_use, # $results.pval
            pch = 20,
            col = "grey",
            ylim = rangeY_use,
            xlim = range_use,
            bty = "n",
            main = paste0("-log10(p) Fisher's exact test (",input$result_name," within ",columnname_use,")"),
            ylab = "-log10(p)",
            cex = 0.75,
            xaxt = "n",
            xlab = "Active ingredients")
        
        abline(v = data$count_change, col = "lightgrey", xpd = F)
        points(x = which(data[,paste0(columnname_use,".pval")] < p_crit),
            y = logPval_use[data[,paste0(columnname_use,".pval")] < p_crit &
                    !is.na(data[,paste0(columnname_use,".pval")])],
            pch = 20,
            col = "blue",
            cex = 0.75)
        
        points(x = which(data$results.drug == input$drug),
               y = logPval_use[which(data$results.drug == input$drug)],
               pch = 20,
               col = "red")
        
        lines(x = rep(which(data$results.drug == input$drug),2),
            y = c(0,logPval_use[which(data$results.drug == input$drug)]),
            col = "red")
        
        abline(h = -log10(p_crit), col = "red")
        abline(h = log10(p_crit), col = "red")
        abline(h = 0, col = "grey")
        axis(1)
    })

    output$drugPlot <- renderPlot({
        #-------------------------- Plot XXXXX plots for all odds ratios
        data <- newData_allCases()
        data_drug <- data[data$results.drug == input$drug,]
        
        data_drug$results.ROR[data_drug$results.ROR == 0] <- 0.0000000000001
        data_drug$results_indication.ROR[data_drug$results_indication.ROR == 0] <- 0.0000000000001
        data_drug$results_age.ROR[data_drug$results_age.ROR == 0] <- 0.0000000000001
        data_drug$results_female.ROR[data_drug$results_female.ROR == 0] <- 0.0000000000001
        data_drug$results_male.ROR[data_drug$results_male.ROR == 0] <- 0.0000000000001
        
        data_drug$results.CI_low[data_drug$results.CI_low == 0 | data_drug$results.CI_low == -Inf] <- 0.0000000000001
        data_drug$results_indication.CI_low[data_drug$results_indication.CI_low == 0 | data_drug$results_indication.CI_low == -Inf] <- 0.0000000000001
        data_drug$results_age.CI_low[data_drug$results_age.CI_low == 0 | data_drug$results_age.CI_low == -Inf] <- 0.0000000000001
        data_drug$results_female.CI_low[data_drug$results_female.CI_low == 0 | data_drug$results_female.CI_low == -Inf] <- 0.0000000000001
        data_drug$results_male.CI_low[data_drug$results_male.CI_low == 0 | data_drug$results_male.CI_low == -Inf] <- 0.0000000000001

        data_drug$results.CI_up[data_drug$results.CI_up == Inf] <- 100
        data_drug$results_indication.CI_up[data_drug$results_indication.CI_up == Inf] <- 100
        data_drug$results_age.CI_up[data_drug$results_age.CI_up == Inf] <- 100
        data_drug$results_female.CI_up[data_drug$results_female.CI_up == Inf] <- 100
        data_drug$results_male.CI_up[data_drug$results_male.CI_up == Inf] <- 100

        oldpar <- par()
        par(mar = c(5.1,10,0.1,0))
        
        plot(x = c(log(data_drug$results.ROR),
            log(data_drug$results_indication.ROR),
            log(data_drug$results_age.ROR),
            log(data_drug$results_female.ROR),
            log(data_drug$results_male.ROR)),
            y = c(5:1),
            pch = 20,
            bty = "n",
            xlim = c(-5,5),
            main = "",
            ylab = "",
            xlab = "log(Odds ratios)",
            yaxt = "n")

        abline(v = 0, col = "grey")

        arrows(y0 = 5, y1 = 5,
            x0 = log(data_drug$results.CI_low),
            x1 = log(data_drug$results.CI_up),
            angle = 90,
            length = 0.1,
            code = 3)

        arrows(y0 = 4, y1 = 4,
            x0 = log(data_drug$results_indication.CI_low),
            x1 = log(data_drug$results_indication.CI_up),
            angle = 90,
            length = 0.1,
            code = 3)

        arrows(y0 = 3, y1 = 3,
            x0 = log(data_drug$results_age.CI_low),
            x1 = log(data_drug$results_age.CI_up),
            angle = 90,
            length = 0.1,
            code = 3)

        arrows(y0 = 2, y1 = 2,
            x0 = log(data_drug$results_female.CI_low),
            x1 = log(data_drug$results_female.CI_up),
            angle = 90,
            length = 0.1,
            code = 3)

        arrows(y0 = 1, y1 = 1,
            x0 = log(data_drug$results_male.CI_low),
            x1 = log(data_drug$results_male.CI_up),
            angle = 90,
            length = 0.1,
            code = 3)

        axis(2, at = c(5:1),
            labels = c("Across all",
                paste0("Within ",data_drug$results_indication.indication),
                paste0("... & aged ",data_drug$results_age.min_age,"-",data_drug$results_age.max_age),
                "... & female",
                "... & male"),
            las = 2)
    })
    
    output$textResults <- renderUI({
        #-------------------------- Print short description text
        data <- newData_allCases()
        data_drug <- data[data$results.drug == input$drug,]
        N_total <- data_drug$results.DrugReac + data_drug$results.DrugNoReac

        N_indication <- data_drug$results_indication.DrugReac + data_drug$results_indication.DrugNoReac

        text_print <- paste0("The active ingredient <b>",data_drug$results.drug,"</b> was administered in ",
        	N_total," reports. The most frequent indication for ",data_drug$results.drug,
        	" was <b>",data_drug$results_indication.indication,"</b> (", N_indication," cases).\n",
            "Results within indication, age, and separate genders were compared to other entries with indication ",
            data_drug$results_indication.indication,".")
        HTML(text_print)
    })
    
    output$fishersTable <- renderTable({
        #-------------------------- Print cross table drug ~ reaction
        data <- newData_allCases()
        data_drug <- data[data$results.drug == input$drug,,drop = F]

        if(input$type == "all"){
            columnname_use <- "results"
        }else{
            columnname_use <- paste0("results_",input$type)
        }
        
        data_drug[data_drug[,paste0(columnname_use,".pval")] == 0,
            paste0(columnname_use,".pval")] <- exp(-700)
        
        log_pval <- (-log10(data_drug[,paste0(columnname_use,".pval")]))
        OR <- data_drug[,paste0(columnname_use,".ROR")]
        CI_low <- data_drug[,paste0(columnname_use,".CI_low")]
        CI_up <- data_drug[,paste0(columnname_use,".CI_up")]
        CI <- paste0(CI_low,"-",CI_up)
        
        data_mat <- matrix(c(OR,CI,round(log_pval,2)),ncol = 1)
        
        colnames(data_mat) <- c("value")
        rownames(data_mat) <- c("OR","95% CI","-log10(p)")
        data_mat
    },
    include.rownames = T)
    
    output$crossTable <- renderTable({
        #-------------------------- Print cross table drug ~ reaction
        data <- newData_allCases()
        data_drug <- data[data$results.drug == input$drug,]

        if(input$type == "all"){
            data_drug <- data_drug[,grepl("results.Drug|results.NoDrug",names(data_drug)),drop = F]
        }else if(input$type == "indication"){
            data_drug <- data_drug[,grepl("results_indication.Drug|results_indication.NoDrug",names(data_drug)),drop = F]
        }else if(input$type == "age"){
            data_drug <- data_drug[,grepl("results_age.Drug|results_age.NoDrug",names(data_drug)),drop = F]
        }else if(input$type == "female"){
            data_drug <- data_drug[,grepl("results_female.Drug|results_female.NoDrug",names(data_drug)),drop = F]
        }else if(input$type == "male"){
            data_drug <- data_drug[,grepl("results_male.Drug|results_male.NoDrug",names(data_drug)),drop = F]
        }
        data_mat <- matrix(unlist(data_drug),ncol = 2, byrow = T)

        perc_reacDrug <- data_mat[1,1]/(sum(as.numeric(data_mat[1,])))
        perc_reacDrug <- as.character(round(100*perc_reacDrug,2))
        perc_reacNoDrug <- data_mat[2,1]/(sum(as.numeric(data_mat[2,])))
        perc_reacNoDrug <- as.character(round(100*perc_reacNoDrug,2))

        perc_drugReac <- data_mat[1,1]/(sum(as.numeric(data_mat[,1])))
        perc_drugReac <- as.character(round(100*perc_drugReac,2))
        perc_drugNoReac <- data_mat[1,2]/(sum(as.numeric(data_mat[,2])))
        perc_drugNoReac <- as.character(round(100*perc_drugNoReac,2))

        data_mat <- cbind(data_mat,c(perc_reacDrug,perc_reacNoDrug))
        data_mat <- rbind(data_mat,c(perc_drugReac,perc_drugNoReac,""))

        colnames(data_mat) <- c("reac","no reac","% reac")
        rownames(data_mat) <- c("drug","no drug","% drug")
        data_mat
    },
    include.rownames = T)
    
    output$logregResults <- renderTable({
        #-------------------------- Print result table for logistic regression
        data <- newData_allCases()
        data_drug <- data[data$results.drug == input$drug,]
        data_drug <- data_drug[,grepl("logReg",names(data_drug)),drop = F]
        data_drug <- matrix(data_drug[,-c(1:3,5)],ncol = 3, byrow = T)
        colnames(data_drug) <- c("log(OR)","SE","p")
        rownames(data_drug) <- c("drug","age","sex")
        data_drug
    }, include.rownames = T)
    
    output$drugActiveIngredients <- renderDataTable({
        #-------------------------- Print table of all drugnames assigned to the active ingredient
        drugActiveIngredients_table <- assignments_list[[input$drug]]

        drugActiveIngredients_df <- data.frame(Drugname = names(drugActiveIngredients_table),
            Count = as.numeric(drugActiveIngredients_table),
            stringsAsFactors = F)
        drugActiveIngredients_df
    })
    
    output$drugIndications <- renderDataTable({
        #-------------------------- Print table of the 10 top indications of the active ingredient
        indication_list <- newIndication_list()
        
        data <- newData_allCases()
        N_use <- data[data$results.drug == input$drug,"results.N"]
        
        indication_vect <- indication_list[[N_use]]
        indication_df <- data.frame(Indications = names(indication_vect),
            Count = as.numeric(indication_vect),
            stringsAsFactors = F)
        indication_df
    })
    
    output$topIndicationsDrug <- renderDataTable({
        #-------------------------- Print table of the 10 most administered drugnames for the
        #                           top indication
        indication_drug_list <- newIndication_drug_list()
        
        data <- newData_allCases()
        N_use <- data[data$results.drug == input$drug,"results.N"]
        
        drug_vect <- indication_drug_list[[N_use]]
        
        drugActiveIngredients<- names(assignments_list[[input$drug]])
        
        names(drug_vect)[names(drug_vect) %in% drugActiveIngredients] <- paste0(names(drug_vect)[names(drug_vect) %in% drugActiveIngredients],"*")
        
        drug_df <- data.frame(Drugname = names(drug_vect),
            Count = unname(drug_vect),
            stringsAsFactors = F)
        drug_df
    })
    
    output$infoDrug <- renderTable({
        if(input$drug %in% names(info_list)){
            use_name <- input$drug
            df_use <- info_list[[use_name]]
            df_use[,names(df_use) != "go_classifiers"]
        }else if(any(names(assignments_list[[input$drug]]) %in% names(info_list))){
            name_ind <- names(assignments_list[[input$drug]]) %in% names(info_list)
            use_name <- names(assignments_list[[input$drug]])[name_ind]
            df_use <- info_list[[use_name]]
            df_use[,names(df_use) != "go_classifiers"]
        }else{
            data.frame(name = "",
                actions = "",
                target_function = "",
                cellular_location = "",
                target_gene = "",
                target_synonyms = "",
                stringsAsFactors = F)
        }
    })
    
    output$GOannot <- renderDataTable({
        if(input$drug %in% names(info_list)){
            use_name <- input$drug
            df_use <- info_list[[use_name]]
            data.frame(annotation = strsplit(df_use$go_classifiers, "; ",fixed = T)[[1]], stringsAsFactors = F)
        }else if(any(names(assignments_list[[input$drug]]) %in% names(info_list))){
            name_ind <- names(assignments_list[[input$drug]]) %in% names(info_list)
            use_name <- names(assignments_list[[input$drug]])[name_ind]
            df_use <- info_list[[use_name]]
            data.frame(annotation = strsplit(df_use$go_classifiers, "; ",fixed = T)[[1]], stringsAsFactors = F)
        }else{
            data.frame(annotation = "",
                stringsAsFactors = F)
        }
    })
    
})
