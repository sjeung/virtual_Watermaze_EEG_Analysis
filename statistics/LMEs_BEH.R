# :::::::::::: libraries ::::::::::::::::::::::::::::::::::::::::::::::::::::: #
# data
library(readxl)      # read from .xlsx
library(tidyverse)   # tidy data
library(dplyr)       # arrange data frames
library(ggplot2)

# statistic
library(afex)        # statistic package for mixed models
library(moments)     # Pearson's kurtosis, Geary's kurtosis and skewness
library(effectsize)  # effect size

library(emmeans)     # post hoc test
library(performance) # computing measures to assess model quality
library(see)         #
library(writexl) 
library(nortest)  # For Lilliefors test

task          = 'probe' # only probe trials for beh analysis
eegparameter  = 'pep' # power or pep 
behmeasure    = 'MemoryScore' # 'MemoryScore', 'DTW' 'HeadRotation'
window        = 'Start' #'Start', Mid', 'End'

if (behmeasure == "DTW") {
  y_breaks <- c(0.1, 0.2, 0.3, 0.4)
  y_limits <- c(0.1, 0.4)
}  else if (behmeasure == "HeadRotation") {
  y_breaks <- c(0.005, 0.010, 0.015, 0.020)
  y_limits <- c(0.005, 0.020)
}else {
  y_breaks <- waiver()
  y_limits <- NULL
}

# :::::::::::::::::::::::: Functions :::::::::::::::::::::::::::::::::::::::::::

# descriptive statistics
descriptive.fun <- function(x) {
  c(mean = mean(x), sd=sd(x),sem = sd(x)/sqrt(length(x)), median=median(x), 
    min=min(x), max = max(x), IQR=IQR(x), quantile=quantile(x),
    confInterval = confint(lm(x ~ 1), level = 0.95))}

normality.fun <- function(x) {
  # Perform the Lilliefors (Kolmogorov-Smirnov) test for normality
  nonNorm <- lillie.test(x)$p.value < 0.05  # Returns TRUE if non-normal
  
  # Compute skewness and kurtosis
  skewness_val <- skewness(x, na.rm = TRUE)
  kurtosis_val <- kurtosis(x, na.rm = TRUE)
  
  # Apply log transformation if skewness or kurtosis exceed thresholds
  if (nonNorm) {
    if (skewness_val < -2 || skewness_val > 2 || kurtosis_val < -7 || kurtosis_val > 7) {
      message("Applying log transformation due to skewness/kurtosis values.")
      x <- log(x)
    }
  }
  
  # Return results as a list
  return(list(
    NonNormal = nonNorm,
    Skewness = skewness_val,
    Kurtosis = kurtosis_val,
    TransformedData = x
  ))
}


model.fun <- function(dataTable, variable, EEG, Group, Setup, 
                      covariate_sex, covariate_age, covariate_education, covariate_order, participantID) {
  
  model.variable <- lmer(variable ~ EEG * Group * Setup + covariate_sex +
                           covariate_age + covariate_education + covariate_order +
                           (1 | participantID), data = dataTable)
  
#  print(mean(dataTable$Group[dataTable$Group == 1]))
#  print(mean(dataTable$Group[dataTable$Group == 2]))
#  print(mean(dataTable$Group[dataTable$Group == 1])-  mean(dataTable$Group[dataTable$Group == 2]))
  

}



# :::::::::::::::: read in, select and sort data :::::::::::::::::::::::::::::::

in_data <- paste0("P:/Sein_Jeung/Project_Watermaze/WM_EEG_Results/resultsTable_", eegparameter, "_", task, "_", window, ".xlsx")
data <- read_xlsx(in_data, col_names=T)

# factorize data 
data$Group <- as.factor(data$Group)
data$Setup <- as.factor(data$Setup)
data$ID <- as.factor(data$ID)
data$Sex <- as.factor(data$Sex)
data$SessionOrder <- as.factor(data$SessionOrder)

# :::::: select data per group & setup combination for descriptive statistic :::
# Define channels and frequency bands
channels <- c("FM", "PM", "LT", "RT")
bands <- c("theta", "alpha", "beta", "gamma", "high gamma")

# Function to filter data and compute mean for selected channels
selectDataProbe_group_setup.fun <- function(data, gNo, sNo) {
  selectedData <- data %>% 
    group_by(ID, Group, Setup, Sex, Education, Age, SessionOrder) %>% 
    filter(Group == gNo & Setup == sNo) %>% 
    summarise(across(
      all_of(paste0(rep(channels, each = length(bands)), bands)), 
      mean, na.rm = TRUE, .names = "{.col}"
    ), .groups = "drop") # <- Prevents unnecessary grouping in output
  
  return(selectedData)  # Explicitly return the result
}


