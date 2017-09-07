# Assuming that data is downloaded and unzipped manually into working directory as a directory "UCI HAR Dataset"

# Investigating the dataset
dataset_path <- './UCI HAR Dataset/'
list.files(dataset_path, recursive = TRUE)
library(data.table)

# Reading subject indices
train_subj <- fread(file.path(dataset_path, 'train', 'subject_train.txt'))
test_subj <- fread(file.path(dataset_path, 'test', 'subject_test.txt'))

# Reading activity indices
train_activities <- fread(file.path(dataset_path, 'train', 'y_train.txt'))
test_activities <- fread(file.path(dataset_path, 'test', 'y_test.txt'))

# Reading actual values
dt_train <- data.table(read.table(file.path(dataset_path, 'train', 'X_train.txt')))
dt_test <- data.table(read.table(file.path(dataset_path, 'test', 'X_test.txt')))

# Merging the test and train tables
dt_subject <- rbind(train_subj, test_subj)
setnames(dt_subject, 'V1', 'subject')
dt_activity <- rbind(train_activities, test_activities)
setnames(dt_activity, 'V1', 'activity_index')
dt <- rbind(dt_train, dt_test)

# Merging columns
dt_subject <- cbind(dt_subject, dt_activity)
dt <- cbind(dt_subject, dt)

# Setting key
setkey(dt, subject, activity_index)

# Extracting mean and std deviation columns
## Reading features.txt file
features <- fread(file.path(dataset_path, 'features.txt'))
setnames(features, names(features), c('feature_index', 'feature_name'))

## Extracting needed column names and indices
features <- features[grepl('mean\\(|std\\(', feature_name)]

## Subsetting dt to include only columns with mean and std deviation
features$feature_code <- features[, paste0('V', feature_index)]
select <- c(key(dt), features$feature_code)
dt <- dt[, select, with = FALSE]

## Adding descriptive names to activity types
activity_names <- fread(file.path(dataset_path,'activity_labels.txt'))
setnames(activity_names, names(activity_names), c('activity_index','activity_name'))
dt <- merge(dt,activity_names, by = 'activity_index', all.x = TRUE)
setkey(dt, subject, activity_index, activity_name)

## Melting data table
dt <- data.table(melt(dt, key(dt), variable.name = "feature_code"))

# Merging activity name
dt <- merge(dt, features[, list(feature_name, feature_index, feature_code)], by = 'feature_code', all.x = TRUE)

# Creating activity and feature rows as factors
dt$activity <- factor(dt$activity_name)
dt$feature <- factor(dt$feature_name)

## removing columns that are no longer needed
names(dt)
new_names <- c("subject", "activity", "feature", "value" )
dt <- dt[, new_names, with = FALSE]

# Creating a tidy dataset
setkey(dt, subject, activity, feature)
tidy_dataset <- dt[, list(count = .N, average = mean(value)), by=key(dt)]

# Saving the tidy dataset as txt
write.table(tidy_dataset, file = "tidy.txt", row.names = FALSE)
