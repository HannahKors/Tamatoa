require(shiny)

# Path to the folder containing app.R
folder_address = 'C:/Users/Z468195/Documents/GitHub/tamatoa/visualization-module'

# Retrieve the local machine's IP addresses
x <- system("ipconfig", intern=TRUE)
z <- x[grep("IPv4", x)]
ips <- gsub(".*? ([[:digit:]])", "\\1", z)

# Print all possible IPs for reference
print(paste0("Available IPs: ", ips))

# Use the first IP address or explicitly set the desired one
host_ip <- ips[1]  # Choose the first IP or manually set: host_ip <- "172.26.128.1"

# Print the chosen URL
print(paste0("The Shiny Web application runs on: http://", host_ip, ":1234/"))

# Run the app from the specified folder
runApp(folder_address, launch.browser=FALSE, port = 1234, host = host_ip)