# ::::::::: select data for quantitative statistic :::::::::::::::::::::::::::::

# Probe trial
selectedData_probe <- data %>% 
  group_by(ID,Group,Setup,Sex,Age,Education,SessionOrder) %>% 
  summarise(
    MemoryScore      = mean(MemoryScore,na.rm = TRUE),
    HeadRotation     = mean(HeadRotation,na.rm = TRUE),
    DTW              = mean(DTW, na.rm = TRUE), 
    across(
      all_of(paste0(rep(channels, each = length(bands)), bands)), 
      mean, na.rm = TRUE, .names = "{.col}"
    ))

# :::::::::::::::: quantitative statistics :::::::::::::::::::::::::::::::::::: #
# Initialize lists to store results
model_results <- list()
pvalues_EEG <- c()  
pvalues_group <- c()  
pvalues_setup <- c()  
pvalues_inter <- c() 

# Iterate over each channel-band combination
for (channel in channels) {
  for (band in bands) {
    column_name <- paste0(channel, band)  # Create the column name dynamically
    
    variable <- normality.fun(selectedData_probe[[behmeasure]])
    model.variable <- model.fun(selectedData_probe, variable$TransformedData, selectedData_probe[[column_name]], selectedData_probe$Group, selectedData_probe$Setup, selectedData_probe$Sex, selectedData_probe$Age, selectedData_probe$Education, selectedData_probe$SessionOrder, selectedData_probe$ID)
    
    # Store model summary
    model_results[[column_name]] <- model.variable
    
    # Get the summary of the model
    model_summary <- summary(model.variable)
    
    # Extract the p-values
    EEG_pvalue <- model_summary$coefficients["EEG", "Pr(>|t|)"]
    group_pvalue <- model_summary$coefficients["EEG:Group2", "Pr(>|t|)"]
    setup_pvalue <- model_summary$coefficients["EEG:Setup2", "Pr(>|t|)"]
    interaction_pvalue <- model_summary$coefficients["EEG:Group2:Setup2", "Pr(>|t|)"]
    pvalues_EEG[column_name] = EEG_pvalue  # Store for correction
    pvalues_group[column_name] = group_pvalue  # Store for correction
    pvalues_setup[column_name] = setup_pvalue  # Store for correction
    pvalues_inter[column_name] = interaction_pvalue  # Store for correction
    
    # Check model assumptions
    performance::check_model(model.variable)
    
    if (interaction_pvalue <= 0.05 || group_pvalue <= 0.05 || setup_pvalue <= 0.05 || EEG_pvalue <= 0.05) {{
      
      if (interaction_pvalue <= 0.05) {
        effectname <- "interaction"
      } else if (group_pvalue <= 0.05) {
        effectname <- "group"
      } else if (setup_pvalue <= 0.05) {
        effectname <- "setup"
      } else if (EEG_pvalue <= 0.05) {
        effectname <- "eeg"
      } else {
        effectname <- "none"
      }
      
      # Prepare data
      plot_data <- selectedData_probe %>%
        mutate(
          EEG = .data[[column_name]],
          behVar = .data[[behmeasure]],
          Group = factor(Group, levels = c(1, 2), labels = c("MTLR", "CTRL")),
          Setup = factor(Setup, levels = c(1, 2), labels = c("stationary", "mobile")),
          Combo = interaction(Group, Setup, sep = " ")  
        )
      
      # Open new plotting window
      if (.Platform$OS.type == "windows") {
        windows()
      } else {
        X11()
      }
      
      # Plot
        p <-ggplot(plot_data, aes(x = EEG, y = behVar, color = Group, linetype = Setup)) +
          geom_point(aes(shape = Combo), stroke = 2, size = 4, alpha = 0.8) +
          geom_smooth(method = "lm", se = TRUE, aes(color = Group, fill = Group, linetype = Setup, group = Combo), size = 1.2, alpha = 0.1) +
          scale_x_continuous(
            trans = "identity",
            labels = function(x) round(1 / (1 + exp(-x)), 2)*100
          ) +
          scale_fill_manual(values = c("CTRL" = "#D55E00", "MTLR" = "#0072B2"))+
          scale_y_continuous(
            breaks = y_breaks,
            limits = y_limits,
            labels = function(y) if (behmeasure == "MemoryScore") round(1 / (1 + exp(-y)), 2)*100 else y  # Apply inverse logit for y-ticks
          ) +
          scale_color_manual(values = c("CTRL" = "#D55E00", "MTLR" = "#0072B2")) +
          scale_linetype_manual(values = c("stationary" = "solid", "mobile" = "dashed")) +
          scale_shape_manual(
            values = c(
              "MTLR stationary" = 16,  # filled circle
              "MTLR mobile" = 1,       # hollow circle
              "CTRL stationary" = 15,  # filled square
              "CTRL mobile" = 0        # hollow square
            )
          ) +
          labs(
            x = NULL,
            y = NULL,
            color = "Group",
            linetype = "Setup"
          ) +
          theme_minimal() +
          theme(legend.position = "none",
                axis.text = element_text(size = 20),   # Increase axis ticks font size
                panel.grid.major = element_blank(),
                panel.grid.minor = element_blank())
      
        print(p)
        
        # Save the plot with a descriptive filename
        ggsave(
          filename = paste0(effectname, "_", behmeasure, "_vs_", column_name, "_", window,  ".png"),
          plot = p,
          width = 8,
          height = 6,
          dpi = 300
        )
        
        }
  }}
}

