# containermaker

Configure, build, run, control docker containers with gnu-make and simple config files.

This evolved from a small hack because i'm a lacy typing person so do not expect to much.

- Howto use

```bash
# clone repository to your filesystem
git clone https://github.com/schmotzle/containermaker

# create a folder for your dockerfile and config files
mkdir hello-world-container
cd hello-world-container

# link the containermaker Makefile to your directory
ln -s ../containermaker/Makefile .

# run make to get a template Dockerfile and config file
make

# edit dockerfile and config file to fit your needs

# build the docker image by running
make build

# run docker container by executing
make run

# get a bash shell inside the container by executing
make interactive
```
