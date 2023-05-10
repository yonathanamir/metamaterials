# Use an official Julia runtime as a parent image
FROM julia:1.6

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages specified in Project.toml and Manifest.toml
RUN julia --project=/app -e 'using Pkg; Pkg.instantiate();'

# Make port 8050 available to the world outside this container
EXPOSE 8050

# Set the environment variable
ENV NAME World

# Run app.jl when the container launches
CMD ["julia", "--project=./", "dashui.jl"]
