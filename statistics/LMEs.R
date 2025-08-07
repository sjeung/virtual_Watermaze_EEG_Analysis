# :::::::::::: libraries ::::::::::::::::::::::::::::::::::::::::::::::::::::: #
# data
library(readxl)      # read from .xlsx
library(tidyverse)   # tidy data
library(dplyr)       # arrange data frames

# statistic
library(afex)        # statistic package for mixed models
library(moments)     # Pearson's kurtosis, Geary's kurtosis and skewness
library(effectsize)  # effect size
library(emmeans)     # post hoc test
library(performance) # computing measures to assess model quality
library(see)         #
library(writexl) 
library(nortest)  # For Lilliefors test

eegparameter  = 'pep' # power or pep 
task          = 'probe' # 'probe', 'stand', 'walk'
window        = 'End' # 'Start', 'Mid', 'End'

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

# create model for 2 x 2 comparison
model.fun <- function(dataTable,variable, Group, Setup, 
                      covariate_sex, covariate_age, covariate_education, covariate_order, participantID){
  model.variable = lmer(variable ~ Group*Setup+covariate_sex+
                          covariate_age+ covariate_education + covariate_order + (1|participantID), data = dataTable)}


# :::::::::::::::: read in, select and sort data :::::::::::::::::::::::::::::::

in_data <- paste0("P:/Sein_Jeung/Project_Watermaze/WM_EEG_Results/resultsTable_", eegparameter, "_", task, "_", window, ".xlsx")

data <- read_xlsx(in_data, col_names=T)

# factorize data 
levels(data$Group) <- c("MTLR", "CTRL")   # or whatever your groups mean
levels(data$Setup) <- c("Stationary", "Mobile")
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
    memory      = mean(MemoryScore,na.rm = TRUE),
    avgidPhi5s  = mean(HeadRotation,na.rm = TRUE),
    lp_aDTWsq = mean(DTW,na.rm = TRUE), 
    across(
      all_of(paste0(rep(channels, each = length(bands)), bands)), 
      mean, na.rm = TRUE, .names = "{.col}"
    ))

# :::::::::::::::: quantitative statistics :::::::::::::::::::::::::::::::::::: #
# Initialize lists to store results
model_results <- list()
anova_pvalues_group <- c()  # Store ANOVA p-values for multiple comparison correction
anova_pvalues_setup <- c()  # Store ANOVA p-values for multiple comparison correction
anova_pvalues_inter <- c()  # Store ANOVA p-values for multiple comparison correction
anova_results_list <- list()  # Store full ANOVA results
omega_squared_list <- list()  # Store Omega Squared results

# Iterate over each channel-band combination
for (channel in channels) {
  for (band in bands) {
    column_name <- paste0(channel, band)  # Create the column name dynamically
    
    #variable <- selectedData_probe[[column_name]]
    variable <- normality.fun( selectedData_probe[[column_name]])
    #normality.fun(variable)
    model.variable <- model.fun(selectedData_probe, variable$TransformedData, selectedData_probe$Group, selectedData_probe$Setup, selectedData_probe$Sex, selectedData_probe$Age, selectedData_probe$Education, selectedData_probe$SessionOrder, selectedData_probe$ID)
    
    # Store model summary
    model_results[[column_name]] <- model.variable
    
    # Perform ANOVApva
    anova_results <- anova(model.variable)
    anova_results_list[[column_name]] <- anova_results  # Store full ANOVA table
    
    # Compute Omega Squared
    omega_values <- as.data.frame(omega_squared(model.variable, partial = TRUE))  # Convert to dataframe
    omega_squared_list[[column_name]] <- omega_values  # Store structured omega values
    
    # Extract p-value for interaction term (assuming Group:Setup is the interaction of interest)
    group_pvalue <- anova_results["Group", "Pr(>F)"]
    setup_pvalue <- anova_results["Setup", "Pr(>F)"]
    interaction_pvalue <- anova_results["Group:Setup", "Pr(>F)"]
    anova_pvalues_group <- c(anova_pvalues_group, group_pvalue)  # Store for correction
    anova_pvalues_setup <- c(anova_pvalues_setup, setup_pvalue)  # Store for correction
    anova_pvalues_inter <- c(anova_pvalues_inter, interaction_pvalue)  # Store for correction
    
    # Check model assumptions
    performance::check_model(model.variable)
  }
}