# Multiple comparison correction
adjusted_pvalues_EEG <- p.adjust(pvalues_EEG, method = "fdr")  # Use FDR correction
adjusted_pvalues_group <- p.adjust(pvalues_group, method = "fdr")  # Use FDR correction
adjusted_pvalues_setup <- p.adjust(pvalues_setup, method = "fdr")  # Use FDR correction
adjusted_pvalues_inter <- p.adjust(pvalues_inter, method = "fdr")  # Use FDR correction

# Store adjusted p-values with corresponding column names
names(adjusted_pvalues_EEG) <- names(pvalues_EEG)
names(adjusted_pvalues_group) <- names(pvalues_group)
names(adjusted_pvalues_setup) <- names(pvalues_setup)
names(adjusted_pvalues_inter) <- names(pvalues_inter)

# Apply post-hoc test only if interaction is significant
post_hoc_results <- list()
post_hoc_results_group_interaction <- list()
post_hoc_results_setup_interaction <- list()

#for (column_name in names(pvalues_inter)) {
#  if (adjusted_pvalues_inter[column_name] < 0.05) {  # Apply post-hoc test only if significant after correction
for (i in seq_along(pvalues_inter)) {
  column_name <- names(pvalues_inter)[i]
  if (pvalues_inter[i] <= 0.05) {  # Apply post-hoc test 
     model.variable <- model_results[[column_name]]  # Retrieve model
#     post_hoc_results[[column_name]] <- emmeans(model.variable, list(pairwise ~ Group|Setup), adjust = "holm")
     post_hoc_results[[column_name]] <- emtrends(model.variable, pairwise ~ Group | Setup, var = "EEG", adjust = "holm")

  }
}


for (i in seq_along(pvalues_group)) {
  column_name <- names(pvalues_group)[i]
  if (pvalues_group[i] <= 0.05) {  # Apply post-hoc test only if significant after correction
    model.variable <- model_results[[column_name]]  # Retrieve model
     post_hoc_results_group_interaction[[column_name]] <- emtrends(model.variable, 
                                                      pairwise ~Group | EEG, 
                                                      var = "EEG",
                                                      adjust = "holm")
  }
}


for (i in seq_along(pvalues_setup)) {
  column_name <- names(pvalues_setup)[i]
  if (pvalues_setup[i] <= 0.05) {  # Apply post-hoc test only if significant after correction
    model.variable <- model_results[[column_name]]  # Retrieve model
    post_hoc_results_setup_interaction[[column_name]]  <- emtrends(model.variable, 
                                                    pairwise ~ Setup | EEG, 
                                                    var = "EEG", 
                                                    adjust = "holm")
  }
}

# Create an empty list to store results in a structured format
results_list <- list()