# **Step 1: Multiple comparison correction**
adjusted_pvalues_group <- p.adjust(anova_pvalues_group, method = "fdr")  # Use FDR correction
adjusted_pvalues_setup <- p.adjust(anova_pvalues_setup, method = "fdr")  # Use FDR correction
adjusted_pvalues_inter <- p.adjust(anova_pvalues_inter, method = "fdr")  # Use FDR correction

# Store adjusted p-values with corresponding column names
names(adjusted_pvalues_group) <- names(anova_results_list)
names(adjusted_pvalues_setup) <- names(anova_results_list)
names(adjusted_pvalues_inter) <- names(anova_results_list)

# **Step 2: Apply post-hoc test only if interaction is significant**
post_hoc_results <- list()

for (i in seq_along(anova_pvalues_inter)) {
  column_name <- names(anova_results_list)[i]
  #if (adjusted_pvalues_inter[column_name] < 0.05) {  # Apply post-hoc test only if significant after correction
  if (anova_pvalues_inter[i] < 0.05) {  # Apply post-hoc test only if significant after correction
    model.variable <- model_results[[column_name]]  # Retrieve model
    post_hoc_results[[column_name]] <- emmeans(model.variable, list(pairwise ~ Group * Setup), adjust = "holm")
    print(post_hoc_results)
  }
}

# Output results
#list(
#  model_results = model_results,
#  anova_results = anova_results_list,
#  adjusted_pvalues = adjusted_pvalues,
#  post_hoc_results = post_hoc_results
#)


# Create an empty list to store results in a structured format
results_list <- list()

# Iterate through ANOVA results
for (column_name in names(anova_results_list)) {
  anova_res <- anova_results_list[[column_name]]
  omega_res <- omega_squared_list[[column_name]]
  
  # Extract statistics for Group, Setup, and Interaction
  group_f <- anova_res["Group", "F value"]
  group_p <- anova_res["Group", "Pr(>F)"]
  setup_f <- anova_res["Setup", "F value"]
  setup_p <- anova_res["Setup", "Pr(>F)"]
  interaction_f <- anova_res["Group:Setup", "F value"]
  interaction_p <- anova_res["Group:Setup", "Pr(>F)"]
  
  # Extract Omega Squared values
  omega_group <- omega_res[1, "Omega2_partial"]
  omega_setup <- omega_res[2, "Omega2_partial"]
  omega_interaction <- omega_res[7, "Omega2_partial"]
  
  # Get adjusted p-value
  adj_p <- adjusted_pvalues_inter[column_name]
  
  # Determine significance after correction
  significant <- ifelse(adj_p < 0.05, "Yes", "No")
  
  # Retrieve post-hoc results if available
  post_hoc <- ifelse(column_name %in% names(post_hoc_results), 
                     capture.output(print(post_hoc_results[[column_name]])), 
                     "-")
  
  results_list[[column_name]] <- data.frame(
    Channel_Band = column_name,
    Group_F = round(group_f, 3), Group_p = round(group_p, 3), Omega2_Group = round(omega_group, 3),
    Setup_F = round(setup_f, 3), Setup_p = round(setup_p, 3), Omega2_Setup = round(omega_setup, 3),
    Interaction_F = round(interaction_f, 3), Interaction_p = round(interaction_p, 3), Omega2_Interaction = round(omega_interaction, 3),
    Group_Adjusted_p       = round(adjusted_pvalues_group[column_name], 3),
    Setup_Adjusted_p       = round(adjusted_pvalues_setup[column_name], 3),
    Interaction_Adjusted_p = round(adjusted_pvalues_inter[column_name], 3),
    Significant_interaction = significant,
    PostHoc = paste(post_hoc, collapse = "; ")  # Store post-hoc results as text 
  )
}

# Combine all results into one data frame
final_results <- do.call(rbind, results_list)

out_data <- paste0("P:/Sein_Jeung/Project_Watermaze/WM_EEG_Results/statistics_", eegparameter, "_", task, "_", window, ".xlsx")

# Save to an Excel file
write_xlsx(final_results, out_data) 

print(paste("Results successfully saved to ", out_data))