# Iterate through ANOVA results
for (column_name in names(pvalues_inter)) {
  results <- model_results[[column_name]]
  results_summary <- summary(results)
  
  # Extract statistics for Group, Setup, and Interaction terms
  EEG_t <- results_summary$coefficients["EEG", "t value"]  
  EEG_p <- results_summary$coefficients["EEG", "Pr(>|t|)"]  
  EEG_beta <- results_summary$coefficients["EEG", "Estimate"] 
  EEG_se <- results_summary$coefficients["EEG", "Std. Error"] 
  
  group_t <- results_summary$coefficients["EEG:Group2", "t value"] 
  group_p <- results_summary$coefficients["EEG:Group2", "Pr(>|t|)"]  
  group_beta <- results_summary$coefficients["EEG:Group2", "Estimate"]  
  group_se <- results_summary$coefficients["EEG:Group2", "Std. Error"]  
  
  setup_t <- results_summary$coefficients["EEG:Setup2", "t value"] 
  setup_p <- results_summary$coefficients["EEG:Setup2", "Pr(>|t|)"] 
  setup_beta <- results_summary$coefficients["EEG:Setup2", "Estimate"]
  setup_se <- results_summary$coefficients["EEG:Setup2", "Std. Error"] 
  
  interaction_t <- results_summary$coefficients["EEG:Group2:Setup2", "t value"]  # t-value for Interaction (EEG:Group2)
  interaction_p <- results_summary$coefficients["EEG:Group2:Setup2", "Pr(>|t|)"]  # p-value for Interaction (EEG:Group2)
  interaction_beta <- results_summary$coefficients["EEG:Group2:Setup2", "Estimate"]  # Estimate (beta) for Interaction (EEG:Group2)
  interaction_se <- results_summary$coefficients["EEG:Group2:Setup2", "Std. Error"]  # SE for Interaction (EEG:Group2)
  
  # Get adjusted p-value
  adj_p <- adjusted_pvalues_inter[column_name]
  
  # Determine significance after correction
  significant <- ifelse(adj_p < 0.05, "Yes", "No")
  
  # Post-hoc results for the specific column (adjust as needed)
  post_hoc <- ifelse(column_name %in% names(post_hoc_results), 
                     capture.output(print(post_hoc_results[[column_name]])), 
                     "-")
  
  # Store results in a structured data frame
  results_list[[column_name]] <- data.frame(
    Channel_Band = column_name,
    EEG_T = round(EEG_t, 3), EEG_p = round(EEG_p, 3), EEG_Beta = round(EEG_beta, 3), EEG_SE = round(group_se, 3),
    Group_T = round(group_t, 3), Group_p = round(group_p, 3), Group_Beta = round(group_beta, 3), Group_SE = round(group_se, 3),
    Setup_T = round(setup_t, 3), Setup_p = round(setup_p, 3), Setup_Beta = round(setup_beta, 3), Setup_SE = round(setup_se, 3),
    Interaction_T = round(interaction_t, 3), Interaction_p = round(interaction_p, 3), Interaction_Beta = round(interaction_beta, 3), Interaction_SE = round(interaction_se, 3),
    Adjusted_p_EEG = round(adjusted_pvalues_EEG[[column_name]], 3),
    Adjusted_p_Group = round(adjusted_pvalues_group[[column_name]], 3),
    Adjusted_p_Setup = round(adjusted_pvalues_setup[[column_name]], 3),
    Adjusted_p_THREEWAY = round(adjusted_pvalues_inter[[column_name]], 3),
    Significant_interaction = significant,  # This should be defined based on your logic
    PostHoc = paste(post_hoc, collapse = "; ")  # Store post-hoc results as text
  )
}


this <- data.frame(
  Channel_Band = column_name,
  EEG_T = round(EEG_t, 3), EEG_p = round(EEG_p, 3), EEG_Beta = round(EEG_beta, 3), EEG_SE = round(group_se, 3),
  Group_T = round(group_t, 3), Group_p = round(group_p, 3), Group_Beta = round(group_beta, 3), Group_SE = round(group_se, 3),
  Setup_T = round(setup_t, 3), Setup_p = round(setup_p, 3), Setup_Beta = round(setup_beta, 3), Setup_SE = round(setup_se, 3),
  Interaction_T = round(interaction_t, 3), Interaction_p = round(interaction_p, 3), Interaction_Beta = round(interaction_beta, 3), Interaction_SE = round(interaction_se, 3),
  Adjusted_p_EEG = round(adjusted_pvalues_EEG[[column_name]], 3),
  Adjusted_p_Group = round(adjusted_pvalues_group[[column_name]], 3),
  Adjusted_p_Setup = round(adjusted_pvalues_setup[[column_name]], 3),
  Adjusted_p_THREEWAY = round(adjusted_pvalues_inter[[column_name]], 3),
  Significant_interaction = significant,  # This should be defined based on your logic
  PostHoc = paste(post_hoc, collapse = "; ")
)

# Combine all results into one data frame
final_results <- do.call(rbind, results_list)

out_data <- paste0("P:/Sein_Jeung/Project_Watermaze/WM_EEG_Results/statistics_beh_", eegparameter, "_", behmeasure, "_", task, "_", window, ".xlsx")

# Save to an Excel file
write_xlsx(final_results, out_data) 
adjusted_pvalues_group
adjusted_pvalues_inter
print(paste("Results successfully saved to ", out_data))
